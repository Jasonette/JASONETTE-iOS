// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import "MSJSONSerializer.h"
#import "MSClient.h"
#import "MSNaiveISODateFormatter.h"


#pragma mark * Mobile Services Special Keys String Constants


static NSString *const idKey = @"id";
static NSString *const resultsKey = @"results";
static NSString *const countKey = @"count";
static NSString *const errorKey = @"error";
static NSString *const descriptionKey = @"description";
static NSString *const stringIdPattern = @"[+?`\"/\\\\]|[\\u0000-\\u001F]|[\\u007F-\\u009F]|^\\.{1,2}$";

#pragma mark * MSJSONSerializer Implementation

@implementation MSJSONSerializer

static MSJSONSerializer *staticJSONSerializerSingleton;
static NSArray<NSString *> *allIdKeys;

#pragma mark * Public Static Singleton Constructor

+(id <MSSerializer>) JSONSerializer
{
    if (staticJSONSerializerSingleton == nil) {
        staticJSONSerializerSingleton = [[MSJSONSerializer alloc] init];
    }
    
    return  staticJSONSerializerSingleton;
}

+(NSArray<NSString *> *) AllIdKeys
{
    if (allIdKeys == nil) {
        allIdKeys = [NSArray arrayWithObjects:idKey, @"Id", @"ID", @"iD", nil];
    }
    
    return  allIdKeys;
}

# pragma mark * MSSerializer Protocol Implementation
-(NSData *)dataFromItem:(id)item
              idAllowed:(BOOL)idAllowed
       ensureDictionary:(BOOL)ensureDictionary
 removeSystemProperties:(BOOL)removeSystemProperties
                orError:(NSError **)error;
{
    NSData *data = nil;
    NSError *localError = nil;
    
    // First, ensure there is an item...
    if (!item) {
        localError = [self errorForNilItem];
    }
    else if (ensureDictionary && ![item isKindOfClass:[NSDictionary class]]) {
        localError = [self errorForInvalidItem];
    }
    else if (!idAllowed) {
        // Determine if an id (any case) exists and if so throw an error if
        // it is not a string id or it is not a default value
        for (id key in MSJSONSerializer.AllIdKeys) {
            id itemId = [item objectForKey:key];
            
            if (itemId == nil || itemId == [NSNull null]) {
                continue;
            }
            else if ([itemId isKindOfClass:[NSString class]]) {
                // Allow empty string for any id
                if ([itemId length] != 0 ) {
                    if([key isEqualToString:idKey]) {
                        // Valid string ids are allowed for 'id' only
                        [self stringFromItemId:itemId orError:&localError];
                    }
                    else {
                        localError = [self errorForInvalidItemId];
                    }
                }
            }
            else if ([itemId isKindOfClass:[NSNumber class]]) {
                // Only a default value, 0, can be used for int ids
                if ([itemId longLongValue] != 0) {
                    localError = [self errorForExistingItemId];
                }
            }
            else {
                localError = [self errorForInvalidItemId];
            }
        }
    }
    
    if (!localError)
    {
        // Convert any NSDate instances into strings formatted with the date.
        item = [self preSerializeItem:item RemoveSystemProperties:removeSystemProperties];

        // ... then make sure the |NSJSONSerializer| can serialize it, otherwise
        // the |NSJSONSerializer| will throw an exception, which we don't
        // want--we'd rather return an error.
        if (![NSJSONSerialization isValidJSONObject:item]) {
            localError = [self errorForInvalidItem];
            
        } else {
            // If there is still an error serializing, |dataWithJSONObject|
            // will ensure that data the error is set and data is nil.
            data = [NSJSONSerialization dataWithJSONObject:item
                                               options:0
                                                 error:error];
        }
    }
    
    if (localError && error) {
        *error = localError;
    }
    
    return data;
}

