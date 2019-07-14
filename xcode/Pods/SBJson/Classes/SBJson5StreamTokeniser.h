//
// Created by SuperPappi on 09/01/2013.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import <Foundation/Foundation.h>

typedef enum {
    sbjson5_token_error = -1,
    sbjson5_token_eof,

    sbjson5_token_array_open,
    sbjson5_token_array_close,
    sbjson5_token_value_sep,

    sbjson5_token_object_open,
    sbjson5_token_object_close,
    sbjson5_token_entry_sep,

    sbjson5_token_bool,
    sbjson5_token_null,

    sbjson5_token_integer,
    sbjson5_token_real,

    sbjson5_token_string,
    sbjson5_token_encoded,
} sbjson5_token_t;


@interface SBJson5StreamTokeniser : NSObject

@property (nonatomic, readonly, copy) NSString *error;

- (void)appendData:(NSData*)data_;
- (sbjson5_token_t)getToken:(char**)tok length:(NSUInteger*)len;

@end

