// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MSSyncContext.h"

/**
 The MSCoreDataStore class is for use when using the offline capabilities
 of mobile services. This class is a local store which manages records and sync
 logic using CoreData.

 This class assumes the provided managed object context has the following tables:
 - MS_TableOperations:      Columns: id (Integer 64), itemId (string), table (string), properties (binary data)
 - MS_TableOperationErrors: Columns: id (string), properties (binary data)
 - MS_TableConfig:          Columns: id (string), key (string), keyType (integer 64), table (string), value (string)
 - Your logical tables:     Columns: id (string), any additional columns of your choice
 */
@interface MSCoreDataStore : NSObject <MSSyncContextDataSource>

#pragma  mark * Public Static Constructor Methods

/** @name Initializing the MSClient object */

/** 
 Creates a CoreDataStore with the given managed object context.
 
 @param context the NSManagedObjectContext to perform all reads/writes to
 @returns a new MSSyncContext class
 */
-(nonnull instancetype) initWithManagedObjectContext:(nonnull NSManagedObjectContext *)context;

/** @name Modifying MSSyncTable behavior */

/**
 Disables the store from receiving information about the items passed into all sync table
 calls (insert, delete, update). If set, the application is responsible for already having
 saved the item in the persisten store. This flag is intended to be used when application
 code is working directly with NSManagedObjects.
 */
@property (nonatomic) BOOL handlesSyncTableOperations;

/// The NSManagedObjectContext that is associated with this data store
@property (readonly, nonatomic, nonnull, strong) NSManagedObjectContext *context;

#pragma mark * Helper functions

/** @name Working with the table APIs */

/**
 Converts a managed object from the core data layer back into a dictionary with the
 properties expected when using a MSTable or MSSyncTable
 
 @param object the NSManagedObject representation of a table's item
 @returns an NSDictionary representation of the item in the format expected by the server
 */
-(nonnull NSDictionary *) tableItemFromManagedObject:(nonnull NSManagedObject *)object;


@end
