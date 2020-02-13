//
//  NBPhoneNumberFormat.h
//  libPhoneNumber
//
//

#import <Foundation/Foundation.h>

@interface NBNumberFormat : NSObject

// from phonemetadata.pb.js
/* 1 */ @property(nonatomic, strong) NSString *pattern;
/* 2 */ @property(nonatomic, strong) NSString *format;
/* 3 */ @property(nonatomic, strong) NSArray *leadingDigitsPatterns;
/* 4 */ @property(nonatomic, strong) NSString *nationalPrefixFormattingRule;
/* 6 */ @property(nonatomic, assign) BOOL nationalPrefixOptionalWhenFormatting;
/* 5 */ @property(nonatomic, strong) NSString *domesticCarrierCodeFormattingRule;

- (instancetype)initWithPattern:(NSString *)pattern
                               withFormat:(NSString *)format
                withLeadingDigitsPatterns:(NSArray *)leadingDigitsPatterns
         withNationalPrefixFormattingRule:(NSString *)nationalPrefixFormattingRule
                           whenFormatting:(BOOL)nationalPrefixOptionalWhenFormatting
    withDomesticCarrierCodeFormattingRule:(NSString *)domesticCarrierCodeFormattingRule;
- (instancetype)initWithEntry:(NSArray *)entry;

@end
