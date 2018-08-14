//
//  NSObject+JSONPayload.m
//  Jasonette
//
//  Created by e on 7/28/17.
//  Copyright © 2017 Jasonette. All rights reserved.
//

#import "NSObject+JSONPayload.h"

@implementation NSObject (JSONPayload)
-(void)setPayload:(id)payload
{
    objc_setAssociatedObject( self, "_payload", payload, OBJC_ASSOCIATION_RETAIN_NONATOMIC ) ;
}

-(id)payload
{
    return objc_getAssociatedObject( self, "_payload" ) ;
}

@end
