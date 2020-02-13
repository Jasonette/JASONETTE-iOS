//
//  UIApplication+DTNetworkActivity.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 5/21/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

/**
 Enhancement for `UIApplication` to properly count active network sessions and show the network activity indicator whenever there are more than 0 active sessions.
 */
@interface UIApplication (DTNetworkActivity)

/**
 Increments the number of active network operations
 */
- (void)pushActiveNetworkOperation;

/**
 Decrements the number of active network operations
 */
- (void)popActiveNetworkOperation;

@end
