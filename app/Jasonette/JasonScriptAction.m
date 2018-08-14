//
//  JasonScriptAction.m
//  Jasonette
//
//  Created by e on 8/28/17.
//  Copyright © 2017 Jasonette. All rights reserved.
//

#import "JasonScriptAction.h"

@implementation JasonScriptAction

// Construct a static JSContext
- (void) include {
    NSArray *scripts = self.options[@"items"];
    dispatch_group_t requireGroup = dispatch_group_create();

    JSContext *context = [[JSContext alloc] init];
    
    for(NSDictionary *script in scripts){
        dispatch_group_enter(requireGroup);
        
        if(script[@"url"]) {
            if([script[@"url"] containsString:@"file://"]){
                NSString *localFilename = [script[@"url"] substringFromIndex:7];
                NSString *filePath = [[NSBundle mainBundle] pathForResource:localFilename ofType:nil];
                NSData *data = [[NSFileManager defaultManager] contentsAtPath:filePath];
                NSString *js = [JasonHelper UTF8StringFromData:data];
                [self inject: js into: context];
                dispatch_group_leave(requireGroup);
            } else {
                AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
                AFHTTPResponseSerializer *serializer = [AFHTTPResponseSerializer serializer];
                NSMutableSet *contentTypes = [NSMutableSet setWithSet:serializer.acceptableContentTypes];
                [contentTypes addObject:@"text/plain"];
                [contentTypes addObject:@"application/javascript"];
                [contentTypes addObject:@"text/javascript"];
                serializer.acceptableContentTypes = contentTypes;
                manager.responseSerializer = serializer;
                
                [manager GET:script[@"url"] parameters: @{} progress:^(NSProgress * _Nonnull downloadProgress) { } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                    NSString *js = [JasonHelper UTF8StringFromData:((NSData *)responseObject)];
                    [self inject: js into: context];
                    dispatch_group_leave(requireGroup);
                } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                    NSLog(@"Error");
                    dispatch_group_leave(requireGroup);
                }];
                
            }
        } else if(script[@"text"]) {
            NSString *js = script[@"text"];
            [self inject: js into: context];
            dispatch_group_leave(requireGroup);
        }
    }

    dispatch_group_notify(requireGroup, dispatch_get_main_queue(), ^{
        [Jason client].jscontext = context;
        [[Jason client] success];
    });

}

- (void) inject: (NSString *) js into: (JSContext *)context{
    [context setExceptionHandler:^(JSContext *context, JSValue *value) {
        NSLog(@"%@", value);
    }];
    [context evaluateScript:js];
}


/**
 * Clean up context
 **/
- (void) clear {
    [Jason client].jscontext = nil;
    [[Jason client] success];
}

@end
