//
//  DTAsyncFileDeleter.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 2/10/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import "DTAsyncFileDeleter.h"
#import "NSString+DTPaths.h"

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif


static dispatch_queue_t _delQueue;
static dispatch_group_t _delGroup;
static dispatch_once_t onceToken;

static dispatch_queue_t _renameQueue;

static DTAsyncFileDeleter *_sharedInstance;


// private utilites
@interface DTAsyncFileDeleter ()
- (BOOL)_supportsTaskCompletion;
@end


@implementation DTAsyncFileDeleter

+ (DTAsyncFileDeleter *)sharedInstance
{
	static dispatch_once_t instanceOnceToken;
	dispatch_once(&instanceOnceToken, ^{
		_sharedInstance = [[DTAsyncFileDeleter alloc] init];
	});
	
	return _sharedInstance;
}

- (id)init
{
	self = [super init];
	if (self)
	{
		dispatch_once(&onceToken, ^{
			_delQueue = dispatch_queue_create("DTAsyncFileDeleterRemoveQueue", 0);
			_delGroup = dispatch_group_create();
			_renameQueue = dispatch_queue_create("DTAsyncFileDeleterRenameQueue", 0);
		});
	}
	
	return self;
}

- (void)waitUntilFinished
{
	dispatch_group_wait(_delGroup, DISPATCH_TIME_FOREVER);
}

- (void)removeItemAtPath:(NSString *)path
{
	// make a unique temporary name in tmp folder
	NSString *tmpPath = [NSString pathForTemporaryFile];
	
	// rename the file, waiting for the rename to finish before async deletion
	dispatch_sync(_renameQueue, ^{
		NSFileManager *fileManager = [[NSFileManager alloc] init];
		
		if ([fileManager moveItemAtPath:path toPath:tmpPath error:NULL])
		{
			// schedule the removal and immediately return
			dispatch_group_async(_delGroup, _delQueue, ^{
#if TARGET_OS_IPHONE && !defined(DT_APP_EXTENSIONS) && !TARGET_OS_WATCH
				__block UIBackgroundTaskIdentifier backgroundTaskID = UIBackgroundTaskInvalid;
				
				// block to use for timeout as well as completed task
				void (^completionBlock)(void) = ^{
					[[UIApplication sharedApplication] endBackgroundTask:backgroundTaskID];
					backgroundTaskID = UIBackgroundTaskInvalid;
				};
				
				if ([self _supportsTaskCompletion])
				{
					// according to docs this is safe to be called from background threads
					backgroundTaskID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:completionBlock];
				}
#endif
				
				// file manager is not used any more in the rename queue, so we reuse it
				[fileManager removeItemAtPath:tmpPath error:NULL];
				
#if TARGET_OS_IPHONE && !defined(DT_APP_EXTENSIONS) && !TARGET_OS_WATCH
				// ... when the task completes:
				if (backgroundTaskID != UIBackgroundTaskInvalid)
				{
					completionBlock();
				}
#endif
			});
		}
	});
}

- (void)removeItemAtURL:(NSURL *)URL
{
	NSAssert([URL isFileURL], @"Parameter URL must be a file URL");
	
	[self removeItemAtPath:[URL path]];
}

#pragma mark Utilities
- (BOOL)_supportsTaskCompletion
{
#if TARGET_OS_IPHONE && !TARGET_OS_WATCH
	UIDevice *device = [UIDevice currentDevice];
	
	if ([device respondsToSelector:@selector(isMultitaskingSupported)])
	{
		if (device.multitaskingSupported)
		{
			return YES;
		}
		else
		{
			return NO;
		}
	}
#endif
	
	return NO;
}

@end
