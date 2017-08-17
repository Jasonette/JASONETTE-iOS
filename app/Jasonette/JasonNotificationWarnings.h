//
//  JasonNotificationWarnings.h
//  Jasonette
//
//  Created by Camilo Castro on 17-08-17.
//  Copyright © 2017 Jasonette. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JasonNotificationWrongHeaderFormat.h"

@interface JasonNotificationWarnings : NSObject

+ (void) triggerWrongHeaderFormatWarningWithKey: (nonnull NSString *) key andValue: (nullable id) value;

@end
