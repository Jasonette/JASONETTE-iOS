//
//  JasonValidations.m
//  Jasonette
//
//  Created by Camilo Castro on 17-08-17.
//  Copyright © 2017 Jasonette. All rights reserved.
//

#import "JasonValidations.h"

@implementation JasonValidations

+ (BOOL) isString:(nullable id) value
{
  return value && [value isKindOfClass:[NSString class]];
}

@end
