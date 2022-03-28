//
//  DTSQLiteDatabase.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 5/22/13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 A wrapper for SQLite databases which offers threadsafe concurrency and support for cancelling long-running operations.
 */

@interface DTSQLiteDatabase : NSObject

/**
 @name Creating a Database
 */

/**
 Opens the sqlite3 database file at the given path
 @param path The file path to the database file
 */
- (id)initWithFileAtPath:(NSString *)path;


/**
 Queries
 */

/**
 Fetches the result rows for a query.
 
 You can call this from any queue/thread as long as it is the only one. For background operations you should call it exclusively via performBlock: or performBlockAndWait: for synchronization.
 @param query The SQL query to execute
 @param error If an error occurs this output parameter will contain it
 @returns An array of `NSDictionary` instances
 */
- (NSArray *)fetchRowsForQuery:(NSString *)query error:(NSError **)error;

/**
 Cancels all currently queued queries
 */
- (void)cancelAllQueries;


/**
 @name Block Operations
 */

/**
 @param block The block to perform
 */
- (void)performBlock:(void (^)(void))block;

/**
 @param block The block to perform
 */
- (void)performBlockAndWait:(void (^)(void))block;

@end
