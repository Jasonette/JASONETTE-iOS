// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import <Foundation/Foundation.h>
#import "MSClient.h"
#import "MSTableOperation.h"
#import "MSSyncContext.h"

@class MSClient;
@protocol MSSyncContextDataSource;
@protocol MSSyncContextDelegate;

@interface MSTableOperation()

@property (nonatomic) NSInteger operationId;

@property (nonatomic, weak)   MSClient *client;
@property (atomic)            BOOL inProgress;
@property (nonatomic, weak)   id<MSSyncContextDataSource> dataSource;
@property (nonatomic, weak)   id<MSSyncContextDelegate> delegate;
@property (nonatomic)         MSTableOperationTypes type;
@property (nonatomic, weak)   NSOperation *pushOperation;

- (NSDictionary *) serialize;

/// Initialized an *MSTableOperation* instance from a record in the local store
-(id) initWithItem:(NSDictionary *)item;

/// Initializes an *MSTableOperation* instance for the given type, table, and item.
-(id) initWithTable:(NSString *)tableName
               type:(MSTableOperationTypes)type
             itemId:(NSString *)item;

/// Initializes an *MSPushOperation* instance for the given type, table, and item.
+(MSTableOperation *) pushOperationForTable:(NSString *)tableName
                                       type:(MSTableOperationTypes)type
                                     itemId:(NSString *)item;


/// Operation helper for tables
typedef NS_OPTIONS(NSUInteger, MSCondenseAction) {
    MSCondenseRemove = 0,
    MSCondenseKeep,
    MSCondenseToDelete,
    MSCondenseNotSupported,
    MSCondenseAddNew
};

/// Determines if two operations can be represented as a single operation in the queue
+ (MSCondenseAction) condenseAction:(MSTableOperationTypes)newAction withExistingOperation:(MSTableOperation *)operation;

@end

