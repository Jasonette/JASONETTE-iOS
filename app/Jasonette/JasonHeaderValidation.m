//
//  JasonHeaderValidation.m
//  Jasonette
//
//  Created by Camilo Castro on 17-08-17.
//  Copyright © 2017 Jasonette. All rights reserved.
//

#import "JasonHeaderValidation.h"

#import "JasonValidations.h"
#import "JasonNotificationWarnings.h"

@implementation JasonHeaderValidation



+ (nonnull NSDictionary *) validHeaders: (nullable NSDictionary *) headers
{
  
  NSMutableDictionary * validHeaders = [@{} mutableCopy];
  
  if(headers)
  {
    for (NSString * key in headers)
    {
      id value = headers[key];
      if(![JasonValidations isString:value])
      {
        [JasonNotificationWarnings
         triggerWrongHeaderFormatWarningWithKey:key andValue:value];
      }
      else
      {
        [validHeaders setObject:value forKey:key];
      }
    }
  }
  
  return [validHeaders copy];
}
@end
