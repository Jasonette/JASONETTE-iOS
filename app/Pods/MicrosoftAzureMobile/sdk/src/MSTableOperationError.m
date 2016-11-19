// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import "MSTableOperationError.h"
#import "MSJSONSerializer.h"
#import "MSError.h"
#import "MSTableOperationInternal.h"
#import "MSSyncContextInternal.h"

@interface MSTableOperationError()

@property (nonatomic) NSString *guid;

// Error
@property (nonatomic) NSInteger code;
@property (nonatomic) NSString *domain;

@property (nonatomic) NSString *description;

@property (nonatomic, copy) NSString *table;
@property (nonatomic) MSTableOperationTypes operation;
@property (nonatomic) NSInteger operationId;
@property (nonatomic, copy) NSString *itemId;
@property (nonatomic, copy) NSDictionary *item;

// Optional HTTP Response data
@property (nonatomic) NSInteger statusCode;
@property (nonatomic) NSString *rawResponse;
@property (nonatomic) NSDictionary *serverItem;

@property (nonatomic, strong) MSSyncContext *syncContext;

@end


@implementation MSTableOperationError

@synthesize description = _description;

#pragma mark - Initialization


- (id) init {
    self = [super init];
    if (self) {
        _guid = [MSJSONSerializer generateGUID];
    }
    return self;
}

- (id) initWithOperation:(MSTableOperation *)operation item:(NSDictionary *)item context:(MSSyncContext *)context error:(NSError *) error
{
    self = [self init];
    
    _code = error.code;
    _domain = [error.domain copy];
    _description = [error.localizedDescription copy];
    
    NSHTTPURLResponse *response = [error.userInfo objectForKey:MSErrorResponseKey];
    if (response) {
        _statusCode = response.statusCode;
    }
    
    _serverItem = [[[error userInfo] objectForKey:MSErrorServerItemKey] copy];
    
    _table = [operation.tableName copy];
    _operation = operation.type;
    _itemId = [operation.itemId copy];
    _item = [item copy];
    _operationId = operation.operationId;
    _syncContext = context;
    
    return self;
}

- (id) initWithOperation:(MSTableOperation *)operation item:(NSDictionary *)item error:(NSError *) error __deprecated;
{
    return [[MSTableOperationError alloc] initWithOperation:operation item:item context:nil error:error];
}

- (id) initWithSerializedItem:(NSDictionary *)item context:(MSSyncContext *)context {
    self = [self init];
    if (self) {
        _guid = [item objectForKey:@"id"];
        
        // Unserialize the raw data now
        NSData *properties = [item objectForKey:@"properties"];
        MSJSONSerializer *serializer = [MSJSONSerializer new];
        NSDictionary *data = [serializer itemFromData:properties withOriginalItem:nil ensureDictionary:NO orError:nil];
        
        _code = [[data objectForKey:@"code"] integerValue];
        _domain = [data objectForKey:@"domain"];
        _description = [data objectForKey:@"description"];
        _table = [data objectForKey:@"table"];
        _operation = [[data objectForKey:@"operation"] integerValue];
        _itemId = [data objectForKey:@"itemId"];
        _item = [data objectForKey:@"item"];
        _serverItem = [data objectForKey:@"serverItem"];
        _statusCode = [[data objectForKey:@"statusCode"] integerValue];
        
        _syncContext = context;
    }
    
    return self;
}

- (id) initWithSerializedItem:(NSDictionary *)item 
{
    return [[MSTableOperationError alloc] initWithSerializedItem:item context:nil];
}

- (NSDictionary *) serialize
{
    NSMutableDictionary *properties = [@{
            @"code": [NSNumber numberWithInteger:self.code],
            @"domain": self.domain,
            @"description": self.description,
            @"table": self.table,
            @"operation": [NSNumber numberWithInteger:self.operation],
            @"itemId": self.itemId,
            @"statusCode": [NSNumber numberWithInteger:self.statusCode]
        } mutableCopy];
    
    if (self.item) {
        [properties setValue:self.item forKey:@"item"];
    }
    if (self.serverItem) {
        [properties setValue:self.serverItem forKey:@"serverItem"];
    }
    
    MSJSONSerializer *serializer = [MSJSONSerializer new];
    NSError *serializeError;
    NSData *data = [serializer dataFromItem:properties
                                  idAllowed:YES
                           ensureDictionary:NO
                     removeSystemProperties:NO
                                    orError:&serializeError];
    
    // Handle if something is wrong with one of our fields, try again without the possibly
    // breaking fields (item or serverItem could not be serializable)
    if (serializeError.code == MSInvalidItemWithRequest) {
        [properties removeObjectForKey:@"item"];
        [properties removeObjectForKey:@"serverItem"];
        
        data = [serializer dataFromItem:properties
                              idAllowed:YES
                       ensureDictionary:NO
                 removeSystemProperties:NO
                                orError:&serializeError];
    }
        
    return @{ @"id": self.guid,
              @"operationId": [NSNumber numberWithInteger:self.operationId],
              @"tableKind": @0, @"properties": data
            };
}

#pragma mark - Error Resolution

- (void) cancelOperationAndUpdateItem:(NSDictionary *)item completion:(MSSyncBlock)completion
{
    if (!item) {
        if (completion) {
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Item is required" };
            NSError *error = [NSError errorWithDomain:MSErrorDomain
                                                 code:MSSyncTableCancelError
                                             userInfo:userInfo];
            completion(error);
            return;
        }
    }
    
    MSTableOperation *op = [[MSTableOperation alloc] initWithTable:self.table
                                                              type:self.operation
                                                            itemId:self.itemId];
    op.operationId = self.operationId;
    op.item = item;
    
    [self.syncContext cancelOperation:op updateItem:item completion:^(NSError * _Nullable error) {
        self.handled = !error;
        
        if (completion) {
            completion(error);
        }
    }];
}

- (void) cancelOperationAndDiscardItemWithCompletion:(MSSyncBlock)completion
{
    MSTableOperation *op = [[MSTableOperation alloc] initWithTable:self.table
                                                              type:self.operation
                                                            itemId:self.itemId];
    op.operationId = self.operationId;
    
    [self.syncContext cancelOperation:op discardItemWithCompletion:^(NSError * _Nullable error) {
        self.handled = !error;
        
        if (completion) {
            completion(error);
        }
    }];
}

- (void) keepOperationAndUpdateItem:(nonnull NSDictionary *)item
                         completion:(nullable MSSyncBlock)completion
{
    [self modifyOperationType:self.operation AndUpdateItem:item completion:completion];
}

- (void) modifyOperationType:(MSTableOperationTypes)type completion:(nullable MSSyncBlock)completion
{
    [self modifyOperationType:type AndUpdateItem:self.item completion:completion];
}

- (void) modifyOperationType:(MSTableOperationTypes)type AndUpdateItem:(nonnull NSDictionary *)item completion:(nullable MSSyncBlock)completion
{
    if (!item) {
        if (completion) {
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Item is required" };
            NSError *error = [NSError errorWithDomain:MSErrorDomain
                                                 code:MSSyncTableCancelError
                                             userInfo:userInfo];
            completion(error);
            return;
        }
    }
    
    MSTableOperation *op = [[MSTableOperation alloc] initWithTable:self.table
                                                              type:type
                                                            itemId:self.itemId];
    
    op.operationId = self.operationId;
    op.item = item;
    
    [self.syncContext updateOperation:op updateItem:item completion:^(NSError * _Nullable error) {
        self.handled = !error;
        if (completion) {
            completion(error);
        }
    }];
}


@end