-(id) itemIdFromItem:(NSDictionary *)item orError:(NSError **)error
{
    id itemId = nil;
    NSError *localError = nil;
    
    // Ensure there is an item
    if (!item) {
        localError = [self errorForNilItem];
    }
    else if (![item isKindOfClass:[NSDictionary class]]) {
        localError = [self errorForInvalidItem];
    }
    else {
        // Then get the value of the id key, which must be present or else
        // it is an error.
        itemId = [item objectForKey:idKey];
        if (!itemId) {
            localError = [self errorForMissingItemId];
        }
        else if (![itemId isKindOfClass:[NSNumber class]] &&
                 ![itemId isKindOfClass:[NSString class]]) {
            localError = [self errorForInvalidItemId];
            itemId = nil;
        }
    }
    
    if (localError && error) {
        *error = localError;
    }

    return itemId;
}

-(NSString *) stringFromItemId:(id)itemId orError:(NSError **)error
{
    NSString *idAsString = nil;
    NSError *localError = nil;
    
    // Ensure there is an item id
    if (!itemId) {
        localError = [self errorForExpectedItemId];
    }
    else if([itemId isKindOfClass:[NSNumber class]]) {
        long long itemIdValue = [itemId longLongValue];
        if(itemIdValue == 0) {
            // id can't be a default value
            localError = [self errorForInvalidItemId];
        }
        else {
            idAsString = [NSString stringWithFormat:@"%lld",itemIdValue];
        }
    }
    else if ([itemId isKindOfClass:[NSString class]]) {
        idAsString = itemId;
        NSString *trimmedId = [idAsString stringByTrimmingCharactersInSet:
                                [NSCharacterSet whitespaceCharacterSet]];
        
        if(idAsString.length == 0 || idAsString.length > 255 || trimmedId.length == 0) {
            localError = [self errorForInvalidItemId];
        } else {
            NSRegularExpression *regEx = [NSRegularExpression regularExpressionWithPattern:stringIdPattern
                                                                                   options:NSRegularExpressionCaseInsensitive
                                                                                     error:&localError];
            if ([regEx firstMatchInString:idAsString options:0 range:NSMakeRange(0, idAsString.length)]) {
                localError = [self errorForInvalidItemId];
            }
        }        
    }
    else {
        // The id was there, but it wasn't a number or string
        localError = [self errorForInvalidItemId];
    }
    
    if (localError && error) {
        *error = localError;
        idAsString = nil;
    }

    return idAsString;
}

-(NSString *) stringIdFromItem:(NSDictionary *)item orError:(NSError **)error
{
    // Get the id field out of the item
    id itemId = [self itemIdFromItem:item orError:error];
    if (error && *error) {
        return nil;
    }
    
    // Verify the Id is a string
    if (itemId && ![itemId isKindOfClass:[NSString class]]) {
        if (error) {
            *error = [self errorForInvalidItemId];
        }
        return nil;
    }
    
    return [self stringFromItemId:itemId orError:error];
}

-(id) itemFromData:(NSData *)data
            withOriginalItem:(id)originalItem
            ensureDictionary:(BOOL)ensureDictionary
            orError:(NSError **)error
{
    id item = nil;
    NSError *localError = nil;
    
    // Ensure there is data
    if (!data) {
        localError = [self errorForNilData];
    }
    else {
        
        // Try to deserialize the data; if it fails the error will be set
        // and item will be nil.
        item = [NSJSONSerialization JSONObjectWithData:data
                                               options:NSJSONReadingAllowFragments
                                                 error:error];

        if (item) {
            
            // The data should have been only a single item--that is, a
            // dictionary and not an array or string, etc.
            if (ensureDictionary &&
                ![item isKindOfClass:[NSDictionary class]]) {
                item = nil;
                localError = [self errorForExpectedItem];
            }
            else {
                
                // Convert any date-like strings into NSDate instances
                item = [self postDeserializeItem:item];
                
                if (originalItem) {
                    
                    // If the originalitem was provided, update it with the values
                    // from the new item.
                    for (NSString *key in [item allKeys]) {
                        id value = [item objectForKey:key];
                        [originalItem setValue:value forKey:key];
                    }
                    
                    // And return the original value instead
                    item = originalItem;
                }
            }
        }
    }
    
    if (localError && error) {
        *error = localError;
    }
    
    return item;
}

