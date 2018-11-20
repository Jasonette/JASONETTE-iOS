/* Copyright 2017 Urban Airship and Contributors */

#import "NSManagedObjectContext+UAAdditions.h"
#import "UAUtils.h"
#import "UAGlobal.h"

@implementation NSManagedObjectContext (UAAdditions)

NSString *const UAManagedContextStoreDirectory = @"com.urbanairship.no-backup";

+ (NSManagedObjectContext *)managedObjectContextForModelURL:(NSURL *)modelURL
                                           concurrencyType:(NSManagedObjectContextConcurrencyType)concurrencyType {

    NSManagedObjectModel *mom = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:concurrencyType];
    [moc setPersistentStoreCoordinator:psc];
    return moc;
}

- (void)addPersistentSqlStore:(NSString *)storeName
            completionHandler:(void(^ __nonnull)(BOOL, NSError *))completionHandler {

    [self performBlock:^{


        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSURL *libraryDirectoryURL = [[fileManager URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject];
        NSURL *cachesDirectoryURL = [[fileManager URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
        NSURL *libraryStoreDirectoryURL = [libraryDirectoryURL URLByAppendingPathComponent:UAManagedContextStoreDirectory];
        NSURL *cachesStoreDirectoryURL = [cachesDirectoryURL URLByAppendingPathComponent:UAManagedContextStoreDirectory];

        NSURL *storeURL;

        // Create the store directory if it doesn't exist
        if ([fileManager fileExistsAtPath:[libraryStoreDirectoryURL path]]) {
            storeURL = [libraryStoreDirectoryURL URLByAppendingPathComponent:storeName];
        } else if ([fileManager fileExistsAtPath:[cachesStoreDirectoryURL path]]) {
            storeURL = [cachesStoreDirectoryURL URLByAppendingPathComponent:storeName];
        } else {
            NSError *error = nil;
            if ([fileManager createDirectoryAtURL:libraryStoreDirectoryURL withIntermediateDirectories:YES attributes:nil error:&error]) {
                storeURL = [libraryStoreDirectoryURL URLByAppendingPathComponent:storeName];
                [UAUtils addSkipBackupAttributeToItemAtURL:libraryStoreDirectoryURL];
            } else if ([fileManager createDirectoryAtURL:cachesStoreDirectoryURL withIntermediateDirectories:YES attributes:nil error:&error]) {
                storeURL = [cachesStoreDirectoryURL URLByAppendingPathComponent:storeName];
                [UAUtils addSkipBackupAttributeToItemAtURL:cachesStoreDirectoryURL];
            } else {
                completionHandler(NO, error);
                return;
            }
        }

        for (NSPersistentStore *store in self.persistentStoreCoordinator.persistentStores) {
            if ([store.URL isEqual:storeURL] && [store.type isEqualToString:NSSQLiteStoreType]) {
                completionHandler(YES, nil);
                return;
            }
        }

        NSError *error = nil;
        NSDictionary *options = @{ NSMigratePersistentStoresAutomaticallyOption : @YES,
                                   NSInferMappingModelAutomaticallyOption : @YES };

        if (![self.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
            completionHandler(NO, error);
            return;
        }

        completionHandler(YES, nil);
    }];
}

- (void)safePerformBlock:(void (^)(BOOL))block {
    [self performBlock:^{
        if (self.persistentStoreCoordinator.persistentStores.count) {
            block(YES);
        } else {
            block(NO);
        }
    }];
}

- (BOOL)safeSave {
    NSError *error;
    if (!self.persistentStoreCoordinator.persistentStores.count) {
        UA_LERR(@"Unable to save context. Missing persistent store.");
        return NO;
    }

    [self save:&error];

    if (error) {
        UA_LERR(@"Error saving context %@", error);
        return NO;
    }

    return YES;
}

@end
