//
//  DTZipArchiveGZip.m
//  DTFoundation
//
//  Created by Stefan Gugarel on 23.01.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DTZipArchiveGZip.h"
#import "DTZipArchiveNode.h"

#include "zip.h"
#include "unzip.h"

@interface DTZipArchiveGZip()

- (NSString *)_inflatedFileName;

/**
 Path of zip file
 */
@property (nonatomic, copy, readwrite) NSString *path;

@property (assign, getter = isCancelling) BOOL cancelling;
@property (assign, getter = isUncompressing) BOOL uncompressing;

@property (readonly, nonatomic) dispatch_queue_t uncompressingQueue;

@end

@implementation DTZipArchiveGZip
{
	/**
	 Data field for the zip archive
    */
	NSData *_data;
	
	NSString *_path;
	
	NSUInteger _uncompressedLength;
	
	/*
	 Queue for asynchronous uncompressing
	 */
	dispatch_queue_t _uncompressingQueue;
	
}


- (id)initWithFileAtPath:(NSString *)sourcePath
{
	self = [super init];
	
	if (self)
	{
		_path = sourcePath;
		
		// only accept if valid file name
		if (![self _inflatedFileName])
		{
			return nil;
		}
		
		_data = [[NSData alloc] initWithContentsOfFile:sourcePath options:NSDataReadingMappedIfSafe error:NULL];
		
		// the last 4 bytes contain the uncompressed size
		// this only works when the uncompressed size of the file is smaller 4GB
		NSRange last4Bytes = NSMakeRange([_data length] - 4, 4);
		char *buffer = malloc(last4Bytes.length);
		[_data getBytes:buffer range:last4Bytes];
		
		_uncompressedLength = 0;
		
		// shift our bytes to get an NSUInteger
		for (NSUInteger i=0; i<last4Bytes.length; i++)
		{
			_uncompressedLength += buffer[i] << (8 * i);
		}
		
		DTZipArchiveNode *singleZipArchiveNode = [[DTZipArchiveNode alloc] init];
		singleZipArchiveNode.name = [[sourcePath lastPathComponent] stringByDeletingPathExtension];
		singleZipArchiveNode.fileSize = _uncompressedLength;
		singleZipArchiveNode.directory = NO;
		
		// we have only 1 entry for GZip
		_listOfEntries = @[singleZipArchiveNode];
		
		_uncompressingQueue = dispatch_queue_create("DTZipArchiveUncompressionQueue", 0);
	}
	
	return self;
}

- (void)dealloc
{
#if !OS_OBJECT_USE_OBJC
	if (_uncompressingQueue)
	{
		dispatch_release(_uncompressingQueue);
	}
#endif
}


#pragma mark - Private methods

- (NSString *)_inflatedFileName
{
	NSString *fileName = [self.path lastPathComponent];
	NSString *extension = [fileName pathExtension];
	
	// man page mentions suffixes .gz, -gz, .z, -z, _z or .Z
	if ([extension isEqualToString:@"gz"] || [extension isEqualToString:@"z"] || [extension isEqualToString:@"Z"])
	{
		fileName = [fileName stringByDeletingPathExtension];
	}
	else if ([fileName hasSuffix:@"-gz"])
	{
		fileName = [fileName substringToIndex:[fileName length]-3];
	}
	else if ([fileName hasSuffix:@"-z"] || [fileName hasSuffix:@"_z"])
	{
		fileName = [fileName substringToIndex:[fileName length]-2];
	}
	else
	{
		fileName = nil;
	}
	
	return fileName;
}

#pragma mark - Overridden methods from DTZipArchive

