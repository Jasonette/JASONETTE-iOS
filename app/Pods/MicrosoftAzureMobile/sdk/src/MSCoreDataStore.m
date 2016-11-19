// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import "MSCoreDataStore.h"
#import "MSTable.h"
#import "MSSyncTable.h"
#import "MSQuery.h"
#import "MSSyncContextReadResult.h"
#import "MSError.h"

@interface MSCoreDataStore()
@property (nonatomic, strong) NSManagedObjectContext *context;
@end

@implementation MSCoreDataStore

-(id) initWithManagedObjectContext:(NSManagedObjectContext *)context
{
    self = [super init];
    if (self) {
        _context = context;
		_handlesSyncTableOperations = YES;
    }
    return self;
}

-(NSString *) operationTableName {
    return @"MS_TableOperations";
}

-(NSString *) errorTableName {
    return @"MS_TableOperationErrors";
}

-(NSString *) configTableName {
    return @"MS_TableConfig";
}

/// Helper function to get a specific record from a table, if
-(NSManagedObject *) getRecordForTable:(NSString *)table itemId:(NSString *)itemId orError:(NSError **)error
{
    // Create the entity description
    NSEntityDescription *entity = [NSEntityDescription entityForName:table inManagedObjectContext:self.context];
    if (!entity) {
        if (error) {
            *error = [MSCoreDataStore errorInvalidTable:table];
        }
        return nil;
    }
    
    NSFetchRequest *fr = [[NSFetchRequest alloc] init];
    [fr setEntity:entity];
    
    fr.predicate = [NSPredicate predicateWithFormat:@"%K ==[c] %@", MSSystemColumnId, itemId];
    
    NSArray<__kindof NSManagedObject *> *results = [self.context executeFetchRequest:fr error:error];
    if (!results || (error && *error)) {
        return nil;
    }
    
    return [results firstObject];
}

-(NSDictionary *) tableItemFromManagedObject:(NSManagedObject *)object
{
    return [self tableItemFromManagedObject:object properties:nil];
}

-(NSDictionary *) tableItemFromManagedObject:(NSManagedObject *)object properties:(NSArray<NSString *> *)properties
{
    if (!properties) {
        properties = [object.entity.attributesByName allKeys];
    }
    
    // Remove any attributes in the dictionary that are not also in the data model
    NSMutableDictionary *serverItem = [[object dictionaryWithValuesForKeys:properties] mutableCopy];
    
    // We need to fix the JSON encoding of this item, by remaking any boolean attributes as explicit
    // NSNumber numberWithBools, or else the encoder will treat them as 1/0 instead of true/false
    for (NSString *property in properties) {
        NSAttributeDescription *attribute = object.entity.attributesByName[property];
        if (attribute.attributeType == NSBooleanAttributeType) {
            if ([serverItem objectForKey:property] != [NSNull null]) {
                serverItem[property] = @([serverItem[property] boolValue]);
            }
        }
    }

    return serverItem;
}

/// Helper function to convert a server (external) item to only contain the appropriate keys for storage
/// in core data tables. This means we need to change system columns (prefix: __) to use ms_, and remove
/// any retrieved columns from the user's schema that aren't in the local store's schema
+(NSDictionary *) internalItemFromExternalItem:(NSDictionary *)item forEntityDescription:(NSEntityDescription *)entityDescription
{
    NSMutableDictionary *modifiedItem = [item mutableCopy];

    // Remove any attributes in the dictionary that are not also in the data model
    NSMutableDictionary *adjustedItem = [NSMutableDictionary new];
    for (NSString *attributeName in entityDescription.attributesByName) {
        [adjustedItem setValue:[modifiedItem objectForKey:attributeName] forKey:attributeName];
    }

    return adjustedItem;
}


#pragma mark - MSSyncContextDataSource


