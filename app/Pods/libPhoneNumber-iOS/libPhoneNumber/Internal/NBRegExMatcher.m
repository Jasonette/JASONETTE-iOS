//
//  NBRegExMatcher.m
//  libPhoneNumber
//
//  Created by Paween Itthipalkul on 11/29/17.
//  Copyright © 2017 Google LLC. All rights reserved.
//

#import "NBRegExMatcher.h"
#import "NBPhoneNumberDesc.h"
#import "NBRegularExpressionCache.h"
#import "NBPhoneNumberUtil.h"

// Expose this method to get a modified RegEx to cover the entire RegEx.
// Though all RegEx methods and functionalities should be moved to either this class, or a separate
// class rather than in NBPhoneNumberUtil.
@interface NBPhoneNumberUtil()
- (NSRegularExpression *)entireRegularExpressionWithPattern:(NSString *)regexPattern
                                                    options:(NSRegularExpressionOptions)options
                                                      error:(NSError **)error;

@end

@implementation NBRegExMatcher

- (BOOL)matchNationalNumber:(NSString *)string
            phoneNumberDesc:(NBPhoneNumberDesc *)numberDesc
          allowsPrefixMatch:(BOOL)allowsPrefixMatch {
  NSString *nationalNumberPattern = numberDesc.nationalNumberPattern;

  // We don't want to consider it a prefix match when matching non-empty input against an empty
  // pattern.
  if (nationalNumberPattern.length == 0) {
    return NO;
  }

  NSRegularExpression *regEx =
      [[NBPhoneNumberUtil sharedInstance] entireRegularExpressionWithPattern:nationalNumberPattern
                                                                     options:kNilOptions
                                                                       error:nil];

  if (regEx == nil) {
    NSAssert(true, @"Regular expression shouldn't be nil");
    return NO;
  }

  NSRange wholeStringRange = NSMakeRange(0, string.length);

  // Prefix match (lookingAt()) search
  NSRegularExpression *prefixRegEx =
    [[NBRegularExpressionCache sharedInstance] regularExpressionForPattern:nationalNumberPattern
                                                                     error:NULL];
  if (prefixRegEx == nil) {
    NSAssert(true, @"Regular expression shouldn't be nil");
    return NO;
  }

  NSTextCheckingResult *prefixResult = [prefixRegEx firstMatchInString:string
                                                               options:NSMatchingAnchored
                                                                 range:wholeStringRange];
  if (prefixResult.numberOfRanges <= 0) {
    // No prefix match found.
    return NO;
  } else {
    // Found prefix match, but need to see if exact match works as well.
    // Exact match (matches()) search.
    NSTextCheckingResult *exactResult = [regEx firstMatchInString:string
                                                     options:NSMatchingAnchored
                                                       range:wholeStringRange];

    return (allowsPrefixMatch || exactResult.numberOfRanges > 0);
  }
}

@end
