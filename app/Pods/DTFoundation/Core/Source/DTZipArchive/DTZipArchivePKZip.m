//
//  DTZipArchivePKZip.m
//  DTFoundation
//
//  Created by Stefan Gugarel on 23.01.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DTZipArchivePKZip.h"
#import "DTZipArchiveNode.h"

#include "zip.h"
#include "unzip.h"

@interface DTZipArchivePKZip()

- (void)_buildIndex;

/**
 Path of zip file
 */
@property (nonatomic, copy, readwrite) NSString *path;

@property (assign, getter = isCancelling) BOOL cancelling;
@property (assign, getter = isUncompressing) BOOL uncompressing;

@end

@implementation DTZipArchivePKZip
{
	/**
	 Total size of all files uncompressed
	 */
	long long _totalSize;
	
	/**
	 Includes files only
	 */
	long long _totalNumberOfFiles;
	
	/**
	 Includes files and folders
	 */
	long long _totalNumberOfItems;
	
	NSString *_path;
	
	/*
	 Pointer to file to unzip
	 */
	unzFile _unzFile;
	
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
		self.path = sourcePath;
		
		[self _buildIndex];
		
		_uncompressingQueue = dispatch_queue_create("DTZipArchiveUncompressionQueue", 0);
	}
	
	return self;
}

- (void)dealloc
{
	if (_unzFile)
	{
		unzClose(_unzFile);
	}
	
#if !OS_OBJECT_USE_OBJC
	dispatch_release(_uncompressingQueue);
#endif
}

#pragma mark - Private methods

/**
 Build the index of files to uncompress that we can calculate a progress later when uncompressing.
 */
- (void)_buildIndex
{
	NSMutableArray *tmpArray = [NSMutableArray array];
	
	// open the file for unzipping
	_unzFile = unzOpen((const char *)[self.path UTF8String]);
	
	// return if failed
	if (!_unzFile)
	{
		return;
	}
	
	// get file info
	unz_global_info  globalInfo = {0};
	
	if (unzGetGlobalInfo(_unzFile, &globalInfo )!=UNZ_OK )
	{
		// there's a problem
		return;
	}
	
	if (unzGoToFirstFile(_unzFile)!=UNZ_OK)
	{
		// unable to go to first file
		return;
	}
	
	// enum block can stop loop
	BOOL shouldStop = NO;
	
	// iterate through all files
	do
	{
		unz_file_info zipInfo ={0};
		
		if (unzOpenCurrentFile(_unzFile) != UNZ_OK)
		{
			// error uncompressing this file
			return;
		}
		
		// first call for file info so that we know length of file name
		if (unzGetCurrentFileInfo(_unzFile, &zipInfo, NULL, 0, NULL, 0, NULL, 0) != UNZ_OK)
		{
			// cannot get file info
			unzCloseCurrentFile(_unzFile);
			return;
		}
		
		// reserve space for file name
		char *fileNameC = (char *)malloc(zipInfo.size_filename+1);
		
		// second call to get actual file name
		unzGetCurrentFileInfo(_unzFile, &zipInfo, fileNameC, zipInfo.size_filename + 1, NULL, 0, NULL, 0);
		fileNameC[zipInfo.size_filename] = '\0';
		NSString *fileName = [NSString stringWithUTF8String:fileNameC];
		free(fileNameC);
		
		/*
		 // get the file date
		 NSDateComponents *comps = [[NSDateComponents alloc] init];
		 
		 // NOTE: zips have no time zone
		 if (zipInfo.dosDate)
		 {
		 // dosdate spec: http://msdn.microsoft.com/en-us/library/windows/desktop/ms724247(v=vs.85).aspx
		 
		 comps.year = ((zipInfo.dosDate>>25)&127) + 1980;  // 7 bits
		 comps.month = (zipInfo.dosDate>>21)&15;  // 4 bits
		 comps.day = (zipInfo.dosDate>>16)&31; // 5 bits
		 comps.hour = (zipInfo.dosDate>>11)&31; // 5 bits
		 comps.minute = (zipInfo.dosDate>>5)&63;	// 6 bits
		 comps.second = (zipInfo.dosDate&31) * 2;  // 5 bits
		 }
		 else
		 {
		 comps.day = zipInfo.tmu_date.tm_mday;
		 comps.month = zipInfo.tmu_date.tm_mon + 1;
		 comps.year = zipInfo.tmu_date.tm_year;
		 comps.hour = zipInfo.tmu_date.tm_hour;
		 comps.minute = zipInfo.tmu_date.tm_min;
		 comps.second = zipInfo.tmu_date.tm_sec;
		 }
		 NSDate *fileDate = [[NSCalendar currentCalendar] dateFromComponents:comps];
		 */
		
		DTZipArchiveNode *file = [[DTZipArchiveNode alloc] init];
		
		// change to only use forward slashes
		fileName = [fileName stringByReplacingOccurrencesOfString:@"\\" withString:@"/"];
		
		if ([fileName hasSuffix:@"/"])
		{
			file.directory = YES;
			fileName = [fileName substringToIndex:[fileName length]-1];
		}
		else
		{
			file.directory = NO;
		}
		
		// save file name and size
		file.name = fileName;
		file.fileSize = zipInfo.uncompressed_size;
		_totalSize += file.fileSize;
		_totalNumberOfItems++;
		
		// only files are counted
		if (!file.isDirectory)
		{
			_totalNumberOfFiles++;
		}
		
		// add to list of nodes
		[tmpArray addObject:file];
		
		// close the current file
		unzCloseCurrentFile(_unzFile);
	}
	while (!shouldStop && unzGoToNextFile(_unzFile )==UNZ_OK);
	
	if ([tmpArray count])
	{
		_listOfEntries = tmpArray;
	}
}


