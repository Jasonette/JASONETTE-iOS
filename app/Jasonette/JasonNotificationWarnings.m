//
//  JasonNotificationWarnings.m
//  Jasonette
//
//  Created by Camilo Castro on 17-08-17.
//  Copyright © 2017 Jasonette. All rights reserved.
//

#import "JasonNotificationWarnings.h"

@implementation JasonNotificationWarnings

+ (void) triggerWrongHeaderFormatWarningWithKey: (nonnull NSString *) key andValue: (nullable id) value
{
  JasonNotificationWrongHeaderFormat * notification =
    [[JasonNotificationWrongHeaderFormat alloc] initWithKey:key andValue:value];
  
  [notification trigger];
}
@end
