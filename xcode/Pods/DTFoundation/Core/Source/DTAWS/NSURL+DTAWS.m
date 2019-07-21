//
//  NSURL+DTAWS.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 7/14/13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "NSURL+DTAWS.h"
#import "NSString+DTURLEncoding.h"
#import "DTBase64Coding.h"
#import <CommonCrypto/CommonCrypto.h>

@implementation NSURL (DTAWS)

+ (NSURL *)amazonWebServicesURLWithHost:(NSString *)host parameters:(NSDictionary *)parameters secretKey:(NSString *)secretKey
{
	NSString *verb = @"GET";
	NSString *path = @"/onca/xml";
	
	// add time stamp
	NSDateFormatter *UTCFormatter = [[NSDateFormatter alloc] init];
	UTCFormatter.dateFormat = @"yyMMddHHmmss'Z'";
	UTCFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
	
	NSString *timeStamp = [UTCFormatter stringFromDate:[NSDate date]];
	
	NSMutableDictionary *tmpParams = [parameters mutableCopy];
	[tmpParams setObject:timeStamp forKey:@"Timestamp"];
	
	NSMutableString *paramString = [NSMutableString string];
	
	NSArray *sortedKeys = [[tmpParams allKeys] sortedArrayUsingSelector:@selector(compare:)];
	
	[sortedKeys enumerateObjectsUsingBlock:^(NSString *oneKey, NSUInteger idx, BOOL *stop) {
		
		if (idx)
		{
			[paramString appendString:@"&"];
		}
		
		[paramString appendString:oneKey];
		[paramString appendString:@"="];
		
		NSString *value = [tmpParams objectForKey:oneKey];
		[paramString appendString:[value stringByURLEncoding]];
	}];
	
	// create canonical string for signing
	
	NSMutableString *canonicalString = [NSMutableString string];
	
	[canonicalString appendString:verb];
	[canonicalString appendString:@"\n"];
	[canonicalString appendString:host];
	[canonicalString appendString:@"\n"];
	[canonicalString appendString:path];
	[canonicalString appendString:@"\n"];
	
	[canonicalString appendString:paramString];
	
	// create HMAC with SHA256
	const char *cKey  = [secretKey cStringUsingEncoding:NSUTF8StringEncoding];
	const char *cData = [canonicalString cStringUsingEncoding:NSUTF8StringEncoding];
	unsigned char cHMAC[CC_SHA256_DIGEST_LENGTH];
	CCHmac(kCCHmacAlgSHA256, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
	
	NSData *hashData = [NSData dataWithBytes:cHMAC length:CC_SHA256_DIGEST_LENGTH];
	NSString *signature = [[DTBase64Coding stringByEncodingData:hashData] stringByURLEncoding];
	
	// create URL String
	NSMutableString *urlString = [NSMutableString string];
	
	[urlString appendString:@"http://"];
	[urlString appendString:host];
	[urlString appendString:path];
	[urlString appendString:@"?"];
	[urlString appendString:paramString];
	
	[urlString appendFormat:@"&Signature=%@", signature];
	
	return [NSURL URLWithString:urlString];
}

@end
