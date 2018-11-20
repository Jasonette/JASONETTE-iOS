/* Copyright 2017 Urban Airship and Contributors */

#import "UASQLite+Internal.h"
#import "UAGlobal.h"

#import <sqlite3.h>

@interface UASQLite ()
@property(nonatomic, assign) sqlite3 *db;
@end


@implementation UASQLite

- (instancetype)init {
    self = [super init];
    if (self) {
        self.busyRetryTimeout = 1;
        self.dbPath = nil;
        self.db = nil;
    }

    return self;
}

- (instancetype)initWithDBPath:(NSString *)aDBPath {
    self = [super init];
    if (self) {
        [self open:aDBPath];
    }

    return self;
}

- (void)dealloc {
    [self close];

}

- (BOOL)open:(NSString *)aDBPath {
    [self close];

    if (sqlite3_open([aDBPath fileSystemRepresentation], &_db) != SQLITE_OK) {
        UA_LDEBUG(@"SQLite Opening Error: %s", sqlite3_errmsg(self.db));
        return NO;
    }

    self.dbPath = aDBPath;
    return YES;
}

- (void)close {
    if (self.db == nil) return;

    int numOfRetries = 0;
    int rc;

    while (1) {
        rc = sqlite3_close(self.db);
        if (rc == SQLITE_OK) {
            self.dbPath = nil;
            self.db = nil;
            break;
        }

        if (rc == SQLITE_BUSY) {
            if (numOfRetries++ >= self.busyRetryTimeout) {
                UA_LDEBUG(@"SQLite Busy, unable to close: %@", self.dbPath);
                break;
            }
            [NSThread sleepForTimeInterval:0.02];
        } else {
            UA_LDEBUG(@"SQLite %@ Closing Error: %s", self.dbPath, sqlite3_errmsg(self.db));
            break;
        }
    }
}

- (NSString*) lastErrorMessage {
    return [NSString stringWithFormat:@"%s", sqlite3_errmsg(self.db)];
}

- (NSInteger) lastErrorCode {
    return sqlite3_errcode(self.db);
}

- (BOOL)prepareSql:(NSString *)sql inStatament:(sqlite3_stmt **)stmt {
    int numOfRetries = 0;
    int rc;

    while (1) {
        rc = sqlite3_prepare_v2(self.db, [sql UTF8String], -1, stmt, NULL);
        if (rc == SQLITE_OK)
            return YES;

        if (rc == SQLITE_BUSY) {
            if (numOfRetries++ >= self.busyRetryTimeout) {
                UA_LDEBUG(@"SQLite Busy: %@", self.dbPath);
                break;
            }
            [NSThread sleepForTimeInterval:0.02];
        } else {
            UA_LDEBUG(@"SQLite Prepare Failed: %s", sqlite3_errmsg(self.db));
            UA_LDEBUG(@" - Query: %@", sql);
            break;
        }
    }

    return NO;
}

- (BOOL)executeStatament:(sqlite3_stmt *)stmt {
    int numOfRetries = 0;
    int rc;

    while (1) {
        rc = sqlite3_step(stmt);
        if (rc == SQLITE_OK || rc == SQLITE_DONE)
            return YES;

        if (rc == SQLITE_BUSY) {
            if (numOfRetries++ >= self.busyRetryTimeout) {
                UA_LDEBUG(@"SQLite Busy: %@", self.dbPath);
                break;
            }
            [NSThread sleepForTimeInterval:0.02];
        } else {
            UA_LDEBUG(@"SQLite Step Failed: %s", sqlite3_errmsg(self.db));
            break;
        }
    }

    return NO;
}

- (void)bindObject:(id)obj toColumn:(int)idx inStatament:(sqlite3_stmt *)stmt {
    if (obj == nil || obj == [NSNull null]) {
        sqlite3_bind_null(stmt, idx);
    } else if ([obj isKindOfClass:[NSData class]]) {
        sqlite3_bind_blob(stmt, idx, [obj bytes], (int)[obj length], SQLITE_STATIC);
    } else if ([obj isKindOfClass:[NSDate class]]) {
        sqlite3_bind_double(stmt, idx, [obj timeIntervalSince1970]);
    } else if ([obj isKindOfClass:[NSNumber class]]) {
        if (!strcmp([obj objCType], @encode(BOOL))) {
            sqlite3_bind_int(stmt, idx, [obj boolValue] ? 1 : 0);
        } else if (!strcmp([obj objCType], @encode(int))) {
            sqlite3_bind_int64(stmt, idx, [obj longValue]);
        } else if (!strcmp([obj objCType], @encode(long))) {
            sqlite3_bind_int64(stmt, idx, [obj longValue]);
        } else if (!strcmp([obj objCType], @encode(float))) {
            sqlite3_bind_double(stmt, idx, [obj floatValue]);
        } else if (!strcmp([obj objCType], @encode(double))) {
            sqlite3_bind_double(stmt, idx, [obj doubleValue]);
        } else {
            sqlite3_bind_text(stmt, idx, [[obj description] UTF8String], -1, SQLITE_STATIC);
        }
    } else {
        sqlite3_bind_text(stmt, idx, [[obj description] UTF8String], -1, SQLITE_STATIC);
    }
}

- (BOOL)hasNext:(sqlite3_stmt *)stmt {
    int numOfRetries = 0;
    int rc;

    while (1) {
        rc = sqlite3_step(stmt);
        if (rc == SQLITE_ROW)
            return YES;

        if (rc == SQLITE_DONE)
            break;

        if (rc == SQLITE_BUSY) {
            if (numOfRetries++ >= self.busyRetryTimeout) {
                UA_LDEBUG(@"SQLite Busy: %@", self.dbPath);
                break;
            }
            [NSThread sleepForTimeInterval:0.02];
        } else {
            UA_LDEBUG(@"SQLite Prepare Failed: %s", sqlite3_errmsg(self.db));
            break;
        }
    }

    return NO;
}

