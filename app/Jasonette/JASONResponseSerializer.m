//
//  JASONResponseSerializer.m
//  Jasonette
//
//  Created by e on 7/12/17.
//  Copyright © 2017 Jasonette. All rights reserved.
//

#import "JASONResponseSerializer.h"

@implementation JASONResponseSerializer
- (id)responseObjectForResponse:(NSURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing *)errorPointer
{
    id responseObject = [super responseObjectForResponse:response data:data error:errorPointer];
    if (*errorPointer) {
        NSError *error = *errorPointer;
        NSMutableDictionary *userInfo = [error.userInfo mutableCopy];
        userInfo[@"responseObject"] = responseObject;
        *errorPointer = [NSError errorWithDomain:error.domain code:error.code userInfo:[userInfo copy]];
    }
    return responseObject;
}

@end
