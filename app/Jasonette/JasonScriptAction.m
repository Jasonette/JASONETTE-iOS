//
//  JasonScriptAction.m
//  Jasonette
//
//  Created by e on 8/28/17.
//  Copyright © 2017 Jasonette. All rights reserved.
//

#import "JasonScriptAction.h"

static JSContext *context;
@implementation JasonScriptAction

+ (JSContext *) get {
    return context;
}

// Construct a static JSContext
- (void) include {
    NSArray *scripts = self.options[@"items"];
    NSMutableDictionary *return_value = [[NSMutableDictionary alloc] init];
    dispatch_group_t requireGroup = dispatch_group_create();

    context = [[JSContext alloc] init];
    
    for(NSDictionary *script in scripts){
        dispatch_group_enter(requireGroup);
        
        if(script[@"url"]) {
            if([script[@"url"] containsString:@"file://"]){
//                // local
//                return_value[url] = [JasonHelper read_local_json:url];
//                dispatch_group_leave(requireGroup);
                
            } else {
                AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
                AFHTTPResponseSerializer *serializer = [AFHTTPResponseSerializer serializer];
                NSMutableSet *contentTypes = [NSMutableSet setWithSet:serializer.acceptableContentTypes];
                [contentTypes addObject:@"text/plain"];
                [contentTypes addObject:@"application/javascript"];
                [contentTypes addObject:@"text/javascript"];
                serializer.acceptableContentTypes = jsonAcceptableContentTypes;
                manager.responseSerializer = serializer;
                
                [manager GET:url parameters: @{} progress:^(NSProgress * _Nonnull downloadProgress) { } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                    NSString *js = [JasonHelper UTF8StringFromData:((NSData *)responseObject)];
                    [self inject: js];
                    dispatch_group_leave(requireGroup);
                } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                    NSLog(@"Error");
                    dispatch_group_leave(requireGroup);
                }];
                
            }
        } else if(script[@"text"]) {
            
        }
    }

    dispatch_group_notify(requireGroup, dispatch_get_main_queue(), ^{
        [[Jason client] success];
    });

}

- (void) inject: (NSString *) js {
    [context setExceptionHandler:^(JSContext *context, JSValue *value) {
        NSLog(@"%@", value);
    }];
    [context evaluateScript:js];
}


/**
 * Clean up context
 **/
- (void) clean {
    context = nil;
}

@end
