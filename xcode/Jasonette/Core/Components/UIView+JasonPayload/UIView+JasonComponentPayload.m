//
//  UIView+Extension.m
//  Jasonette
//
//  Copyright © 2016 gliechtenstein.
//  Copyright © 2019 Jasonelle Team.
//
#import "UIView+JasonComponentPayload.h"

@implementation UIView (JasonComponentPayload)

- (void)setPayload:(id)payload
{
    // Create a new property named _payload inside the view object
    objc_setAssociatedObject (self, "_payload", payload, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id)payload
{
    return objc_getAssociatedObject (self, "_payload");
}

@end
