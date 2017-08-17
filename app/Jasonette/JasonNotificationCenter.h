//
//  JasonNotificationCenter.h
//  Jasonette
//
//  Created by Camilo Castro on 17-08-17.
//  Copyright © 2017 Jasonette. All rights reserved.
//

#import <Foundation/Foundation.h>

@class JasonNotification;

@interface JasonNotificationCenter : NSObject

+ (void) postNotificationWithName: (nonnull NSString *) name;

+ (void) postNotificationWithName: (nonnull NSString *) name andMessage:(nonnull NSString *) message;

+ (void) postNotificationWithName: (nonnull NSString *) name message:(nonnull NSString *) message andData: (nullable id) data;

+ (void) postNotification: (nonnull JasonNotification *) notification;

@end