-(NSUInteger) systemPropertiesForTable:(NSString *)table
{
    MSSystemProperties properties = MSSystemPropertyNone;
    NSEntityDescription *entity = [NSEntityDescription entityForName:table
                                              inManagedObjectContext:self.context];
    
    NSDictionary *columns = [entity propertiesByName];
    
    if ([columns objectForKey:MSSystemColumnVersion]) {
        properties = properties | MSSystemPropertyVersion;
    }
    if ([columns objectForKey:MSSystemColumnCreatedAt]) {
        properties = properties | MSSystemPropertyCreatedAt;
    }
    if ([columns objectForKey:MSSystemColumnUpdatedAt]) {
        properties = properties | MSSystemPropertyUpdatedAt;
    }
    if ([columns objectForKey:MSSystemColumnDeleted]) {
        properties = properties | MSSystemPropertyDeleted;
    }
    
    return properties;
}

-(NSDictionary *)readTable:(NSString *)table withItemId:(NSString *)itemId orError:(NSError *__autoreleasing *)error
{
    __block NSDictionary *item;
    [self.context performBlockAndWait:^{
        NSManagedObject *rawItem = [self getRecordForTable:table itemId:itemId orError:error];
        if (rawItem) {
            item = [self tableItemFromManagedObject:rawItem];
        }
    }];
    
    return item;
}

-(MSSyncContextReadResult *)readWithQuery:(MSQuery *)query orError:(NSError *__autoreleasing *)error
{
    __block NSInteger totalCount = -1;
    __block NSArray<NSDictionary *> *results;
    __block NSError *internalError;
    [self.context performBlockAndWait:^{
        // Create the entity description
        NSEntityDescription *entity = [NSEntityDescription entityForName:query.syncTable.name inManagedObjectContext:self.context];
        if (!entity) {
            internalError = [MSCoreDataStore errorInvalidTable:query.syncTable.name];
            return;
        }
        
        NSFetchRequest *fr = [[NSFetchRequest alloc] init];
        fr.entity = entity;
        fr.predicate = query.predicate;
        fr.sortDescriptors = query.orderBy;

        // Only calculate total count if fetchLimit/Offset is set
        if (query.includeTotalCount && (query.fetchLimit != -1 || query.fetchOffset != -1)) {
            totalCount = [self.context countForFetchRequest:fr error:&internalError];
            if (internalError) {
                return;
            }
            
            // If they just want a count quit out
            if (query.fetchLimit == 0) {
                return;
            }
        }
        
        if (query.fetchOffset != -1) {
            fr.fetchOffset = query.fetchOffset;
        }
        
        if (query.fetchLimit != -1) {
            fr.fetchLimit = query.fetchLimit;
        }
        
        NSMutableArray *properties;
        if (query.selectFields) {
            // We don't let users opt out of version for now to be safe
            NSAttributeDescription *versionProperty;
            for (NSAttributeDescription *desc in entity.properties) {
                if ([desc.name isEqualToString:MSSystemColumnVersion]) {
                    versionProperty = desc;
                    break;
                }
            }
            
            properties = [query.selectFields mutableCopy];
            if (![properties containsObject:MSSystemColumnVersion] && versionProperty) {
                [properties addObject:MSSystemColumnVersion];
            }
        }
        
        NSArray<__kindof NSManagedObject *> *rawResult = [self.context executeFetchRequest:fr error:&internalError];
        if (internalError) {
            return;
        }
        
        // Convert NSKeyedDictionary to regular dictionary objects since for now keyed dictionaries don't
        // seem to convert to mutable dictionaries as a user may expect
        NSMutableArray<NSDictionary *> *finalResult = [[NSMutableArray alloc] initWithCapacity:rawResult.count];
        [rawResult enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSDictionary *adjustedItem = [self tableItemFromManagedObject:obj properties:properties];
            [finalResult addObject:adjustedItem];
        }];
        
        // If there was no fetch/skip (totalCount will still be -1) and total count requested, use the results array for the count
        if (query.includeTotalCount && totalCount == -1) {
            totalCount = results.count;
        }
        
        results = finalResult;
    }];
    
    if (internalError) {
        if (error) {
            *error = internalError;
        }
        return nil;
    } else {
        return [[MSSyncContextReadResult alloc] initWithCount:totalCount items:results];
    }
}

