
//
//  JasonNetworkAction.m
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import "JasonNetworkAction.h"

@implementation JasonNetworkAction
- (void)storeSession:(NSDictionary *)session forDomain:(NSString*)domain{
    UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:[domain lowercaseString]];
    keychain[@"session"] = [session description];
}
- (void)saveCookies{
    
    NSData *cookiesData = [NSKeyedArchiver archivedDataWithRootObject: [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject: cookiesData forKey: @"sessionCookies"];
    [defaults synchronize];
    
}

- (void)loadCookies{
    
    NSArray *cookies = [NSKeyedUnarchiver unarchiveObjectWithData: [[NSUserDefaults standardUserDefaults] objectForKey: @"sessionCookies"]];
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    
    for (NSHTTPCookie *cookie in cookies){
        [cookieStorage setCookie: cookie];
    }
    
}

- (void)request{
    __weak typeof(self) weakSelf = self;

    NSString *original_url = self.VC.url;
    
    if(self.options){
        [[Jason client] networkLoading:YES with:self.options];
        AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
        NSString *url = self.options[@"url"];
        // Instantiate with session if needed
        NSDictionary *session = [JasonHelper sessionForUrl:url];
        
        // Check for valid URL and throw error if invalid
        if(![url isEqualToString:@""]) {
            NSURL *urlToCheck = [NSURL URLWithString:url];
            if(!urlToCheck){
                NSLog(@"Error = Invalid URL for $network.request call");
                [[Jason client] networkLoading:NO with:nil];
                [[Jason client] error: nil];
                return;
            }
        } else {
            NSLog(@"Error = URL not specified for $network.request call");
            [[Jason client] networkLoading:NO with:nil];
            [[Jason client] error: nil];
            return;
        }
        
        // Set Header if specified  "header"
        NSDictionary *headers = self.options[@"header"];
        // legacy code : headers is deprecated
        if(!headers){
            headers = self.options[@"headers"];
        }
        
        
        // setting content_type
        NSString *contentType = self.options[@"contentType"]; // contentType is deprecated. Use content_type
        if(!contentType){
            contentType = self.options[@"content_type"];
        }
        
        if(contentType){
            if([contentType isEqualToString:@"json"]){
                manager.requestSerializer = [AFJSONRequestSerializer serializer];
            }
        }
        
        
        if(headers && headers.count > 0){
            for(NSString *key in headers){
                [manager.requestSerializer setValue:headers[key] forHTTPHeaderField:key];
            }
        }
        if(session && session.count > 0 && session[@"header"]){
            for(NSString *key in session[@"header"]){
                [manager.requestSerializer setValue:session[@"header"][key] forHTTPHeaderField:key];
            }
        }
        NSString *dataType = self.options[@"dataType"];     // dataType is deprecated. Use data_type
        if(!dataType){
            dataType = self.options[@"data_type"];
        }
        if(dataType && [dataType isEqualToString:@"html"]){
            manager.responseSerializer = [AFHTTPResponseSerializer serializer];
            manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/html", @"text/plain", nil];
        } else if(dataType && ([dataType isEqualToString:@"xml"] || [dataType isEqualToString:@"rss"])){
            AFHTTPResponseSerializer *serializer = [AFHTTPResponseSerializer serializer];
            NSMutableSet *acceptableContentTypes = [NSMutableSet setWithSet:serializer.acceptableContentTypes];
            [acceptableContentTypes addObject:@"application/rss+xml"];
            [acceptableContentTypes addObject:@"application/text+xml"];
            [acceptableContentTypes addObject:@"text/xml"];
            [acceptableContentTypes addObject:@"application/xml"];
            [acceptableContentTypes addObject:@"application/soap+xml"];
            [acceptableContentTypes addObject:@"application/atom+xml"];
            [acceptableContentTypes addObject:@"application/atomcat+xml"];
            [acceptableContentTypes addObject:@"application/atomsvc+xml"];
            serializer.acceptableContentTypes = acceptableContentTypes;
            manager.responseSerializer = serializer;

        } else if(dataType && [dataType isEqualToString:@"raw"]){
            manager.responseSerializer = [AFHTTPResponseSerializer serializer];
            manager.responseSerializer.acceptableContentTypes = nil;
        } else {
            JASONResponseSerializer *jsonResponseSerializer = [JASONResponseSerializer serializer];
            NSMutableSet *jsonAcceptableContentTypes = [NSMutableSet setWithSet:jsonResponseSerializer.acceptableContentTypes];
            [jsonAcceptableContentTypes addObject:@"text/plain"];
            jsonResponseSerializer.acceptableContentTypes = jsonAcceptableContentTypes;
            manager.responseSerializer = jsonResponseSerializer;
        }
        
    
        // Set params if specified  ("data")
        NSMutableDictionary *parameters;
        if(self.options[@"data"]){
            parameters = [self.options[@"data"] mutableCopy];
        } else {
            if(session && session.count > 0 && session[@"body"]){
                parameters = [@{} mutableCopy];
                for(NSString *key in session[@"body"]){
                    parameters[key] = session[@"body"][key];
                }
            } else {
                parameters = nil;
            }
        }
        
        NSString *method = self.options[@"method"];
        if(dataType && ([dataType isEqualToString:@"html"] || [dataType isEqualToString:@"xml"] || [dataType isEqualToString:@"rss"])){
            [self loadCookies];
        }
        
        
        // don't use cached result if fresh is true
        NSString *fresh = self.options[@"fresh"];
        if(fresh){
            [manager.requestSerializer setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
        }
        
        
        if(method){
            if([[method lowercaseString] isEqualToString:@"post"]){
                //dispatch_async(dispatch_queue_create("clientQueue", NULL) , ^{
                dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                    [manager.operationQueue cancelAllOperations];
                    [manager POST:url parameters:parameters progress:^(NSProgress * _Nonnull uploadProgress) {
                        // Nothing
                    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                        // Ignore if the url is different
                        if(![JasonHelper isURL:task.originalRequest.URL equivalentTo:url]) return;
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if(dataType && ([dataType isEqualToString:@"html"] || [dataType isEqualToString:@"xml"] || [dataType isEqualToString:@"rss"])){
                                [self saveCookies];
                                NSString *data = [JasonHelper UTF8StringFromData:((NSData *)responseObject)];
                                data = [[data componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] componentsJoinedByString:@" "];
                                [[Jason client] success: data withOriginalUrl:original_url];
                            } else if(dataType && [dataType isEqualToString:@"raw"]){
                                [self saveCookies];
                                NSString *data = [JasonHelper UTF8StringFromData:((NSData *)responseObject)];
                                [[Jason client] success: data withOriginalUrl:original_url];
                            } else {
                                [[Jason client] success: responseObject withOriginalUrl:original_url];
                            }
                        });
                    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                        [weakSelf processError: error withOriginalUrl:original_url];
                    }];
                });
                return;
            } else if([[method lowercaseString] isEqualToString:@"put"]){
                dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                    [manager.operationQueue cancelAllOperations];
                    [manager PUT:url parameters:parameters success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
                        // Ignore if the url is different
                        if(![JasonHelper isURL:task.originalRequest.URL equivalentTo:url]) return;
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if(dataType && ([dataType isEqualToString:@"html"] || [dataType isEqualToString:@"xml"] || [dataType isEqualToString:@"rss"])){
                                [self saveCookies];
                                NSString *data = [JasonHelper UTF8StringFromData:((NSData *)responseObject)];
                                data = [[data componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] componentsJoinedByString:@" "];
                                [[Jason client] success: data withOriginalUrl:original_url];
                                
                            } else if(dataType && [dataType isEqualToString:@"raw"]){
                                [self saveCookies];
                                NSString *data = [JasonHelper UTF8StringFromData:((NSData *)responseObject)];
                                [[Jason client] success: data withOriginalUrl:original_url];
                            } else {
                                [[Jason client] success: responseObject withOriginalUrl:original_url];
                            }
                        });
                    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                        [weakSelf processError: error withOriginalUrl:original_url];
                    }];
                });
                return;
            } else if([[method lowercaseString] isEqualToString:@"delete"]){
                dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                    [manager.operationQueue cancelAllOperations];
                    [manager DELETE:url parameters:parameters success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
                        // Ignore if the url is different
                        if(![JasonHelper isURL:task.originalRequest.URL equivalentTo:url]) return;
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if(dataType && ([dataType isEqualToString:@"html"] || [dataType isEqualToString:@"xml"] || [dataType isEqualToString:@"rss"])){
                                [self saveCookies];
                                NSString *data = [JasonHelper UTF8StringFromData:((NSData *)responseObject)];
                                data = [[data componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] componentsJoinedByString:@" "];
                                [[Jason client] success: data withOriginalUrl:original_url];
                                
                            } else if(dataType && [dataType isEqualToString:@"raw"]){
                                [self saveCookies];
                                NSString *data = [JasonHelper UTF8StringFromData:((NSData *)responseObject)];
                                [[Jason client] success: data withOriginalUrl:original_url];
                            } else {
                                [[Jason client] success: responseObject withOriginalUrl:original_url];
                            }
                        });
                    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                        [weakSelf processError: error withOriginalUrl:original_url];
                    }];
                });
                return;
            }
        }
        
        
        // GET:
        // If you've reached this part, it means we're left with
        // the default option : GET
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
            [manager.operationQueue cancelAllOperations];
            [manager GET:url parameters:parameters progress:^(NSProgress * _Nonnull downloadProgress) {
                // Nothing
            } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                // Ignore if the url is different
                if(![JasonHelper isURL:task.originalRequest.URL equivalentTo:url]) return;
                dispatch_async(dispatch_get_main_queue(), ^{
                    if(dataType && ([dataType isEqualToString:@"html"] || [dataType isEqualToString:@"xml"] || [dataType isEqualToString:@"rss"])){
                        [self saveCookies];
                        NSString *data = [JasonHelper UTF8StringFromData:((NSData *)responseObject)];
                        data = [[data componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] componentsJoinedByString:@" "];
                        [[Jason client] success: data withOriginalUrl:original_url];
                        
                    } else if(dataType && [dataType isEqualToString:@"raw"]){
                        [self saveCookies];
                        NSString *data = [JasonHelper UTF8StringFromData:((NSData *)responseObject)];
                        [[Jason client] success: data withOriginalUrl:original_url];
                    } else {
                        [[Jason client] success: responseObject withOriginalUrl:original_url];
                    }
                });
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf processError: error withOriginalUrl:original_url];
                });
            }];
        });
    }
}
- (void)processError: (NSError *)error withOriginalUrl: (NSString*) original_url{
    NSLog(@"Error = %@", error);
    [[Jason client] networkLoading:NO with:nil];
    [[Jason client] error: error.userInfo withOriginalUrl:original_url];
}