-(NSArray *) arrayFromData:(NSData *)data
           orError:(NSError **)error
{
    id jsonObject = nil;
    NSError *localError = nil;
    
    // Ensure there is data
    if (!data) {
        localError = [self errorForNilData];
    }
    else {
        
        // Try to deserialize the data; if it fails the error will be set
        // and item will be nil.
        jsonObject = [NSJSONSerialization JSONObjectWithData:data
                                               options:NSJSONReadingAllowFragments
                                                 error:error];
        
        if (jsonObject) {
            // The data should have been of array type
            if (![jsonObject isKindOfClass:[NSArray class]]) {
                jsonObject = nil;
                localError = [self errorForExpectedArray];
            }
        }
    }
    
    if (localError && error) {
        *error = localError;
    }
    
    return jsonObject;
}

-(NSInteger) totalCountAndItems:(NSArray **)items
                       fromData:(NSData *)data
                        orError:(NSError **)error
{
    NSInteger totalCount = -1;
    NSError *localError = nil;
    NSArray *localItems = nil;
    
    // Ensure there is data
    if (!data) {
        localError = [self errorForNilData];
    }
    else
    {
        id JSONObject = [NSJSONSerialization JSONObjectWithData:data
                        options:NSJSONReadingMutableContainers |
                                NSJSONReadingAllowFragments
                        error:error];
    
        if (JSONObject) {

            // The JSONObject could be either an array or a dictionary
            if ([JSONObject isKindOfClass:[NSArray class]]) {
                
                // The JSONObject was just an array, so it is the items.
                // Convert any date-like strings into NSDate instances
                localItems = JSONObject;
            }
            else if ([JSONObject isKindOfClass:[NSDictionary class]]) {
            
                // Since it was a dictionary, it has to have both the
                // count, which is a number...
                id count = [JSONObject objectForKey:countKey];
                if (![count isKindOfClass:[NSNumber class]]) {
                    localError = [self errorForMissingTotalCount];
                }
                else {
                    totalCount = [count integerValue];
                
                    // ...and it has to have the array of items.
                    id results = [JSONObject objectForKey:resultsKey];
                    if (![results isKindOfClass:[NSArray class]]) {
                        localError = [self errorForMissingItems];
                        totalCount = -1;
                    }
                    else {
                        localItems = results;
                    }
                }
            }
            else {
                // The JSONObject was neither a dictionary nor an array, so that
                // is also an error.
                localError = [self errorForMissingItems];
            }
        }
    }
    
    if (localItems) {
        *items = [self postDeserializeItem:localItems];
    }
    
    if (localError && error) {
        *error = localError;
    }
    
    return totalCount;
}

