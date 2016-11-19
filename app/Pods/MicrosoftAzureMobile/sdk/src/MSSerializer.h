// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import <Foundation/Foundation.h>


#pragma mark * MSSerializer Protocol


// The |MSSerializer| protocol defines serializers that can serialize
// items into instances of NSData and vice-versa. It does require that
// item instances have an associated id that is an unsigned 64-bit integer.
@protocol MSSerializer <NSObject>

@required


#pragma mark * Serialization Methods


// Called for updates and inserts so that the item can be serialized into
// an |NSData| instance.  Inserts are not allows to have items that already have
// an id.
-(NSData *)dataFromItem:(id)item
              idAllowed:(BOOL)idAllowed
       ensureDictionary:(BOOL)ensureDictionary
 removeSystemProperties:(BOOL)removeSystemProperties
                orError:(NSError **)error;

// Called to obtain the id of an item.
-(id)itemIdFromItem:(id)item orError:(NSError **)error;

// Called to obtain a string representation of an id of an item.
-(NSString *)stringFromItemId:(id)itemId orError:(NSError **)error;

// Called to get a string id only from a given item
-(NSString *) stringIdFromItem:(NSDictionary *)item orError:(NSError **)error;

#pragma mark * Deserialization Methods


// Called for updates and inserts when the data will be a single item. If
// the original item is--that is the item that was serialized and
// sent in the update or insert--is non-nil, it should be updated with
// the values from the item deserialized from the data.
-(id)itemFromData:(NSData *)data
        withOriginalItem:(id)originalItem
        ensureDictionary:(BOOL)ensureDictionary
                 orError:(NSError **)error;

// Called to deserialize a response to an NSArray
-(NSArray *) arrayFromData:(NSData *)data
                   orError:(NSError **)error;

// Called for reads when the data will either by an array of items or
// an array of items and a total count. After returning, either the items
// parameter or the error parameter (but not both) will be set. The
// return value will be the total count, if it was requested or -1 otherwise.
-(NSInteger)totalCountAndItems:(NSArray **)items
                      fromData:(NSData *)data
                       orError:(NSError **)error;

// Called when the data is expected to have an error message instead of
// an item; for example, if the HTTP response status code was >= 400. May
// return nil if no error message could be obtained from the data.
-(NSError *)errorFromData:(NSData *)data MIMEType:(NSString *)MIMEType;

- (void) removeSystemProperties:(NSMutableDictionary *) item;

@end