// adapted from http://www.cocoadev.com/index.pl?NSDataCategory
- (void)enumerateUncompressedFilesAsDataUsingBlock:(DTZipArchiveEnumerationResultsBlock)enumerationBlock
{
	NSUInteger dataLength = [_data length];
	NSUInteger halfLength = dataLength / 2;
	
	NSMutableData *decompressed = [NSMutableData dataWithLength: dataLength + halfLength];
	BOOL done = NO;
	int status;
	
	
	z_stream strm;
	strm.next_in = (Bytef *)[_data bytes];
	strm.avail_in = (uInt)dataLength;
	strm.total_out = 0;
	strm.zalloc = Z_NULL;
	strm.zfree = Z_NULL;
	
	// inflateInit2 knows how to deal with gzip format
	status = inflateInit2(&strm, (15+32));
	
	NSAssert(status == Z_OK, @"This should never be failing, only if out of memory");
	
	while (!done && !self.isCancelling)
	{
		// extend decompressed if too short
		if (strm.total_out >= [decompressed length])
		{
			[decompressed increaseLengthBy: halfLength];
		}
		
		strm.next_out = [decompressed mutableBytes] + strm.total_out;
		strm.avail_out = (uInt)[decompressed length] - (uInt)strm.total_out;
		
		// Inflate another chunk.
		status = inflate (&strm, Z_SYNC_FLUSH);
		
		if (status == Z_STREAM_END)
		{
			done = YES;
		}
		else if (status != Z_OK)
		{
			break;
		}
	}
	
	// we exit here if we did not reach the stream end (e.g. error or cancel)
	if (inflateEnd (&strm) != Z_OK || !done)
	{
		return;
	}
	
	// set actual length
	[decompressed setLength:strm.total_out];
	
	// call back block
	enumerationBlock([self _inflatedFileName], decompressed, NULL);
}

- (void)_uncompressFile:(NSString *)targetPath completion:(DTZipArchiveUncompressFileCompletionBlock)completion
{
	BOOL isDirectory = NO;
	
	if (targetPath != nil && (![[NSFileManager defaultManager] fileExistsAtPath:targetPath isDirectory:&isDirectory] || !isDirectory))
	{
		if (completion)
		{
			NSDictionary *userInfo = @{NSLocalizedDescriptionKey : @"Invalid target path"};
			NSError *error = [[NSError alloc] initWithDomain:DTZipArchiveErrorDomain code:1 userInfo:userInfo];
			
			completion(nil, error);
		}
		
		return;
	}
	
	NSError *error = nil;
	DTZipArchiveNode *node = self.nodes[0];
	
	
	NSData *data;
	
	[self _uncompressZipArchiveNode:node targetPath:targetPath targetData:&data withError:&error];
	
	if (completion && !self.isCancelling)
	{
		completion(data, error);
	}
}

// adapted from http://www.cocoadev.com/index.pl?NSDataCategory
- (void)uncompressToPath:(NSString *)targetPath completion:(DTZipArchiveUncompressionCompletionBlock)completion
{
	NSAssert(!self.isUncompressing, @"Calling %s multiple times is a programming error", __PRETTY_FUNCTION__);
	
	self.uncompressing = YES;
	
	dispatch_async(_uncompressingQueue, ^{
		[self _uncompressFile:targetPath completion:^(NSData *data, NSError *error) {
			
            self->_uncompressing = NO;
			
			if (completion)
			{
				completion(error);
			}
		}];
	});
}

- (NSData *)uncompressZipArchiveNode:(DTZipArchiveNode *)node withError:(NSError **)error
{
	if (![self.nodes containsObject:node])
	{
		if (error)
		{
			NSDictionary *userInfo = @{NSLocalizedDescriptionKey : @"Invalid node specified, cannot uncompress GZip file."};
			*error = [[NSError alloc] initWithDomain:DTZipArchiveErrorDomain code:7 userInfo:userInfo];
		}
		
		return nil;
	}
	
	NSData *data;
	
	[self _uncompressZipArchiveNode:node targetPath:nil targetData:&data withError:error];
	
	return data;
}