-(NSError *) errorFromData:(NSData *)data MIMEType:(NSString *)MIMEType
{
    NSError *error = nil;

    // If there is data, deserialize it
    if (data) {
        
        // We'll see if we can find an error message in the data
        NSString *errorMessage = nil;
        
        BOOL isJson = MIMEType &&
                      NSNotFound != [MIMEType rangeOfString:@"JSON"
                                                    options:NSCaseInsensitiveSearch].location;
        if (isJson) {
            id JSONObject = [NSJSONSerialization JSONObjectWithData:data
                                    options: NSJSONReadingMutableContainers |
                                             NSJSONReadingAllowFragments
                                      error:&error];
            
            if (JSONObject) {
            
                if ([JSONObject isKindOfClass:[NSString class]]) {
                
                    // Since the JSONObject was just a string, we'll assume it
                    // is the error message.
                    errorMessage = JSONObject;
                }
                else if ([JSONObject isKindOfClass:[NSDictionary class]]) {
                    
                    // Since we have a dictionary, we'll look for the 'error' or
                    // 'description' keys.
                    errorMessage = [JSONObject objectForKey:errorKey];
                    if (![errorMessage isKindOfClass:[NSString class]]) {
                        
                        // The 'error' key didn't work, so we'll try 'description'
                        errorMessage = [JSONObject objectForKey:descriptionKey];
                        if (![errorMessage isKindOfClass:[NSString class]]) {
                            
                            // 'description' didn't work either
                            errorMessage = nil;
                        }
                    }
                }

            }
        }
    
        if (!error) {
            if (!errorMessage) {
                // Since the data wasn't Json in the form we assumed, assume it is UTF8 text
                errorMessage = [[NSString alloc] initWithData:data
                                                 encoding:NSUTF8StringEncoding];
            }
        
            // If we found an error message, make an error from it
            if (errorMessage) {
                error = [self errorWithMessage:errorMessage];
            }
        }
    }
    
    if (!error) {
        // If we couldn't find an error message, return a generic error
        error = [self errorWithoutMessage];
    }
    
    return error;
}

- (void) removeSystemProperties:(NSMutableDictionary *) item
{
    NSArray<NSString *> *systemProperties = @[
         @"version",
         @"updatedAt",
         @"createdAt",
         @"deleted"
    ];
    
    [item removeObjectsForKeys:systemProperties];
    
    return;
}

#pragma mark * Private Pre/Post Serialization Methods

-(id) preSerializeItem:(id)item RemoveSystemProperties:(BOOL)removeSystemProperties
{
    id preSerializedItem = nil;
    
    if ([item isKindOfClass:[NSDictionary class]]) {
        preSerializedItem = [item mutableCopy];
        
        if(removeSystemProperties) {
            [self removeSystemProperties:preSerializedItem];
        }
        
        for (NSString *key in [preSerializedItem allKeys]) {
            id value = [preSerializedItem valueForKey:key];
            id preSerializedValue = [self preSerializeItem:value RemoveSystemProperties:NO];
            [preSerializedItem setObject:preSerializedValue forKey:key];
        }
    }
    else if([item isKindOfClass:[NSArray class]]) {
        preSerializedItem = [item mutableCopy];
        for (NSInteger i = 0; i < [preSerializedItem count]; i++) {
            id value = [preSerializedItem objectAtIndex	:i];
            id preSerializedValue = [self preSerializeItem:value RemoveSystemProperties:NO];
            [preSerializedItem setObject:preSerializedValue atIndex:i];
        }
    }
    else if ([item isKindOfClass:[NSDate class]]) {
        NSDateFormatter *formatter =
        [MSNaiveISODateFormatter naiveISODateFormatter];
        preSerializedItem = [formatter stringFromDate:item];
    }
    else {
        preSerializedItem = item;
    }
    
    return preSerializedItem;
}

-(id) postDeserializeItem:(id)item
{
    id postDeserializedItem = nil;
    
    if ([item isKindOfClass:[NSDictionary class]]) {
        postDeserializedItem = [item mutableCopy];
        for (NSString *key in [postDeserializedItem allKeys]) {
            id value = [postDeserializedItem valueForKey:key];
            id preSerializedValue = [self postDeserializeItem:value];
            [postDeserializedItem setObject:preSerializedValue forKey:key];
        }
    }
    else if([item isKindOfClass:[NSArray class]]) {
        postDeserializedItem = [item mutableCopy];
        for (NSInteger i = 0; i < [postDeserializedItem count]; i++) {
            id value = [postDeserializedItem objectAtIndex:i];
            id preSerializedValue = [self postDeserializeItem:value];
            [postDeserializedItem setObject:preSerializedValue atIndex:i];
        }
    }
    else if ([item isKindOfClass:[NSString class]]) {
        NSDateFormatter *formatter;
        if ([item rangeOfString:@"."].location == NSNotFound) {
            formatter = [MSNaiveISODateFormatter naiveISODateNoFractionalSecondsFormatter];
        } else {
            formatter = [MSNaiveISODateFormatter naiveISODateFormatter];
        }
        
        NSDate *date = [formatter dateFromString:item];
        postDeserializedItem = (date) ? date : item;
    }
    else {
        postDeserializedItem = item;
    }
    
    return postDeserializedItem;
}


