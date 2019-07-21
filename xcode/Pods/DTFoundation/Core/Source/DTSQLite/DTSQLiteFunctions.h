//
//  DTSQLiteFunctions.h
//  TravelSpeak
//
//  Created by Oliver Drobnik on 5/22/13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import <sqlite3.h>

// block to be executed for each column in TSPEnumerateSQLStatementColumns
typedef void (^DTSQLiteEnumerateSQLStatementColumnsBlock)(NSString *columnName, id value);

/**
 Enumerates the columns in a SQLite3 statement
 */
void DTSQLiteEnumerateSQLStatementColumns(sqlite3_stmt *statement, DTSQLiteEnumerateSQLStatementColumnsBlock block);