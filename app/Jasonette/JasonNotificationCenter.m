//
//  JasonNotificationCenter.m
//  Jasonette
//
//  Created by Camilo Castro on 17-08-17.
//  Copyright © 2017 Jasonette. All rights reserved.
//

#import "JasonNotificationCenter.h"
#import "JasonNotification.h"

@implementation JasonNotificationCenter


+ (void) postNotificationWithName: (nonnull NSString *) name
{
  [[NSNotificationCenter defaultCenter]
   postNotificationName:name
   object:self];
}

+ (void) postNotificationWithName: (nonnull NSString *) name
                       andMessage:(nonnull NSString *) message
{
  [[NSNotificationCenter defaultCenter]
   postNotificationName:name
   object:self
   userInfo:@{@"message" : message}];
}

+ (void) postNotificationWithName: (nonnull NSString *) name
                          message:(nonnull NSString *) message
                        andData: (nullable id) data
{
  if(!data)
  {
    data = @"Null";
  }
  
  [[NSNotificationCenter defaultCenter]
   postNotificationName:name
   object:self
   userInfo:@{@"message" : message, @"data" : data}];
}

+ (void) postNotification: (nonnull JasonNotification *) notification
{

  [[NSNotificationCenter defaultCenter]
   postNotificationName:notification.name
   object:self
   userInfo:@{@"message" : notification.message,
              @"data" : notification.data,
              @"notification" : notification}];
}

@end
