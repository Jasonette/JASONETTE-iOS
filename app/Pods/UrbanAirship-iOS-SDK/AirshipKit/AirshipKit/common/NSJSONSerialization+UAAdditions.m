/* Copyright 2017 Urban Airship and Contributors */

#import "NSJSONSerialization+UAAdditions.h"
#import "UAGlobal.h"

@implementation NSJSONSerialization (UAAdditions)

NSString * const UAJSONSerializationErrorDomain = @"com.urbanairship.json_serialization";

+ (NSString *)stringWithObject:(id)jsonObject {
    return [NSJSONSerialization stringWithObject:jsonObject options:0 acceptingFragments:NO error:nil];
}

+ (NSString *)stringWithObject:(id)jsonObject error:(NSError **)error {
    return [NSJSONSerialization stringWithObject:jsonObject options:0 acceptingFragments:NO error:error];
}

+ (NSString *)stringWithObject:(id)jsonObject options:(NSJSONWritingOptions)opt {
    return [NSJSONSerialization stringWithObject:jsonObject options:opt acceptingFragments:NO error:nil];
}

+ (NSString *)stringWithObject:(id)jsonObject options:(NSJSONWritingOptions)opt error:(NSError **)error {
    return [NSJSONSerialization stringWithObject:jsonObject options:opt acceptingFragments:NO error:error];
}

+ (NSString *)stringWithObject:(id)jsonObject acceptingFragments:(BOOL)acceptingFragments {
    return [NSJSONSerialization stringWithObject:jsonObject options:0 acceptingFragments:acceptingFragments error:nil];
}

+ (NSString *)stringWithObject:(id)jsonObject acceptingFragments:(BOOL)acceptingFragments error:(NSError **)error {
    return [NSJSONSerialization stringWithObject:jsonObject options:0 acceptingFragments:acceptingFragments error:error];
}

+ (NSString *)stringWithObject:(id)jsonObject
                       options:(NSJSONWritingOptions)opt
            acceptingFragments:(BOOL)acceptingFragments
                         error:(NSError **)error {
    if (!jsonObject) {
        return nil;
        
    }

    if (!acceptingFragments ||
        ([jsonObject isKindOfClass:[NSArray class]] || [jsonObject isKindOfClass:[NSDictionary class]])) {
        if (![NSJSONSerialization isValidJSONObject:jsonObject]) {
            UA_LWARN(@"Attempting to JSON-serialize a non-foundation object. Returning nil.");
            if (error) {
                NSString *msg = [NSString stringWithFormat:@"Attempted to serialize invalid object: %@", jsonObject];
                NSDictionary *info = @{NSLocalizedDescriptionKey:msg};
                *error =  [NSError errorWithDomain:UAJSONSerializationErrorDomain
                                              code:UAJSONSerializationErrorCodeInvalidObject
                                          userInfo:info];
            }
            return nil;
        }
        NSData *data = [NSJSONSerialization dataWithJSONObject:jsonObject
                                                       options:opt
                                                         error:error];

        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    } else {
        //this is a dirty hack but it works well. while NSJSONSerialization doesn't allow writing of
        //fragments, if we serialize the value in an array without pretty printing, and remove the
        //surrounding bracket characters, we get the equivalent result.
        NSString *arrayString = [self stringWithObject:@[jsonObject] options:0 acceptingFragments:NO error:error];
        return [arrayString substringWithRange:NSMakeRange(1, arrayString.length-2)];
    }
}

+ (id)objectWithString:(NSString *)jsonString {
    return [self objectWithString:jsonString options:NSJSONReadingMutableContainers];
}

+ (id)objectWithString:(NSString *)jsonString options:(NSJSONReadingOptions)opt {
    return [self objectWithString:jsonString options:opt error:nil];
}

+ (id)objectWithString:(NSString *)jsonString options:(NSJSONReadingOptions)opt error:(NSError **)error {
    if (!jsonString) {
        return nil;
    }
    return [NSJSONSerialization JSONObjectWithData: [jsonString dataUsingEncoding:NSUTF8StringEncoding]
                                           options: opt
                                             error: error];
}


@end
