// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import "MSTableOperation.h"
#import "MSTableOperationInternal.h"
#import "MSClient.h"
#import "MSTable.h"
#import "MSTableInternal.h"
#import "MSJSONSerializer.h"

@implementation MSTableOperation

@synthesize operationId = operationId_;
@synthesize type = type_;
@synthesize tableName = tableName_;
@synthesize itemId = itemId_;
@synthesize item = item_;

+(MSTableOperation *) pushOperationForTable:(NSString *)tableName
                                      type:(MSTableOperationTypes)type
                                      itemId:(NSString *)itemId;
{
    return [[MSTableOperation alloc] initWithTable:tableName type:type itemId:itemId];
}

-(id) initWithTable:(NSString *)tableName
               type:(MSTableOperationTypes)type
               itemId:(NSString *)itemId;
{
    self = [super init];
    if (self)
    {
        type_ = type;
        tableName_ = [tableName copy];
        itemId_ = [itemId copy];
    }
    
    return self;
}

-(id) initWithItem:(NSDictionary *)item
{
    self = [super init];
    if (self) {
        NSData *data = [item objectForKey:@"properties"];
        MSJSONSerializer *serializer = [MSJSONSerializer new];
        
        NSDictionary *rawItem = [serializer itemFromData:data withOriginalItem:nil ensureDictionary:YES orError:nil];
        
        type_ = [[rawItem objectForKey:@"type"] integerValue];
        itemId_ = [item objectForKey:@"itemId"];
        tableName_ = [item objectForKey:@"table"];
        operationId_ = [[item objectForKey:@"id"] integerValue];
        
        item_ = [rawItem objectForKey:@"item"];
    }
    return self;
}

-(NSDictionary *) serialize
{
    NSDictionary *properties;
    if (self.type == MSTableOperationDelete && self.item) {
        properties = @{ @"type": [NSNumber numberWithInteger:self.type],
                        @"item": self.item };
    } else {
        properties = @{ @"type": [NSNumber numberWithInteger:self.type] };
    }
    
    MSJSONSerializer *serializer = [MSJSONSerializer new];
    NSData *data = [serializer dataFromItem:properties idAllowed:YES ensureDictionary:NO removeSystemProperties:NO orError:nil];
    
    return @{ @"id": [NSNumber numberWithInteger:self.operationId], @"table": self.tableName, @"tableKind": @0, @"itemId": self.itemId, @"properties": data };
}

- (void) executeWithCompletion:(void(^)(NSDictionary *, NSError *))completion
{
    MSTable *table = [self.client tableWithName:self.tableName];
    table.features = MSFeatureOffline;
    
    if (self.type == MSTableOperationInsert) {
        [table insert:self.item completion:completion];
    } else if (self.type == MSTableOperationUpdate) {
        [table update:self.item completion:completion];
    } else if (self.type == MSTableOperationDelete) {
        [table delete:self.item completion:completion];
    }
}

- (void) cancelPush
{
    [self.pushOperation cancel];
}

/// Logic for determining how operations should be condensed into one single pending operation
/// For example: Insert + Update -> Insert
///              Update + Insert -> Error (don't allow user to do this)
+ (MSCondenseAction) condenseAction:(MSTableOperationTypes)newAction withExistingOperation:(MSTableOperation *)operation
{
    MSTableOperationTypes existingAction = operation.type;
    MSCondenseAction actionToTake = MSCondenseNotSupported;
    
    if (existingAction == MSTableOperationInsert) {
        switch (newAction) {
            case MSTableOperationUpdate:
                actionToTake = MSCondenseKeep;
                break;
            case MSTableOperationDelete:
                actionToTake = MSCondenseRemove;
                break;
            default:
                actionToTake = MSCondenseNotSupported;
                break;
        }
    }
    else if (existingAction == MSTableOperationUpdate) {
        switch (newAction) {
            case MSTableOperationDelete:
                actionToTake = MSCondenseToDelete;
                break;
            case MSTableOperationUpdate:
                actionToTake = MSCondenseKeep;
                break;
            default:
                actionToTake = MSCondenseNotSupported;
                break;
        }
    }
    
    // All actions after a MSPushOperationDelete are invalid
    
    if (operation.inProgress && actionToTake != MSCondenseNotSupported) {
        actionToTake = MSCondenseAddNew;
    }
    
    return actionToTake;
}

@end
