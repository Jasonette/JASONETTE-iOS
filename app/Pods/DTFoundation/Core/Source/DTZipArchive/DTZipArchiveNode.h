//
//  DTZipArchiveNode.h
//  DTFoundation
//
//  Created by Stefan Gugarel on 23.01.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

/**
 Represents a node in a DTZipArchive, i.e. a folder or a file. Holds important values for files or directories to uncompress.
 */
@interface DTZipArchiveNode : NSObject

/**
 @name Getting Information about Zip Archive Nodes
 */

/**
 File or directory name
 */
@property (nonatomic, copy) NSString *name;

/**
 Size of file in bytes
 Directories will have size 0
 */
@property (nonatomic, assign) NSUInteger fileSize;

/**
 Specifies if we have a directory or folder
 */
@property (nonatomic, assign, getter=isDirectory) BOOL directory;

/**
 Child nodes of node, of class DTZipArchiveNode
 */
@property (nonatomic, strong) NSMutableArray *children;

@end