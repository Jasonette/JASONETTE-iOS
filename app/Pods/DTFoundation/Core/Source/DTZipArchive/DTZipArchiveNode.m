//
//  DTZipArchiveNode.m
//  DTFoundation
//
//  Created by Stefan Gugarel on 23.01.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DTZipArchiveNode.h"

@implementation DTZipArchiveNode
{
    NSString *_name;

    NSUInteger _fileSize;

    BOOL _directory;
}

#ifndef COVERAGE
- (NSString *)description
{
    if (self.isDirectory)
    {
        return [NSString stringWithFormat:@"<%@ name='%@' directory='YES'>", NSStringFromClass([self class]), self.name];
    }
    else
    {
        return [NSString stringWithFormat:@"<%@ name='%@'>", NSStringFromClass([self class]), self.name];
    }
}
#endif

#pragma mark - Properties

@synthesize name = _name;
@synthesize fileSize = _fileSize;
@synthesize directory = _directory;

- (NSMutableArray *)children
{
	if (!_children)
	{
		_children = [[NSMutableArray alloc] init];
	}

	return _children;
}

@end