//
//  DTZipArchive.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 12.02.12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//


@class DTZipArchiveNode;

/**
 Buffer size when unzipping in blocks
 */
#define BUFFER_SIZE 4096

/** This is how the enumeration block needs to look like. Setting *stop to YES will stop the enumeration.
 */
typedef void (^DTZipArchiveEnumerationResultsBlock)(NSString *fileName, NSData *data, BOOL *stop);


/**
 Completion block for uncompressToPath:withCompletion:
 */
typedef void (^DTZipArchiveUncompressionCompletionBlock)(NSError *error);

/**
 Completion block when uncompressing a single file
 */
typedef void (^DTZipArchiveUncompressFileCompletionBlock)(NSData *data, NSError *error);


/**
 Notification for the progress of the uncompressing process
 */
extern NSString * const DTZipArchiveProgressNotification;

/**
* Error domain for NSErrors
*/
extern NSString * const DTZipArchiveErrorDomain;


/** This class represents a compressed file in GZIP or PKZIP format. The used format is auto-detected. 
 
 Dependencies: minizip (in Core/Source/Externals), libz.dylib
 */

@interface DTZipArchive : NSObject
{
	NSArray *_listOfEntries;
}

/**
 @name Getting Information about Archives
 */

/**
 Path of zip file
*/
@property (nonatomic, copy, readonly) NSString *path;

/**-------------------------------------------------------------------------------------
 @name Creating A Zip Archive
 ---------------------------------------------------------------------------------------
 */

/** Creates an instance of DTZipArchive in preparation for enumerating its contents.
 
 Uses the [minizip](http://www.winimage.com/zLibDll/minizip.html) wrapper for zlib to deal with PKZip-format files.
 
 @param path A Path to a compressed file
 @returns An instance of DTZipArchive or `nil` if an error occured
 */
+ (DTZipArchive *)archiveAtPath:(NSString *)path;

/** Enumerates through the files contained in the archive.
 
 If stop is set to `YES` in the enumeration block then the enumeration stops. Note that this parameter is ignored for GZip files since those only contain a single file.
 
 @param enumerationBlock An enumeration block that gets executed for each found and decompressed file
 */
- (void)enumerateUncompressedFilesAsDataUsingBlock:(DTZipArchiveEnumerationResultsBlock)enumerationBlock;

/**
  The nodes at the root level of the archive. Each node is a DTZipArchiveNode and can represent either a folder or a file. This forms the directory hierarchy of the archive.
 */
@property (nonatomic, readonly) NSArray *nodes;

@end


/**
 @name Uncompressing Methods
 */
@interface DTZipArchive(Uncompressing)

/**
 Uncompresses the receiver to a given path overwriting existing files. Can be cancelled by calling -cancelAllUncompressing. For a cancelled operation the completion block will not be called.

 @param targetPath path where the zip archive is being uncompressed
 @param completion block that executes when uncompressing is finished. Error is `nil` if successful.
 */
- (void)uncompressToPath:(NSString *)targetPath completion:(DTZipArchiveUncompressionCompletionBlock)completion;

/**
 Cancels an uncompressing operation started by uncompressToPath:completion:.
 */
- (void)cancelAllUncompressing;

/**
 Synchronous uncompressing the receiver and returning file as NSData
 
 @param node path where the zip archive is being uncompressed
 @param error the error returned when something went wrong
 @return data of uncompressed file. If nil error has occured.
 */
- (NSData *)uncompressZipArchiveNode:(DTZipArchiveNode *)node withError:(NSError **)error;

/**
 Asynchronous uncompressing of single file with completion block

 @param node from the listOfEntries property of DTZipArchiveNodes
 @param completion block that is called when the unzipping of this file is done
 */
- (void)uncompressZipArchiveNode:(DTZipArchiveNode *)node toDataWithCompletion:(DTZipArchiveUncompressFileCompletionBlock)completion;

@end