// UPLOAD TO S3
- (void)upload{
    NSString *original_url = self.VC.url;
    if(self.options){
        NSString *contentType = self.options[@"Content-Type"];      //Content-Type is deprecated. Use content_type
        if(!contentType){
            contentType = self.options[@"content_type"];
        }
        
        
        __weak typeof(self) weakSelf = self;
        [[Jason client] loading:YES];
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            
            NSData *mediaData;
            NSString *guid = [[NSUUID new] UUIDString];
            if(contentType){
                // Custom Media Type exists,
                // Which means it's been transformed by another module
                // such as vidgif
                mediaData = [[NSData alloc] initWithBase64EncodedString:self.options[@"data"] options:0];
                NSArray *tokens = [contentType componentsSeparatedByString:@"/"];
                if(tokens && tokens.count > 1){
                    NSString *extension = [tokens lastObject];
                    NSString *upload_filename = [NSString stringWithFormat:@"%@.%@", guid, extension];
                    NSString *tmpFile = [NSTemporaryDirectory() stringByAppendingPathComponent:upload_filename];
                    
                    NSError *error;
                    Boolean success = [mediaData writeToFile:tmpFile options:0 error:&error];
                    if (!success) {
                        NSLog(@"writeToFile failed with error %@", error);
                    }
                    [weakSelf _uploadData: mediaData ofType: contentType withFilename: upload_filename fromOriginalUrl: original_url];
                }
            }
        });
    }
}
- (void)_uploadData:(NSData *)mediaData ofType: (NSString *)contentType withFilename: upload_filename fromOriginalUrl: original_url{
    
    NSDictionary *storage = self.options;
    NSString *bucket = storage[@"bucket"];
    NSString *path = storage[@"path"];
    NSString *sign_url = storage[@"sign_url"];
    
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSDictionary *session = [JasonHelper sessionForUrl:sign_url];
    
    // Set Header if specified  ("headers"
    NSDictionary *headers = self.options[@"headers"];
    if(headers && headers.count > 0){
        for(NSString *key in headers){
            [manager.requestSerializer setValue:headers[key] forHTTPHeaderField:key];
        }
    }
    if(session && session.count > 0 && session[@"header"]){
        for(NSString *key in session[@"header"]){
            [manager.requestSerializer setValue:session[@"header"][key] forHTTPHeaderField:key];
        }
    }
    
    
    NSString *file_path;
    if(path && path.length > 0){
        file_path = [NSString stringWithFormat:@"%@/%@", path, upload_filename];
    } else {
        file_path = upload_filename;
    }
    NSMutableDictionary *parameters = [@{@"bucket": bucket,
                                        @"path": file_path,
                                         @"content-type": contentType} mutableCopy];
    if(session && session.count > 0 && session[@"body"]){
        for(NSString *key in session[@"body"]){
            parameters[key] = session[@"body"][key];
        }
    }
    
    [manager.operationQueue cancelAllOperations];
    [manager GET:sign_url parameters:parameters progress:^(NSProgress * _Nonnull downloadProgress) {
        // Nothing
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        // Ignore if the url is different
        if(![JasonHelper isURL:task.originalRequest.URL equivalentTo:sign_url]) return;
        if(!responseObject[@"$jason"]){
            [[Jason client] error:@{@"description": @"The server must return a signed url wrapped with '$jason' key"} withOriginalUrl:original_url];
            return;
        }
        
        NSMutableURLRequest *req = [[NSMutableURLRequest alloc] init];
        [req setAllHTTPHeaderFields:@{@"Content-Type": contentType}];
        [req setHTTPBody:mediaData]; // the key is here
        [req setHTTPMethod:@"PUT"];
        [req setURL:[NSURL URLWithString:responseObject[@"$jason"]]];
        
        NSURLSessionDataTask *upload_task = [manager dataTaskWithRequest:req completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
            if (!error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self s3UploadDidSucceed: upload_filename withOriginalUrl: original_url];
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSLog(@"error = %@", error);
                    [self s3UploadDidFail: error withOriginalUrl:original_url];
                });
            }
        }];
        [upload_task resume];

    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self s3UploadDidFail:error withOriginalUrl: original_url];
    }];
}
- (void)s3UploadDidFail: (NSError *)error withOriginalUrl: (NSString*)original_url
{
    [[Jason client] loading:NO];
    [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"Error"
                                               description:@"There was an error sending the image. Please try again."
                                                      type:TWMessageBarMessageTypeError];
    [[Jason client] error: error.userInfo withOriginalUrl:original_url];
}
- (void)s3UploadDidSucceed: (NSString *)upload_filename withOriginalUrl: original_url{
    [[Jason client] loading:NO];
    [[Jason client] success: @{@"filename": upload_filename, @"file_name": upload_filename} withOriginalUrl:original_url];
}

@end