/**
 Creates an error and fires completion block
 */
- (NSError *)_errorWithText:(NSString *)errorText code:(NSUInteger)code underlyingError:(NSError *)underlyingError
{
	NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
	
	if (errorText)
	{
		userInfo[NSLocalizedDescriptionKey] = errorText;
	}
	
	if (underlyingError)
	{
		userInfo[NSUnderlyingErrorKey] = underlyingError;
	}
	
	return [NSError errorWithDomain:DTZipArchiveErrorDomain code:code userInfo:[userInfo copy]];
}

#pragma mark - Overridden methods from DTZipArchive

/**
 Uncompress a PKZip file to a given path
 
 @param targetPath path to extract the PKZip
 @param completion block that is executed on success or failure (with a given error + description). On success the error is nil.
 */
- (void)uncompressToPath:(NSString *)targetPath completion:(DTZipArchiveUncompressionCompletionBlock)completion
{
	NSAssert(!self.isUncompressing, @"Calling %s multiple times is a programming error", __PRETTY_FUNCTION__);
	
	self.uncompressing = YES;
	__block NSError *error = nil;
	
	BOOL isDirectory = NO;
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:targetPath isDirectory:&isDirectory] || !isDirectory)
	{
		if (completion)
		{
			error = [self _errorWithText:@"Invalid target path" code:1 underlyingError:nil];
			
			NSDictionary *userInfo = @{NSLocalizedDescriptionKey : @"Invalid target path"};
			error = [[NSError alloc] initWithDomain:DTZipArchiveErrorDomain code:1 userInfo:userInfo];
			
			completion(error);
		}
		
		return;
	}
	
	if (!_unzFile)
	{
		// should never get here with a NULL pointer, that means that the index building did not work
		if (completion)
		{
			error = [self _errorWithText:@"Unable to open file for unzipping" code:4 underlyingError:nil];
			
			completion(error);
		}
		
		return;
	}
	
	if (unzGoToFirstFile(_unzFile) != UNZ_OK)
	{
		if (completion)
		{
			error = [self _errorWithText:@"Unable to go to first file in zip archive" code:3 underlyingError:nil];

			completion(error);
		}
		
		return;
	}
	
	__block long long numberOfFilesUncompressed = 0;
	__block long long numberOfItemsUncompressed = 0;
	__block long long sizeUncompressed = 0;
	
	// creating queue and group for uncompression
	
	
	dispatch_async(_uncompressingQueue, ^{
		
		NSFileManager *fileManager = [[NSFileManager alloc] init];
		
		// iterate through all files
        for (DTZipArchiveNode *node in self->_listOfEntries)
		{
			if (self.isCancelling)
			{
				break;
			}
			
			// append uncompress blocks to file
			__block NSString *filePath = [targetPath stringByAppendingPathComponent:node.name];
			
			if (node.isDirectory)
			{
				if (![fileManager createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:&error])
				{
					error = [self _errorWithText:@"Cannot create folder for entry" code:8 underlyingError:error];
					
					break;
				}
			}
			else
			{
                if (unzOpenCurrentFile(self->_unzFile) != UNZ_OK)
				{
					error = [self _errorWithText:@"Unable to open zip file" code:5 underlyingError:nil];
					
					break;
				}
				
				// For files
				// increase number of files -> to calculate progress
				numberOfFilesUncompressed++;
				
				// create file handle
				NSURL *fileURL = [NSURL fileURLWithPath:filePath];
				NSFileHandle *_destinationFileHandle = [NSFileHandle fileHandleForWritingToURL:fileURL error:&error];
				
				if (!_destinationFileHandle)
				{
					error = nil;
					
					// if we have no file create it first
					if (![fileManager createFileAtPath:filePath contents:nil attributes:nil])
					{
						error = [self _errorWithText:@"Unzip file cannot be created" code:2 underlyingError:nil];
						
						break;
					}
					
					_destinationFileHandle = [NSFileHandle fileHandleForWritingToURL:fileURL error:&error];
					
					if (!_destinationFileHandle)
					{
						error = [self _errorWithText:@"Cannot create output file" code:7 underlyingError:error];
						
						break;
					}
				}
				
				int readBytes;
				unsigned char buffer[BUFFER_SIZE] = {0};
                while ((readBytes = unzReadCurrentFile(self->_unzFile, buffer, BUFFER_SIZE)) > 0)
				{
					if (self.isCancelling)
					{
						break;
					}
					
					NSData *fileData = [[NSData alloc] initWithBytes:buffer length:(uint) readBytes];
					
					if ([fileData length])
					{
						// append data to the file handle
						[_destinationFileHandle writeData:fileData];
					}
				}
				
				[_destinationFileHandle closeFile];
                unzCloseCurrentFile(self->_unzFile);
				
				// increase size of all files (uncompressed) -> to calculate progress
				sizeUncompressed += node.fileSize;

				// progress calc
                float sizeInPercentUncompressed = (float) sizeUncompressed / self->_totalSize;
                float itemsInPercentUncompressed = (float) numberOfItemsUncompressed / self->_totalNumberOfItems;
				float percent = MAX(sizeInPercentUncompressed, itemsInPercentUncompressed);
				
				// create progress notification
				dispatch_async(dispatch_get_main_queue(), ^{
					NSDictionary *userInfo = @{@"ProgressPercent" : [NSNumber numberWithFloat:percent],
                                               @"TotalNumberOfItems" : [NSNumber numberWithLongLong:self->_totalNumberOfItems],
														@"NumberOfItemsUncompressed" : [NSNumber numberWithLongLong:numberOfItemsUncompressed],
                                               @"TotalNumberOfFiles" : [NSNumber numberWithLongLong:self->_totalNumberOfFiles],
														@"NumberOfFilesUncompressed" : [NSNumber numberWithLongLong:numberOfFilesUncompressed],
                                               @"TotalSize" : [NSNumber numberWithLongLong:self->_totalSize],
														@"SizeUncompressed" : [NSNumber numberWithLongLong:sizeUncompressed]};
					
					[[NSNotificationCenter defaultCenter] postNotificationName:DTZipArchiveProgressNotification object:self userInfo:userInfo];
				});
			}
			
			// increase number of files -> to calculate progress
			numberOfItemsUncompressed++;
			
            unzGoToNextFile(self->_unzFile);
		} // end of entry loop
		
		if (completion && !self.cancelling)
		{
			completion(error);
		}
		
		self.cancelling = NO;
		self.uncompressing = NO;
	});
}

