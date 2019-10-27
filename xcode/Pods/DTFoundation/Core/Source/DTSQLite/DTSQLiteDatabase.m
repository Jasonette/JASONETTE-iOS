//
//  DTSQLiteDatabase.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 5/22/13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DTSQLiteDatabase.h"
#import "DTSQLiteFunctions.h"
#import "DTLog.h"

@implementation DTSQLiteDatabase
{
	sqlite3 *_database;
	NSOperationQueue *_queue;
	
	BOOL _isCancelling;
}

- (id)initWithFileAtPath:(NSString *)path
{
	self = [super init];
	
	if (self)
	{
		if (sqlite3_open([path UTF8String], &_database) != SQLITE_OK)
		{
			sqlite3_close(_database);
			
			return nil;
		}
		
		_queue = [[NSOperationQueue alloc] init];
		[_queue setName:@"DTSQLiteDatabase Queue"];
		[_queue setMaxConcurrentOperationCount:1];
	}
	
	return self;
}

- (void)dealloc
{
	if (_database)
	{
		sqlite3_close(_database);
		_database = nil;
	}
}

- (NSError *)_currentErrorForDatabase
{
	NSDictionary *userInfo = @{NSLocalizedDescriptionKey:[NSString stringWithUTF8String:sqlite3_errmsg(_database)]};
	return [NSError errorWithDomain:NSStringFromClass([self class]) code:sqlite3_errcode(_database) userInfo:userInfo];
}


- (void)cancelAllQueries
{
	
	[_queue setSuspended:YES];
	
	for (NSOperation *op in _queue.operations)
	{
		[op cancel];
	}

	_isCancelling = YES;

	sqlite3_interrupt(_database);
	
	[self performBlock:^{
		// set cancelling back after queue was cleared out
		self->_isCancelling = NO;
	}];
	
	[_queue setSuspended:NO];
}

#pragma mark - Queries

- (NSArray *)fetchRowsForQuery:(NSString *)query error:(NSError **)error
{
	sqlite3_stmt *statement = NULL;
	
	NSMutableArray *tmpArray = [NSMutableArray array];
	
	if (sqlite3_prepare_v2(_database, [query UTF8String], -1, &statement, NULL) != SQLITE_OK)
	{
		if (error)
		{
			*error = [self _currentErrorForDatabase];
		}
		
		return nil;
	}
	
	while (sqlite3_step(statement) == SQLITE_ROW)
	{
		NSMutableDictionary *tmpDictionary = [NSMutableDictionary dictionary];
		
		DTSQLiteEnumerateSQLStatementColumns(statement, ^(NSString *columnName, id value) {
			tmpDictionary[columnName] = value;
		});
		
		[tmpArray addObject:tmpDictionary];
	}
	
	sqlite3_finalize(statement);
	
	if (!_isCancelling)
	{
		return [tmpArray copy];
	}
	
	DTLogError(@"ignored result");
	
	return nil;
}

#pragma mark - Block Operations

- (void)performBlock:(void (^)(void))block
{
	[_queue addOperationWithBlock:block];
}

- (void)performBlockAndWait:(void (^)(void))block
{
	[_queue addOperationWithBlock:block];
	[_queue waitUntilAllOperationsAreFinished];
}

#pragma mark - Properties


@end
