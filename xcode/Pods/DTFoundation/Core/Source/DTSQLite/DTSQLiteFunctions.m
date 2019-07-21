//
//  DTSQLiteFunctions.m
//  TravelSpeak
//
//  Created by Oliver Drobnik on 5/22/13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DTSQLiteFunctions.h"
#import "DTLog.h"

#pragma mark - Database Helpers

void DTSQLiteEnumerateSQLStatementColumns(sqlite3_stmt *statement, DTSQLiteEnumerateSQLStatementColumnsBlock block)
{
	NSUInteger numCols = sqlite3_column_count(statement);
	
	for (int i=0; i<numCols; i++)
	{
		NSString *columnName = [NSString stringWithUTF8String:sqlite3_column_name(statement, i)];
		
		int columnType = sqlite3_column_type(statement, i);
		id value = nil;
		
		switch (columnType)
		{
			case SQLITE_TEXT:
			{
				char *cStr = (char *)sqlite3_column_text(statement, i);
				
				value = [NSString stringWithUTF8String:cStr];
				
				break;
			}
				
			case SQLITE_INTEGER:
			{
				NSUInteger v = sqlite3_column_int(statement, i);
				value = [NSNumber numberWithUnsignedInteger:v];
				
				break;
			}
				
			case SQLITE_FLOAT:
			{
				double v = sqlite3_column_double(statement, i);
				value = [NSNumber numberWithUnsignedInteger:v];
				
				break;
			}
				
				
			default:
			{
				DTLogError(@"Type %d not implemented", columnType);
				break;
			}
		}
		
		block(columnName, value);
	}
}