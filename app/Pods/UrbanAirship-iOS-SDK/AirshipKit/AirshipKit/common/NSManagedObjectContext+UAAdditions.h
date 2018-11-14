/* Copyright 2017 Urban Airship and Contributors */

#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSManagedObjectContext (UAAdditions)


/**
 * Creates a managed object context in the UA no backup directory.
 * @param modelURL The url to coredata model.
 * @param concurrencyType The managed object's concurrency type.
 * @return A managed object context.
 */
+ (instancetype)managedObjectContextForModelURL:(NSURL *)modelURL
                                concurrencyType:(NSManagedObjectContextConcurrencyType)concurrencyType;


/**
 * Attempts to add a persistent sql store to the managed object. The store will be created
 * in an Urban Airship no backup directory.
 *
 * @param storeName The store name.
 * @param completionHandler Completion handler called with the result.
 */
- (void)addPersistentSqlStore:(NSString *)storeName
            completionHandler:(void(^ __nonnull)(BOOL, NSError *))completionHandler;

/**
 * Calls `context save` but first checks if it has a persistent store.
 * @return `YES` if the context was able to save, otherwise `NO`.
 */
- (BOOL)safeSave;

/**
 * Performs a block with the passed in boolean indicating if it's safe to perform
 * operations. Safe is determined by checking if the context has any persistent stores.
 * @param block A block to perform.
 */
- (void)safePerformBlock:(void (^)(BOOL))block;


@end

NS_ASSUME_NONNULL_END
