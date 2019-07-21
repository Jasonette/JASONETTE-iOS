//
//  NSURL+DTAWS.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 7/14/13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

/**
 Category on `NSURL` for constructing a signed request URL for Amazon's [Product Advertising API](http://docs.aws.amazon.com/AWSECommerceService/latest/DG/Welcome.html)
 */
@interface NSURL (DTAWS)

/**
 Creates a signed `NSURL` to query Amazon's Product Advertising API.
 
 Typical host names are:
 
 -	ecs.amazonaws.de for German
 - webservices.amazon.com for US

 The secret key is a parameter. The access key is passed in the parameters dictionary.
 @param host The domain name for the Amazon host to query
 @param parameters The request parameters
 @param secretKey The secret key
 @returns The prepared and signed `NSURL`
 */
+ (NSURL *)amazonWebServicesURLWithHost:(NSString *)host parameters:(NSDictionary *)parameters secretKey:(NSString *)secretKey;

@end
