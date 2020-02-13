//
//  NSObject+JSONPayload.h
//  Jasonette
//
//  Created by e on 7/28/17.
//  Copyright © 2017 Jasonette. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@interface NSObject (JSONPayload)

@property ( nonatomic, strong ) NSMutableDictionary* payload;

@end