- (NSData *)uncompressZipArchiveNode:(DTZipArchiveNode *)node withError:(NSError **)error
{
	if (node.isDirectory)
	{
		if (error)
		{
			NSDictionary *userInfo = @{NSLocalizedDescriptionKey : @"Zip Archive node is a directory"};
			*error = [[NSError alloc] initWithDomain:DTZipArchiveErrorDomain code:6 userInfo:userInfo];
		}
		return nil;
	}
	
	if (unzLocateFile(_unzFile, [node.name UTF8String], 1) != UNZ_OK)
	{
		if (error)
		{
			NSDictionary *userInfo = @{NSLocalizedDescriptionKey : @"Given single file cannot be found to unzip"};
			*error = [[NSError alloc] initWithDomain:DTZipArchiveErrorDomain code:7 userInfo:userInfo];
		}
		return nil;
	}
	
	if (unzOpenCurrentFile(_unzFile) != UNZ_OK)
	{
		if (error)
		{
			NSDictionary *userInfo = @{NSLocalizedDescriptionKey : @"Unable to open zip file"};
			*error = [[NSError alloc] initWithDomain:DTZipArchiveErrorDomain code:5 userInfo:userInfo];
		}
		return nil;
	}
	
	int readBytes;
	unsigned char buffer[BUFFER_SIZE] = {0};
	NSMutableData *fileData = [[NSMutableData alloc] init];
	while ((readBytes = unzReadCurrentFile(_unzFile, buffer, BUFFER_SIZE)) > 0)
	{
		[fileData appendBytes:buffer length:(uint)readBytes];
	}
	
	unzCloseCurrentFile(_unzFile);
	return [fileData copy];
}

