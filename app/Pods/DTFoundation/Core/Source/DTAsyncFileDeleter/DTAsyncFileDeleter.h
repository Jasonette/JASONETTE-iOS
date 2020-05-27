//
//  DTAsyncFileDeleter.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 2/10/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

/** This class deletes large amounts of files asynchronously. You should use the sharedInstance to get an instance. On iOS this automatically starts a background task if the app is suspended so that file deletion can complete.
 */

@interface DTAsyncFileDeleter : NSObject

/**-------------------------------------------------------------------------------------
 @name Creating A File Deleter
 ---------------------------------------------------------------------------------------
 */

/** Creates a shared file deleter.
 */ 
+ (DTAsyncFileDeleter *)sharedInstance;

/**-------------------------------------------------------------------------------------
 @name Asynchronous Operations
 ---------------------------------------------------------------------------------------
 */

/** Blocks execution of the current thread until the receiver finishes.
 */
- (void)waitUntilFinished;


/** Removes the file or directory at the specified path and immediately returns.
 
 This method moves the given item to a temporary name which is an instant operation. It then schedules an asynchronous background operation to actually remove the item.
 
 @param path A path string indicating the file or directory to remove. If the path specifies a directory, the contents of that directory are recursively removed. 
 */
- (void)removeItemAtPath:(NSString *)path;


/** Removes the file or directory at the specified URL.
 
 This method moves the given item to a temporary name which is an instant operation. It then schedules an asynchronous background operation to actually remove the item.
 
 @param URL A file URL specifying the file or directory to remove. If the URL specifies a directory, the contents of that directory are recursively removed.
 */
- (void)removeItemAtURL:(NSURL *)URL;

@end
