//
//  DTZipArchive.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 12.02.12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "DTZipArchive.h"
#import "DTZipArchiveGZip.h"
#import "DTZipArchivePKZip.h"
#import "DTZipArchiveNode.h"

#include "zip.h"
#include "unzip.h"

NSString * const DTZipArchiveProgressNotification = @"DTZipArchiveProgressNotification";
NSString * const DTZipArchiveErrorDomain = @"DTZipArchive";

@interface DTZipArchive ()

/**
 Private dedicated initializer
 */
- (id)initWithFileAtPath:(NSString *)path;

@property (assign, getter = isCancelling) BOOL cancelling;
@property (assign, getter = isUncompressing) BOOL uncompressing;

@end


@implementation DTZipArchive
{
	NSString *_path;
	NSArray *_fileTree;
}

+ (DTZipArchive *)archiveAtPath:(NSString *)path;
{
    // detect archive type
    NSData *data = [[NSData alloc] initWithContentsOfFile:path options:NSDataReadingMapped error:NULL];

    if (!data)
    {
        return nil;
    }

    // detect file format
    const char *bytes = [data bytes];

    // Create class cluster for PKZip or GZip depending on first bytes
    if (bytes[0]=='P' && bytes[1]=='K')
    {
        return [[DTZipArchivePKZip alloc] initWithFileAtPath:path];
    }
    else
    {
        return [[DTZipArchiveGZip alloc] initWithFileAtPath:path];
    }
}

#ifndef COVERAGE
- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@ path='%@'>", NSStringFromClass([self class]), self.path];
}
#endif

#pragma mark - Abstract Methods

- (id)initWithFileAtPath:(NSString *)path
{
    [NSException raise:@"DTAbstractClassException" format:@"You tried to call %@ on an abstract class %@",  NSStringFromSelector(_cmd), NSStringFromClass([self class])];

    return self;
}

/**
 Abstract method -> should be never called here directly
 But have to be implemented in SubClass
 */
- (void)enumerateUncompressedFilesAsDataUsingBlock:(DTZipArchiveEnumerationResultsBlock)enumerationBlock
{
    [NSException raise:@"DTAbstractClassException" format:@"You tried to call %@ on an abstract class %@",  NSStringFromSelector(_cmd), NSStringFromClass([self class])];
}

#pragma mark - FileTree

- (NSArray *)nodes
{
	if (!_fileTree)
	{
		NSMutableArray *temporaryfileTree = [[NSMutableArray alloc] init];

		// dictionary for fast finding of directory nodes
		NSMutableDictionary *nodeDictionary = [[NSMutableDictionary alloc] init];

		for (DTZipArchiveNode *node in _listOfEntries)
		{
			NSRange slashOccurence = [node.name rangeOfString:@"/"];
			if (slashOccurence.location == NSNotFound)
			{
				// entry on root level
				[temporaryfileTree addObject:node];

				// when it is a root directory add it also NSDictionary for fast finding
				if (node.isDirectory)
				{
					nodeDictionary[node.name] = node;
				}
			}
			else
			{
				// entry under root level

				// delete last path extension to know parent node
				NSString *parentPath = [node.name stringByDeletingLastPathComponent];
				DTZipArchiveNode *parentNode = nodeDictionary[parentPath];

				// we add only directories to dictionary
				if (node.isDirectory)
				{
					nodeDictionary[node.name] = node;
				}

				[parentNode.children addObject:node];
			}
		}

		_fileTree = [temporaryfileTree copy];
	}

	return _fileTree;
}

#pragma mark - Properties

@synthesize path;

@end

@implementation DTZipArchive(Uncompressing)

/**
 Abstract methods -> should be never called here directly
 But have to be implemented in SubClass
 */
- (void)uncompressToPath:(NSString *)targetPath completion:(DTZipArchiveUncompressionCompletionBlock)completion
{
    [NSException raise:@"DTAbstractClassException" format:@"You tried to call %@ on an abstract class %@",  NSStringFromSelector(_cmd), NSStringFromClass([self class])];
}

- (void)cancelAllUncompressing
{
	if (self.isUncompressing)
	{
		self.cancelling = YES;
	}
}

- (NSData *)uncompressZipArchiveNode:(DTZipArchiveNode *)node withError:(NSError **)error
{
	[NSException raise:@"DTAbstractClassException" format:@"You tried to call %@ on an abstract class %@",  NSStringFromSelector(_cmd), NSStringFromClass([self class])];
	
	return nil;
}

- (void)uncompressZipArchiveNode:(DTZipArchiveNode *)node toDataWithCompletion:(DTZipArchiveUncompressFileCompletionBlock)completion
{
	[NSException raise:@"DTAbstractClassException" format:@"You tried to call %@ on an abstract class %@",  NSStringFromSelector(_cmd), NSStringFromClass([self class])];
}

@end