#pragma mark * Private NSError Generation Methods


-(NSError *) errorForNilItem
{
    return [self errorWithDescriptionKey:@"No item was provided."
                            andErrorCode:MSExpectedItemWithRequest];
}

-(NSError *) errorForInvalidItem
{
    return [self errorWithDescriptionKey:@"The item provided was not valid."
                            andErrorCode:MSInvalidItemWithRequest];
}

-(NSError *) errorForMissingItemId
{
    return [self errorWithDescriptionKey:@"The item provided did not have an id."
                            andErrorCode:MSMissingItemIdWithRequest];
}

-(NSError *) errorForExistingItemId
{
    return [self errorWithDescriptionKey:@"The item provided must not have an id."
                            andErrorCode:MSExistingItemIdWithRequest];
}

-(NSError *) errorForExpectedItemId
{
    return [self errorWithDescriptionKey:@"The item id was not provided."
                            andErrorCode:MSExpectedItemIdWithRequest];
}
-(NSError *) errorForInvalidItemId
{
    return [self errorWithDescriptionKey:@"The item provided did not have a valid id."
                            andErrorCode:MSInvalidItemIdWithRequest];
}

-(NSError *) errorForNilData
{
    return [self errorWithDescriptionKey:@"The server did return any data."
                            andErrorCode:MSExpectedBodyWithResponse];
}

-(NSError *) errorForExpectedItem
{
    return [self errorWithDescriptionKey:@"The server did not return the expected item."
                            andErrorCode:MSExpectedItemWithResponse];
}

-(NSError *) errorForExpectedArray
{
    return [self errorWithDescriptionKey:@"The server did not return object of expected array type."
                            andErrorCode:MSExpectedItemWithResponse];
}

-(NSError *) errorForMissingTotalCount
{
    return [self errorWithDescriptionKey:@"The server did not return the expected total count."
                            andErrorCode:MSExpectedTotalCountWithResponse];
}

-(NSError *) errorForMissingItems
{
    return [self errorWithDescriptionKey:@"The server did not return the expected items."
                            andErrorCode:MSExpectedItemsWithResponse];
}

-(NSError *) errorWithoutMessage
{
    return [self errorWithDescriptionKey:@"The server returned an error."
                            andErrorCode:MSErrorNoMessageErrorCode];
}

-(NSError *) errorWithMessage:(NSString *)errorMessage
{
    return [self errorWithDescription:errorMessage
                            andErrorCode:MSErrorMessageErrorCode];
}

-(NSError *) errorWithDescriptionKey:(NSString *)descriptionKey
                        andErrorCode:(NSInteger)errorCode
{
    NSString *description = NSLocalizedString(descriptionKey, nil);
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey :description };
    
    return [NSError errorWithDomain:MSErrorDomain
                               code:errorCode
                           userInfo:userInfo];
}

-(NSError *) errorWithDescription:(NSString *)description
                     andErrorCode:(NSInteger)errorCode
{
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey :description };
    
    return [NSError errorWithDomain:MSErrorDomain
                               code:errorCode
                           userInfo:userInfo];
}

// Generates a random GUID to uniquely identify operations or objects missing an Id
+ (NSString *) generateGUID {
    CFUUIDRef newUUID = CFUUIDCreate(kCFAllocatorDefault);
    NSString *newId = (__bridge_transfer NSString *)CFUUIDCreateString(kCFAllocatorDefault, newUUID);
    CFRelease(newUUID);
    
    return newId;
}

@end
