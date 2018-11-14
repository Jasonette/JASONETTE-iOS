/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Interface wrapping sqlite database operations
 */
@interface UASQLite : NSObject

///---------------------------------------------------------------------------------------
/// @name SQLite Internal Properties
///---------------------------------------------------------------------------------------

/**
 * Number of retries before timeout, defaults to 1
 */
@property (atomic, assign) NSInteger busyRetryTimeout;

/**
 * Path string to the sqlite DB
 */
@property (nonatomic, copy, nullable) NSString *dbPath;

///---------------------------------------------------------------------------------------
/// @name SQLite Internal Methods
///---------------------------------------------------------------------------------------

/**
 * Initializes sqlite DB with provided path string
 *
 * @param aDBPath Path to the sqlite DB
 */
- (instancetype)initWithDBPath:(NSString *)aDBPath;

/**
 * Opens the sqlite DB
 *
 * @param aDBPath String representing path of SQLite DB
 * @return YES if sucessful NO if unsucessful
 */
- (BOOL)open:(NSString *)aDBPath;


/**
 * Closes the sqlite DB
 */
- (void)close;

/**
 * Gets the last sqlite error message
 *
 * @return Last error message string
 */
- (nullable NSString*)lastErrorMessage;

/**
 * Gets the last sqlite error code
 *
 * @return Last error code int
 */
- (NSInteger)lastErrorCode;

/**
 * Executes query on database given the database string and arguments
 *
 * @param sql Database string
 * @param ... Variable argument list
 * @return Last error code int
 */
- (nullable NSArray *)executeQuery:(NSString *)sql, ...;

/**
 * Executes query on database given the database string and arguments
 * @param sql Database string
 * @param args Array of arguments
 * @return Last error code int
 */
- (nullable NSArray *)executeQuery:(NSString *)sql arguments:(nullable NSArray *)args;

/**
 * Executes update on database
 *
 * @param sql Database string
 * @param ... Variable argument list
 * @return YES if update succeeded, NO if update failed
 */
- (BOOL)executeUpdate:(NSString *)sql, ...;

/**
 * Executes update on database
 *
 * @param sql Database string
 * @param args Arguments array
 * @return YES if update succeeded, NO if update failed
 */
- (BOOL)executeUpdate:(NSString *)sql arguments:(nullable NSArray *)args;

/**
 * Executes commit transaction on database
 *
 * @return YES if transaction succeeded, NO if transaction failed
 */
- (BOOL)commit;

/**
 * Executes rollback transaction on database
 *
 * @return YES if transaction succeeded, NO if transaction failed
 */
- (BOOL)rollback;

/**
 * Executes exclusive transaction on database
 *
 * @return YES if transaction succeeded, NO if transaction failed
 */
- (BOOL)beginTransaction;

/**
 * Executes deferred transaction on database
 *
 * @return YES if transaction succeeded, NO if transaction failed
 */
- (BOOL)beginDeferredTransaction;

/**
 * Checks if table exists in DB
 *
 * @param tableName Table name string
 * @return YES if table exists, NO if table does not exist
 */
- (BOOL)tableExists:(NSString*)tableName;

/**
 * Checks if index exists in DB
 *
 * @param indexName Index name string
 * @return YES if index exists, NO if index does not exist
 */
- (BOOL)indexExists:(NSString*)indexName;

@end

NS_ASSUME_NONNULL_END
