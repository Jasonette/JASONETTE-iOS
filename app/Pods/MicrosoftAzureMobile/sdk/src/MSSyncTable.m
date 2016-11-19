// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import "MSQuery.h"
#import "MSSyncTable.h"
#import "MSClientInternal.h"
#import "MSTableOperation.h"
#import "MSSyncContextInternal.h"

@implementation MSSyncTable


#pragma mark * Public Initializer Methods


-(id) initWithName:(NSString *)tableName client:(MSClient *)client;
{
    NSAssert(client.syncContext != nil, @"Client must have an initialized MSSyncContext");

    self = [super init];
    if (self)
    {
        _client = client;
        _name = tableName;
    }
    
    return self;
}


#pragma mark * Public Insert, Update, Delete Methods


-(void)insert:(NSDictionary *)item completion:(MSSyncItemBlock)completion
{
    [self.client.syncContext syncTable:self.name item:item action:MSTableOperationInsert completion:completion];
}

-(void)update:(NSDictionary *)item completion:(MSSyncBlock)completion
{
    [self.client.syncContext syncTable:self.name item:item action:MSTableOperationUpdate completion:^(NSDictionary *item, NSError *error) {
        if (completion) {
            completion(error);
        }
    }];
}

-(void)delete:(NSDictionary *)item completion:(MSSyncBlock)completion
{
    [self.client.syncContext syncTable:self.name item:item action:MSTableOperationDelete completion:^(NSDictionary *item, NSError *error) {
        if (completion) {
            completion(error);
        }
    }];
}


#pragma mark * Public Local Storage Management commands


-(NSOperation *)pullWithQuery:(MSQuery *)query queryId:(NSString *)queryId completion:(MSSyncBlock)completion
{
    return [self pullWithQuery:query queryId:queryId settings:nil completion:completion];
}

-(NSOperation *)pullWithQuery:(MSQuery *)query queryId:(NSString *)queryId settings:(id)pullSettings completion:(MSSyncBlock)completion
{
    return [self.client.syncContext pullWithQuery:query queryId:queryId settings:pullSettings completion:completion];
}

-(NSOperation *)purgeWithQuery:(MSQuery *)query completion:(MSSyncBlock)completion
{
    // If no query, purge all records in the table by default
    if (query == nil) {
        MSQuery *allRecords = [[MSQuery alloc] initWithSyncTable:self];
        return [self.client.syncContext purgeWithQuery:allRecords completion:completion];
        
    } else {
        return [self.client.syncContext purgeWithQuery:query completion:completion];
    }
}

/// Purges all data, pending operations, operation errors, and metadata for the
/// MSSyncTable from the local store.
-(NSOperation *)forcePurgeWithCompletion:(MSSyncBlock)completion
{
    return [self.client.syncContext forcePurgeWithTable:self completion:completion];
}

#pragma mark * Public Read Methods


-(void)readWithId:(NSString *)itemId completion:(MSItemBlock)completion
{
    [self.client.syncContext syncTable:self.name readWithId:itemId completion:completion];
}

-(void)readWithCompletion:(MSReadQueryBlock)completion
{
    MSQuery *query = [[MSQuery alloc] initWithSyncTable:self];
    [query readWithCompletion:completion];
}

-(void)readWithPredicate:(NSPredicate *)predicate completion:(MSReadQueryBlock)completion
{
    MSQuery *query = [[MSQuery alloc] initWithSyncTable:self predicate:predicate];
    [query readWithCompletion:completion];
}


#pragma mark * Public Query Methods


-(MSQuery *)query {
    return [[MSQuery alloc] initWithSyncTable:self];
}

-(MSQuery *)queryWithPredicate:(NSPredicate *)predicate
{
    return [[MSQuery alloc] initWithSyncTable:self predicate:predicate];
}


@end
