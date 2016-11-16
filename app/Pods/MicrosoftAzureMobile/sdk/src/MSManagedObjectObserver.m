// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import "MSManagedObjectObserver.h"
#import "MSCoreDataStore.h"
#import "MSClient.h"
#import "MSSyncTable.h"
#import <CoreData/CoreData.h>

@interface MSManagedObjectObserver()

@property (nonatomic, strong) MSClient *client;
@property (nonatomic, weak) NSManagedObjectContext *context;
@property (nonatomic, weak) MSCoreDataStore *store;

@end

@implementation MSManagedObjectObserver

- (instancetype) initWithClient:(MSClient *)client context:(NSManagedObjectContext *)context
{
    self = [super init];
    
    NSAssert(context != nil, @"context may not be nil");
    
    if (self) {
        if (![client.syncContext.dataSource isKindOfClass:[MSCoreDataStore class]]) {
            // Throw error
            return nil;
        }
        
        _store = client.syncContext.dataSource;
        NSAssert(_store.context != context, @"Observed context may not be the client's context");
        
        _client = client;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleDidSaveNotification:)
                                                     name:NSManagedObjectContextDidSaveNotification
                                                   object:context];
        
		// Modify the handling of sync table operations for this instance of the data source
		_client.syncContext.dataSource.handlesSyncTableOperations = NO;
    }
    return self;
}

- (void)dealloc
{
	if (self.context != nil)
	{
		[[NSNotificationCenter defaultCenter] removeObserver:self
														name:NSManagedObjectContextDidSaveNotification
													  object:self.context];
	}
}

/// Checks the entity has the ms_version attribute to signal it should
/// be synchronised to the mobile service
- (BOOL)entityHasRemoteStoreAttributes:(NSManagedObject *)managedObject
{
	return (managedObject.entity.attributesByName[@"version"] != nil);
}

- (void)handleDidSaveNotification:(NSNotification *)notification
{
	NSSet *insertedObjects = notification.userInfo[NSInsertedObjectsKey];
	for (NSManagedObject *insertedObject in insertedObjects)
	{
		if (![self entityHasRemoteStoreAttributes:insertedObject]) {
			// Only apply table operations on entities we expect to be managed by the mobile service
			continue;
		}
		
		NSString *tableName = insertedObject.entity.name;
        NSDictionary *tableItem = [self.store tableItemFromManagedObject:insertedObject];
		
		MSSyncTable *syncTable = [self.client syncTableWithName:tableName];
		[syncTable insert:tableItem completion:^(NSDictionary *item, NSError *error) {
			if (self.observerActionCompleted != nil)
			{
				self.observerActionCompleted(MSTableOperationInsert, tableItem, error);
			}
		}];
	}
	
	NSSet *updatedObjects = notification.userInfo[NSUpdatedObjectsKey];
	for (NSManagedObject *updatedObject in updatedObjects)
	{
		if (![self entityHasRemoteStoreAttributes:updatedObject]) {
			// Only apply table operations on entities we expect to be managed by the mobile service
			continue;
		}
		
		NSString *tableName = updatedObject.entity.name;
        NSDictionary *tableItem = [self.store tableItemFromManagedObject:updatedObject];
		
		MSSyncTable *syncTable = [self.client syncTableWithName:tableName];
		[syncTable update:tableItem completion:^(NSError *error) {
			if (self.observerActionCompleted != nil)
			{
				self.observerActionCompleted(MSTableOperationUpdate, tableItem, error);
			}
		}];
	}
	
	NSSet *deletedObjects = notification.userInfo[NSDeletedObjectsKey];
	for (NSManagedObject *deletedObject in deletedObjects)
	{
		if (![self entityHasRemoteStoreAttributes:deletedObject]) {
			// Only apply table operations on entities we expect to be managed by the mobile service
			continue;
		}
		
		NSString *tableName = deletedObject.entity.name;
		NSDictionary *tableItem = [self.store tableItemFromManagedObject:deletedObject];
		
		MSSyncTable *syncTable = [self.client syncTableWithName:tableName];
		[syncTable delete:tableItem completion:^(NSError *error) {
			if (self.observerActionCompleted != nil)
			{
				self.observerActionCompleted(MSTableOperationDelete, tableItem, error);
			}
		}];
	}
}

@end
