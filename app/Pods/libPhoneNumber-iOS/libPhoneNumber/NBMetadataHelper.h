//
//  NBMetadataHelper.h
//  libPhoneNumber
//
//  Created by tabby on 2015. 2. 8..
//  Copyright (c) 2015년 ohtalk.me. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NBPhoneNumberDefines.h"

@class NBPhoneMetaData;

@interface NBMetadataHelper : NSObject

+ (BOOL)hasValue:(NSString *)string;

+ (NSDictionary *)CCode2CNMap;

- (NSArray *)getAllMetadata;

- (NBPhoneMetaData *)getMetadataForNonGeographicalRegion:(NSNumber *)countryCallingCode;
- (NBPhoneMetaData *)getMetadataForRegion:(NSString *)regionCode;

+ (NSArray *)regionCodeFromCountryCode:(NSNumber *)countryCodeNumber;
+ (NSString *)countryCodeFromRegionCode:(NSString *)regionCode;

#if SHORT_NUMBER_SUPPORT

/**
 * Returns the short number metadata for the given region code or {@code nil} if the region
 * code is invalid or unknown.
 *
 * @param regionCode regionCode
 * @return {i18n.phonenumbers.PhoneMetadata}
 */
- (NBPhoneMetaData *)shortNumberMetadataForRegion:(NSString *)regionCode;

#endif // SHORT_NUMBER_SUPPORT

@end
