//
//  NSURL+DTAppLinks.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 11/25/11.
//  Copyright (c) 2011 Cocoanetics. All rights reserved.
//

#import "NSURL+DTAppLinks.h"

#if TARGET_OS_IPHONE

#import <UIKit/UIKit.h>

@implementation NSURL (DTAppLinks)

+ (NSURL *)appStoreURLforApplicationIdentifier:(NSString *)identifier
{
	NSString *link = [NSString stringWithFormat:@"http://itunes.apple.com/us/app/id%@?mt=8", identifier];
	
	return [NSURL URLWithString:link];
}

+ (NSURL *)appStoreReviewURLForApplicationIdentifier:(NSString *)identifier
{
	NSString *link = [NSString stringWithFormat:@"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=%@", identifier];
	return [NSURL URLWithString:link];
}

@end

#endif