-(BOOL) upsertItems:(NSArray<NSDictionary *> *)items table:(NSString *)table orError:(NSError *__autoreleasing *)error
{
    __block BOOL success;
    [self.context performBlockAndWait:^{
        NSEntityDescription *entity = [NSEntityDescription entityForName:table inManagedObjectContext:self.context];
        if (!entity) {
            if (error) {
                *error = [MSCoreDataStore errorInvalidTable:table];
            }
            return;
        }
        
        for (NSDictionary *item in items) {
            NSManagedObject *managedItem = [self getRecordForTable:table itemId:[item objectForKey:MSSystemColumnId] orError:error];
            if (error && *error) {
                // Reset since we may have made changes earlier
                [self.context reset];
                return;
            }
            
            if (managedItem == nil) {
                managedItem = [NSEntityDescription insertNewObjectForEntityForName:table
                                                            inManagedObjectContext:self.context];
            }
            
            NSDictionary *managedItemDictionary = [MSCoreDataStore internalItemFromExternalItem:item forEntityDescription:entity];
            [managedItem setValuesForKeysWithDictionary:managedItemDictionary];
        }
        
        success = [self.context save:error];
        if (!success) {
            [self.context reset];
        }
    }];
    
    return success;
}

-(BOOL) deleteItemsWithIds:(NSArray<NSString *> *)items table:(NSString *)table orError:(NSError **)error
{
    __block BOOL success;
    [self.context performBlockAndWait:^{
        for (NSString *itemId in items) {
            NSManagedObject *foundItem = [self getRecordForTable:table itemId:itemId orError:error];
            if (error && *error) {
                [self.context reset];
                return;
            }
            
            if (foundItem) {
                [self.context deleteObject:foundItem];
            }
        }
        
        success = [self.context save:error];
        if (!success) {
            [self.context reset];
        }
    }];
    
    return success;
}

-(BOOL) deleteUsingQuery:(MSQuery *)query orError:(NSError *__autoreleasing *)error
{
    __block BOOL success;
    [self.context performBlockAndWait:^{
        NSEntityDescription *entity = [NSEntityDescription entityForName:query.syncTable.name inManagedObjectContext:self.context];
        if (!entity) {
            if (error) {
                *error = [MSCoreDataStore errorInvalidTable:query.syncTable.name];
            }
            return;
        }
        
        NSFetchRequest *fr = [[NSFetchRequest alloc] init];
        fr.entity = entity;
        fr.predicate = query.predicate;
        fr.sortDescriptors = query.orderBy;
        
        if (query.fetchOffset != -1) {
            fr.fetchOffset = query.fetchOffset;
        }
        
        if (query.fetchLimit != -1) {
            fr.fetchLimit = query.fetchLimit;
        }
        
        fr.includesPropertyValues = NO;
        
        NSArray<__kindof NSManagedObject *> *array = [self.context executeFetchRequest:fr error:error];
        for (NSManagedObject *object in array) {
            [self.context deleteObject:object];
        }
        
        success = [self.context save:error];
        if (!success) {
            [self.context reset];
        }
    }];
    
    return success;
}


# pragma mark Error helpers

+ (NSError *) errorInvalidTable:(NSString *)table
{
    NSDictionary *errorDetails = @{ NSLocalizedDescriptionKey:
                                        [NSString stringWithFormat:@"Table '%@' not found", table] };
    
    return [NSError errorWithDomain:MSErrorDomain
                               code:MSSyncTableLocalStoreError
                           userInfo:errorDetails];
}

@end
