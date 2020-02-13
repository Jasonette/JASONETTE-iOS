//
//  NBRegExMatcher.h
//  libPhoneNumber
//
//  Created by Paween Itthipalkul on 11/29/17.
//  Copyright © 2017 Google LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NBPhoneNumberDesc;

@interface NBRegExMatcher : NSObject

/**
 Returns whether the given national number (a string containing only decimal digits) matches
 the national number pattern defined in the given {@code PhoneNumberDesc} message.

 @param string National number string ot match.
 @param numberDesc Phone number description.
 @param allowsPrefixMatch Whether to allow prefix match or not.
 @return Whether the given national number matches the pattern.
 */
- (BOOL)matchNationalNumber:(NSString *)string
            phoneNumberDesc:(NBPhoneNumberDesc *)numberDesc
          allowsPrefixMatch:(BOOL)allowsPrefixMatch;

@end