// try to uncompress the node, will write to file at targetPath if set and create a data object if data is not nil
- (BOOL)_uncompressZipArchiveNode:(DTZipArchiveNode *)node targetPath:(NSString *)targetPath targetData:(NSMutableData **)data withError:(NSError **)error
{
	NSFileHandle *destinationFileHandle;
	
	if (targetPath)
	{
		NSString *filePath = [targetPath stringByAppendingPathComponent:[self _inflatedFileName]];
		NSURL *fileURL = [NSURL fileURLWithPath:filePath];
		
		NSFileManager *fileManager = [[NSFileManager alloc] init];
		
		// create file handle
		destinationFileHandle = [NSFileHandle fileHandleForWritingToURL:fileURL error:nil];
		
		if (!destinationFileHandle)
		{
			// if we have no file create it first
			if (![fileManager createFileAtPath:filePath contents:nil attributes:nil])
			{
				if (error)
				{
					NSDictionary *userInfo = @{NSLocalizedDescriptionKey : @"Unzip file cannot be created"};
					*error = [[NSError alloc] initWithDomain:DTZipArchiveErrorDomain code:2 userInfo:userInfo];
				}
				
				return NO;
			}
			
			destinationFileHandle = [NSFileHandle fileHandleForWritingToURL:fileURL error:error];
		}
	}

	NSAssert(destinationFileHandle||data, @"Cannot proceed without an output for %s", __PRETTY_FUNCTION__);
	
	NSMutableData *tmpData = [NSMutableData data];
	
	NSMutableData *decompressed = [NSMutableData dataWithLength:BUFFER_SIZE];
	BOOL done = NO;
	int status;
	
	z_stream strm;
	strm.next_in = (Bytef *)[_data bytes];
	strm.avail_in = (uInt)[_data length];
	strm.total_out = 0;
	strm.zalloc = Z_NULL;
	strm.zfree = Z_NULL;
	
	// inflateInit2 knows how to deal with gzip format
	status = inflateInit2(&strm, (15+32));
	
	NSAssert(status == Z_OK, @"This should never be failing, only if out of memory");
	
	// creating queue and group for file writing (files and directories)
	dispatch_queue_t fileWriteQueue;
	dispatch_group_t fileWriteGroup;
	
	fileWriteQueue = dispatch_queue_create("DTZipArchiveFileQueue", 0);
	fileWriteGroup = dispatch_group_create();
	
	// send 0%
	dispatch_async(dispatch_get_main_queue(), ^{
		
		// prepare progress notification
		NSDictionary *userInfo =  @{@"ProgressPercent" : [NSNumber numberWithFloat:0]};
		[[NSNotificationCenter defaultCenter] postNotificationName:DTZipArchiveProgressNotification object:self userInfo:userInfo];
	});
	
	while (!done)
	{
		// extend decompressed if too short
		strm.next_out = [decompressed mutableBytes];
		strm.avail_out = BUFFER_SIZE;
		
		// Inflate another chunk.
		status = inflate (&strm, Z_SYNC_FLUSH);
	
		if (status != Z_OK && status != Z_STREAM_END)
		{
			if (error)
			{
				NSDictionary *userInfo = @{NSLocalizedDescriptionKey : @"Unzip file corrupt"};
				*error = [[NSError alloc] initWithDomain:DTZipArchiveErrorDomain code:9 userInfo:userInfo];
			}
			
			break;
		}
		
		// on last block reduce size of decompressed block
		uInt lengthOfBlock = strm.total_out % BUFFER_SIZE;
		
		if (lengthOfBlock)
		{
			[decompressed setLength:(uInt)lengthOfBlock];
		}
		
		NSMutableData *decompressedBlock = [decompressed mutableCopy];
		
		// add each data block to have all data
		[tmpData appendData:[decompressed copy]];

		float percent = (float)strm.total_out / _uncompressedLength;

		// only write data to disk when we have a valid targetPath (is checked at the beginning of this method)
		dispatch_group_async(fileWriteGroup, fileWriteQueue, ^{
			
			[destinationFileHandle writeData:decompressedBlock];
			
			// always send progress report
			dispatch_async(dispatch_get_main_queue(), ^{
				
				// prepare progress notification
				NSDictionary *userInfo =  @{@"ProgressPercent" : [NSNumber numberWithFloat:percent]};
				[[NSNotificationCenter defaultCenter] postNotificationName:DTZipArchiveProgressNotification object:self userInfo:userInfo];
			});
		});
		
		if (status == Z_STREAM_END)
		{
			done = YES;
		}
	}
	
	dispatch_group_wait(fileWriteGroup, DISPATCH_TIME_FOREVER);
	
#if !OS_OBJECT_USE_OBJC
	dispatch_release(fileWriteQueue);
	dispatch_release(fileWriteGroup);
#endif
	
	if (inflateEnd (&strm) != Z_OK || !done)
	{
		return NO;
	}
	
	if (data)
	{
		*data = [tmpData copy];
	}
	
	return YES;
}

- (void)uncompressZipArchiveNode:(DTZipArchiveNode *)node toDataWithCompletion:(DTZipArchiveUncompressFileCompletionBlock)completion
{
	if ([self.nodes containsObject:node])
	{
		NSError *error = nil;
		
		NSData *data = [self uncompressZipArchiveNode:node withError:&error];
		
		if (completion)
		{
			completion(data, error);
		}
	}
	else
	{
		NSDictionary *userInfo = @{NSLocalizedDescriptionKey : @"Invalid node specified, cannot uncompress GZip file."};
		NSError *error = [[NSError alloc] initWithDomain:DTZipArchiveErrorDomain code:7 userInfo:userInfo];
		
		completion(nil, error);
	}
}

#pragma mark - Properties

@synthesize path = _path;

@end