- (void)uncompressZipArchiveNode:(DTZipArchiveNode *)node toDataWithCompletion:(DTZipArchiveUncompressFileCompletionBlock)completion
{
	
	// creating queue and group for uncompression
	dispatch_queue_t uncompressingQueue = dispatch_queue_create("DTZipArchiveUncompressionQueue", DISPATCH_QUEUE_SERIAL);
	
	dispatch_async(uncompressingQueue, ^{
		
		NSError *error = nil;
		NSData *data = [self uncompressZipArchiveNode:node withError:&error];
		
		if (completion)
		{
			completion(data, error);
		}
	});
}

// adapted from: http://code.google.com/p/ziparchive
- (void)enumerateUncompressedFilesAsDataUsingBlock:(DTZipArchiveEnumerationResultsBlock)enumerationBlock
{
	unsigned char buffer[BUFFER_SIZE] = {0};
	
	// return if failed
	if (!_unzFile)
	{
		return;
	}
	
	// get file info
	unz_global_info  globalInfo = {0};
	
	if (unzGetGlobalInfo(_unzFile, &globalInfo )!=UNZ_OK )
	{
		// there's a problem
		return;
	}
	
	if (unzGoToFirstFile(_unzFile)!=UNZ_OK)
	{
		// unable to go to first file
		return;
	}
	
	// enum block can stop loop
	BOOL shouldStop = NO;
	
	// iterate through all files
	for (DTZipArchiveNode *node in _listOfEntries)
	{
		unz_file_info zipInfo ={0};
		
		if (unzOpenCurrentFile(_unzFile) != UNZ_OK)
		{
			// error uncompressing this file
			return;
		}
		
		// first call for file info so that we know length of file name
		if (unzGetCurrentFileInfo(_unzFile, &zipInfo, NULL, 0, NULL, 0, NULL, 0) != UNZ_OK)
		{
			// cannot get file info
			unzCloseCurrentFile(_unzFile);
			return;
		}
		
		if (node.isDirectory)
		{
			// call the enum block
			enumerationBlock(node.name, nil, &shouldStop);
		}
		else
		{
			
			NSMutableData *tmpData = [[NSMutableData alloc] init];
			
			NSInteger readBytes;
			while((readBytes = unzReadCurrentFile(_unzFile, buffer, BUFFER_SIZE)) > 0)
			{
				[tmpData appendBytes:buffer length:readBytes];
			}
			
			// call the enum block
			enumerationBlock(node.name, tmpData, &shouldStop);
		}
		
		// close the current file
		unzCloseCurrentFile(_unzFile);
		
		unzGoToNextFile(_unzFile);
		
		if (shouldStop)
		{
			return;
		}
	}
}

#pragma mark - Properties

@synthesize path = _path;

@end