- (id)columnData:(sqlite3_stmt *)stmt columnIndex:(NSInteger)index {
    int columnType = sqlite3_column_type(stmt, (int)index);

    if (columnType == SQLITE_NULL)
        return([NSNull null]);

    if (columnType == SQLITE_INTEGER)
        return [NSNumber numberWithInt:sqlite3_column_int(stmt, (int)index)];

    if (columnType == SQLITE_FLOAT)
        return [NSNumber numberWithDouble:sqlite3_column_double(stmt, (int)index)];

    if (columnType == SQLITE_TEXT) {
        const unsigned char *text = sqlite3_column_text(stmt, (int)index);
        return [NSString stringWithFormat:@"%s", text];
    }

    if (columnType == SQLITE_BLOB) {
        int nbytes = sqlite3_column_bytes(stmt, (int)index);
        const char *bytes = sqlite3_column_blob(stmt, (int)index);
        return [NSData dataWithBytes:bytes length:(NSUInteger)nbytes];
    }

    return nil;
}

- (NSString *)columnName:(sqlite3_stmt *)stmt columnIndex:(NSInteger)index {
    return [NSString stringWithUTF8String:sqlite3_column_name(stmt, (int)index)];
}

- (NSArray *)executeQuery:(NSString *)sql, ... {
    va_list args;
    va_start(args, sql);

    NSMutableArray *argsArray = [[NSMutableArray alloc] init];
    NSUInteger i;
    for (i = 0; i < [sql length]; ++i) {
        if ([sql characterAtIndex:i] == '?')
            [argsArray addObject:va_arg(args, id)];
    }

    va_end(args);

    NSArray *result = [self executeQuery:sql arguments:argsArray];

    return result;
}

- (NSArray*)convertResultSet:(sqlite3_stmt*)sqlStmt {
    NSMutableArray *arrayList = [[NSMutableArray alloc] init];
    int columnCount = sqlite3_column_count(sqlStmt);
    while ([self hasNext:sqlStmt]) {
        NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
        for (int i = 0; i < columnCount; ++i) {
            id columnName = [self columnName:sqlStmt columnIndex:i];
            id columnData = [self columnData:sqlStmt columnIndex:i];
            [dictionary setObject:columnData forKey:columnName];
        }
        [arrayList addObject:dictionary];
    }
    return arrayList;
}

- (NSArray *)executeQuery:(NSString *)sql arguments:(NSArray *)args {
    sqlite3_stmt *sqlStmt;

    if (![self prepareSql:sql inStatament:(&sqlStmt)])
        return nil;

    int i = 1;
    int queryParamCount = sqlite3_bind_parameter_count(sqlStmt);
    for (; i<=queryParamCount; i++)
        [self bindObject:[args objectAtIndex:(NSUInteger)(i - 1)] toColumn:i inStatament:sqlStmt];

    NSArray *result = [self convertResultSet:sqlStmt];
    sqlite3_finalize(sqlStmt);

    return result;
}

- (BOOL)executeUpdate:(NSString *)sql, ... {
    va_list args;
    va_start(args, sql);

    NSMutableArray *argsArray = [[NSMutableArray alloc] init];
    NSUInteger i;
    for (i = 0; i < [sql length]; ++i) {
        if ([sql characterAtIndex:i] == '?') {
            id arg = va_arg(args, id);
            if (!arg) {
                UA_LDEBUG(@"Update failed. Attempted to insert a nil value into DB.");
                // clean up before bailing
                return NO;
            }
            [argsArray addObject:arg];
        }
    }

    va_end(args);

    BOOL success = [self executeUpdate:sql arguments:argsArray];

    return success;
}

- (BOOL)executeUpdate:(NSString *)sql arguments:(NSArray *)args {
    sqlite3_stmt *sqlStmt;

    if (![self prepareSql:sql inStatament:(&sqlStmt)])
        return NO;

    int i = 1;
    int queryParamCount = sqlite3_bind_parameter_count(sqlStmt);
    for (; i<=queryParamCount; i++)
        [self bindObject:[args objectAtIndex:(NSUInteger)(i - 1)] toColumn:i inStatament:sqlStmt];

    BOOL success = [self executeStatament:sqlStmt];

    sqlite3_finalize(sqlStmt);
    return success;
}

- (BOOL)commit {
    return [self executeUpdate:@"COMMIT TRANSACTION;"];
}

- (BOOL)rollback {
    return [self executeUpdate:@"ROLLBACK TRANSACTION;"];
}

- (BOOL)beginTransaction {
    return [self executeUpdate:@"BEGIN EXCLUSIVE TRANSACTION;"];
}

- (BOOL)beginDeferredTransaction {
    return [self executeUpdate:@"BEGIN DEFERRED TRANSACTION;"];
}

- (BOOL)tableExists:(NSString*)tableName {
    tableName = [tableName lowercaseString];
    NSArray *result = [self executeQuery:@"select [sql] from sqlite_master where [type] = 'table' and lower(name) = ?", tableName];
    return result.count > 0;
}

- (BOOL)indexExists:(NSString*)indexName {
    indexName = [indexName lowercaseString];
    NSArray *result = [self executeQuery:@"select [sql] from sqlite_master where [type] = 'index' and lower(name) = ?", indexName];
    return result.count > 0;
}

@end
