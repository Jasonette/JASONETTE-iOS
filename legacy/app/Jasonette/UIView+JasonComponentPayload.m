//
//  UIView+Extension.m
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import "UIView+JasonComponentPayload.h"

@implementation UIView (JasonComponentPayload)
-(void)setPayload:(id)payload
{
    objc_setAssociatedObject( self, "_payload", payload, OBJC_ASSOCIATION_RETAIN_NONATOMIC ) ;
}

-(id)payload
{
    return objc_getAssociatedObject( self, "_payload" ) ;
}

@end
