/* Copyright 2017 Urban Airship and Contributors */

#import "NSJSONSerialization+UAAdditions.h"
#import "UAJSONValueTransformer+Internal.h"


@implementation UAJSONValueTransformer

+ (Class)transformedValueClass {
    return [NSData class];
}

+ (BOOL)allowsReverseTransformation {
    return YES;
}

- (id)transformedValue:(NSDictionary *)value {
    return [NSJSONSerialization dataWithJSONObject:value
                                           options:NSJSONWritingPrettyPrinted
                                             error:nil];
}

- (id)reverseTransformedValue:(id)value {
    return [NSJSONSerialization JSONObjectWithData: value
                                           options: NSJSONReadingMutableContainers
                                             error: nil];
}

@end
