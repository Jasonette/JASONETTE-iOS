//
//  JasonOauthAction.m
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import "JasonOauthAction.h"
#import <TDOAuth/TDOAuth.h>
#import <Accounts/Accounts.h>
#import <Social/Social.h>

@implementation JasonOauthAction
- (void)performSocialFrameworkRequestFor: (ACAccount *)account{
    
    NSString *path = self.options[@"path"];
    NSString *host = self.options[@"host"];
    NSString *scheme = self.options[@"scheme"];
    NSString *method = self.options[@"method"];
    if(!method) method = @"get";
    
    NSString *accname;
    if([host containsString:@"twitter"]){
            accname = @"twitter";
    } else if([host containsString:@"facebook"]){
            accname = @"facebook";
        
    } else if([host containsString:@"sina"]){
            accname = @"sina";
        
    } else if([host containsString:@"qq"]){
            accname = @"tencent";
    }
    
    NSDictionary *serviceMapping = @{@"twitter": SLServiceTypeTwitter, @"facebook": SLServiceTypeFacebook, @"sina": SLServiceTypeSinaWeibo, @"tencent": SLServiceTypeTencentWeibo};
    NSDictionary *methodMapping = @{@"get": @(SLRequestMethodGET), @"post": @(SLRequestMethodPOST), @"put": @(SLRequestMethodPUT), @"delete": @(SLRequestMethodDELETE)};
    NSDictionary *params= self.options[@"data"];
   
    // preprocess to make sure host and path merge regardless of whether theres's a slash or not
    if([host hasSuffix:@"/"]){
        if([path hasPrefix:@"/"]){
            path = [path substringFromIndex:1];
        } else {
            path = path;
        }
    } else {
        if([path hasPrefix:@"/"]){
            path = path;
        } else {
            path = [NSString stringWithFormat:@"/%@", path];
        }
    }
    
     NSString *urlString = [NSString stringWithFormat:@"%@://%@%@", scheme, host, path];
     NSURL *requestURL = [NSURL URLWithString: urlString];
     
     SLRequest *request = [SLRequest requestForServiceType:serviceMapping[accname] requestMethod:[methodMapping[method] integerValue] URL:requestURL parameters:params];
     
     request.account = account;
     [request performRequestWithHandler: ^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        // Ignore if the url is different
        if(![[[request.preparedURLRequest URL] absoluteString] isEqualToString:urlResponse.URL.absoluteString]) return;
         if(error){
             [[Jason client] error];
         } else {
             NSDictionary *result = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableLeaves error:&error];
             [[Jason client] success: result];
         }
      }];


}
- (void)request{
    NSString *host = self.options[@"host"];
    NSString *client_id = self.options[@"client_id"];
    if(self.options[@"version"] && [self.options[@"version"] isEqualToString:@"0"]){
        ACAccountStore *account = [[ACAccountStore alloc] init];
        NSDictionary *accountMapping = @{@"twitter": ACAccountTypeIdentifierTwitter, @"facebook": ACAccountTypeIdentifierFacebook, @"sina": ACAccountTypeIdentifierSinaWeibo, @"tencent": ACAccountTypeIdentifierTencentWeibo};
        NSString *accname;
        if([host containsString:@"twitter"]){
                accname = @"twitter";
        } else if([host containsString:@"facebook"]){
                accname = @"facebook";
            
        } else if([host containsString:@"sina"]){
                accname = @"sina";
            
        } else if([host containsString:@"qq"]){
                accname = @"tencent";
        }
        
        
        if([host containsString:@"twitter"] || [host containsString:@"facebook"] || [host containsString:@"sina"] || [host containsString:@"qq"]){
            
            
            NSString *method = self.options[@"method"];
            if(!method) method = @"get";
            
            ACAccountType *accountType = [account accountTypeWithAccountTypeIdentifier:accountMapping[accname]];
            NSDictionary *options = nil;
            
            
            if([host containsString:@"facebook"]){
                options = @{
                    ACFacebookAppIdKey: client_id,
                    //ACFacebookPermissionsKey: @[@"user_friends", @"email"],
                    ACFacebookAudienceKey: ACFacebookAudienceFriends
                };
            }
            
            // For socialframework with twitter, use the host as client_id
            if([host containsString:@"twitter"]){
                client_id = host;
            }
            
            
            // IF already signed in, just use the already stored account from keychain
            UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:@"$socialframework"];
            NSString *account_identifier = [keychain stringForKey:client_id];
            if(account_identifier && account_identifier.length > 0){
                ACAccount *a = [account accountWithIdentifier:account_identifier];
                 [self performSocialFrameworkRequestFor: a];
            } else {
                
                [account requestAccessToAccountsWithType:accountType options:options completion:^(BOOL granted, NSError *error) {
                     if (granted == YES) {
                         NSArray *arrayOfAccounts = [account accountsWithAccountType:accountType];
                         if ([arrayOfAccounts count] > 0) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                AHKActionSheet *actionSheet = [[AHKActionSheet alloc] initWithTitle:nil];
                                for(int i = 0 ; i < arrayOfAccounts.count ; i++){
                                    ACAccount *a = arrayOfAccounts[i];
                                    [actionSheet addButtonWithTitle:a.username type:AHKActionSheetButtonTypeDefault handler:^(AHKActionSheet *as) {
                                        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                                            UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:@"$socialframework"];
                                            [keychain setString:a.identifier forKey:client_id];
                                             [self performSocialFrameworkRequestFor: a];
                                        });
                                    }];
                                }
                                actionSheet.title = @"Select an account";
                                actionSheet.blurTintColor = [UIColor colorWithWhite:1.0f alpha:0.75f];
                                actionSheet.blurRadius = 8.0f;
                                actionSheet.buttonHeight = 45.0f;

                                actionSheet.animationDuration = 0.2f;
                                UIFont *defaultFont = [UIFont fontWithName:@"HelveticaNeue" size:16.0f];
                                actionSheet.buttonTextAttributes = @{ NSFontAttributeName : defaultFont,
                                                                      NSForegroundColorAttributeName : [UIColor blackColor] };
                                actionSheet.disabledButtonTextAttributes = @{ NSFontAttributeName : defaultFont,
                                                                              NSForegroundColorAttributeName : [UIColor grayColor] };
                                actionSheet.destructiveButtonTextAttributes = @{ NSFontAttributeName : defaultFont,
                                                                                 NSForegroundColorAttributeName : [UIColor redColor] };
                                actionSheet.cancelButtonTextAttributes = @{ NSFontAttributeName : defaultFont,
                                                                            NSForegroundColorAttributeName : [UIColor blackColor] };
                                [actionSheet show];
                                
                            });
                         } else {
                             [[Jason client] error];
                         }
                     } else {
                         [[Jason client] error];
                     }
                 }];
            }
        } else {
            [[Jason client] error];
        }
        
    } else if(self.options[@"version"] && [self.options[@"version"] isEqualToString:@"1"]){
        
        /*********************************************************
         * OAuth 1 flow
         *********************************************************/
        
        
        NSString *APP_NAME = [[NSBundle mainBundle] bundleIdentifier];
        
        UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:[NSString stringWithFormat:@"%@", APP_NAME]];
        NSString *token = [keychain stringForKey:[NSString stringWithFormat:@"%@#token", client_id]];
        if(token){
            dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                [self _process];
            });
        } else {
            [[Jason client] error];
        }
    } else {
        /*********************************************************
         * OAuth 2 flow
         *********************************************************/
        AFOAuthCredential *credential = [AFOAuthCredential retrieveCredentialWithIdentifier:client_id];
        
        if(credential){
            [self _process];
        } else {
            [[Jason client] error];
        }
    }
}
- (void)reset{
    /* 
     Signing out

     EXAMPLE:
     
    "action": {
        "type": "$oauth.reset",
        "options": {
            "version": "1",
            "client_id": "{{$keys.key}}"
        },
        "success": {
            "type": "$reload"
        }
    }
    */
    if(self.options){
        NSString *client_id = self.options[@"client_id"];
        if(self.options[@"version"] && [self.options[@"version"] isEqualToString:@"0"]){
            // For social framework, set the client_id: "#{host}"
            client_id = self.options[@"host"];
            UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:@"$socialframework"];
            [keychain removeItemForKey:client_id];
            [[Jason client] success];
        } else if(self.options[@"version"] && [self.options[@"version"] isEqualToString:@"1"]){
            
            NSString *APP_NAME = [[NSBundle mainBundle] bundleIdentifier];
            
            UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:[NSString stringWithFormat:@"%@", APP_NAME]];
            [keychain removeItemForKey:[NSString stringWithFormat:@"%@#token", client_id]];
            [keychain removeItemForKey:[NSString stringWithFormat:@"%@#secret", client_id]];
            [[Jason client] success];
        } else if(self.options[@"version"] && [self.options[@"version"] isEqualToString:@"2"]){
            
            [AFOAuthCredential deleteCredentialWithIdentifier:client_id];
            [[Jason client] success];
        } else {
            [AFOAuthCredential deleteCredentialWithIdentifier:client_id];
            [[Jason client] success];
            
        }
        return;
    }
    [[Jason client] error];
}
- (void)_process{
    NSString *client_id = self.options[@"client_id"];
    NSString *client_secret = self.options[@"client_secret"];
    NSString *path = self.options[@"path"];
    NSString *host = self.options[@"host"];
    NSString *scheme = self.options[@"scheme"];
    if(!scheme) scheme = @"https";
    NSString *method = self.options[@"method"];
    if(!method) method = @"get";
    NSDictionary *params= self.options[@"data"];
    NSDictionary *header = self.options[@"header"];
    if(self.options[@"version"] && [self.options[@"version"] isEqualToString:@"1"]){
        /*********************************************************
         * OAuth 1 flow
         *********************************************************/
        
        
        NSString *APP_NAME = [[NSBundle mainBundle] bundleIdentifier];
        
        UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:[NSString stringWithFormat:@"%@", APP_NAME]];
        NSString *access_token = [keychain stringForKey:[NSString stringWithFormat:@"%@#token", client_id]];
        NSString *access_secret = [keychain stringForKey:[NSString stringWithFormat:@"%@#secret", client_id]];
        
        NSMutableURLRequest *request ;
        request = [[TDOAuth URLRequestForPath:path
                               parameters:params
                                     host:host
                              consumerKey:client_id
                           consumerSecret:client_secret
                              accessToken:access_token
                              tokenSecret:access_secret
                                   scheme:scheme
                            requestMethod:method.uppercaseString
                             dataEncoding:TDOAuthContentTypeUrlEncodedForm
                             headerValues:nil
                          signatureMethod:TDOAuthSignatureMethodHmacSha1] mutableCopy];
        
        if(request){
            
            AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
            
            AFJSONResponseSerializer *jsonResponseSerializer = [AFJSONResponseSerializer serializer];
            NSMutableSet *jsonAcceptableContentTypes = [NSMutableSet setWithSet:jsonResponseSerializer.acceptableContentTypes];
            [jsonAcceptableContentTypes addObject:@"text/plain"];
            jsonResponseSerializer.acceptableContentTypes = jsonAcceptableContentTypes;
            [manager setResponseSerializer:jsonResponseSerializer];
            
            for(NSString *key in header){
                [request setValue:header[key] forHTTPHeaderField:key];
            }
            [[manager dataTaskWithRequest:request completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
                if(!error){
                    [[Jason client] success:responseObject];
                } else {
                    [[NSNotificationCenter defaultCenter] removeObserver:self];
                    [[Jason client] error];
                }
            }] resume];
            
        }
    } else {
        /*********************************************************
         * OAuth 2 flow
         *********************************************************/
        
        NSURL *baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@", scheme, host]];
        AFOAuthCredential *credential = [AFOAuthCredential retrieveCredentialWithIdentifier:client_id];

        AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithBaseURL:baseURL];
        
        manager.responseSerializer = [AFJSONResponseSerializer serializer];
        AFJSONResponseSerializer *jsonResponseSerializer = [AFJSONResponseSerializer serializer];
        NSMutableSet *jsonAcceptableContentTypes = [NSMutableSet setWithSet:jsonResponseSerializer.acceptableContentTypes];
        [jsonAcceptableContentTypes addObject:@"text/plain"];
        jsonResponseSerializer.acceptableContentTypes = jsonAcceptableContentTypes;
        manager.responseSerializer = jsonResponseSerializer;
        
        
        if(!params){
            params = @{};
        }
        NSMutableDictionary *parameters = [params mutableCopy];
        // whether to send the credentials over header or as a param(body)

        
        if([[parameters allValues] containsObject:@"{{$oauth.token}}"]){
            // auth token contained in body
            for(NSString *key in [parameters allKeys]){
                if([parameters[key] isEqualToString:@"{{$oauth.token}}"]){
                    parameters[key] = [credential accessToken];
                }
            }
        } else {
            // auth token sent as header
            [manager.requestSerializer setAuthorizationHeaderFieldWithCredential:credential];
            for(NSString *key in header){
                [manager.requestSerializer setValue:header[key] forHTTPHeaderField:key];
            }
        }
        
        
        if([method isEqualToString:@"get"]){
            [manager GET:path parameters:parameters progress:^(NSProgress * _Nonnull downloadProgress) {
                // Nothing
            } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                // Ignore if the url is different
                NSString *originalRequestPath = task.originalRequest.URL.path;
                
                // Make sure the request from the returning task is the same as the original request
                BOOL same = YES;
                if([originalRequestPath isEqualToString:path]){
                    if(task.originalRequest.URL.query && task.originalRequest.URL.query.length > 0){
                        NSArray *originalRequestQueries = [task.originalRequest.URL.query componentsSeparatedByString:@"&"];
                        for (NSString *kv in originalRequestQueries) {
                            NSArray *pairComponents = [kv componentsSeparatedByString:@"="];
                            NSString *key = [[pairComponents firstObject] stringByRemovingPercentEncoding];
                            NSString *value = [[pairComponents lastObject] stringByRemovingPercentEncoding];
                            
                            // check if the value is the same as the original
                            if(![parameters[key] isEqualToString:value]){
                                same = NO;
                                break;
                            }
                        }
                    }
                } else {
                    same = NO;
                }
                
                if(same){
                    [[Jason client] success: responseObject];
                }
                
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                   NSString* ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                   NSLog(@"#E = %@",ErrorResponse);
                 [[Jason client] error];
            }];
        } else if([method isEqualToString:@"post"]){
            [manager POST:path parameters:parameters progress:^(NSProgress * _Nonnull downloadProgress) {
                // Nothing
            } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                // Ignore if the url is different
                NSString *originalRequestPath = task.originalRequest.URL.path;
                NSString *originalRequestQuery = nil;
                if(task.originalRequest.URL.query && task.originalRequest.URL.query.length > 0){
                    originalRequestQuery = [task.originalRequest.URL.query stringByRemovingPercentEncoding];
                }
                NSString *originalRequestFullPath;
                if(originalRequestQuery){
                    originalRequestFullPath = [NSString stringWithFormat:@"%@?%@", originalRequestPath, originalRequestQuery];
                } else {
                    originalRequestFullPath = originalRequestPath;
                }
                if(![originalRequestFullPath isEqualToString:path]) return;
                
                 [[Jason client] success: responseObject];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                 [[Jason client] error];
            }];
        } else if([method isEqualToString:@"put"]){
            [manager PUT:path parameters:parameters success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                // Ignore if the url is different
                NSString *originalRequestPath = task.originalRequest.URL.path;
                NSString *originalRequestQuery = nil;
                if(task.originalRequest.URL.query && task.originalRequest.URL.query.length > 0){
                    originalRequestQuery = [task.originalRequest.URL.query stringByRemovingPercentEncoding];
                }
                NSString *originalRequestFullPath;
                if(originalRequestQuery){
                    originalRequestFullPath = [NSString stringWithFormat:@"%@?%@", originalRequestPath, originalRequestQuery];
                } else {
                    originalRequestFullPath = originalRequestPath;
                }
                if(![originalRequestFullPath isEqualToString:path]) return;
                
                [[Jason client] success: responseObject];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                 [[Jason client] error];
            }];
        } else if([method isEqualToString:@"head"]){
            [manager HEAD:path parameters:parameters success:^(NSURLSessionDataTask * _Nonnull task) {
                // Ignore if the url is different
                NSString *originalRequestPath = task.originalRequest.URL.path;
                NSString *originalRequestQuery = nil;
                if(task.originalRequest.URL.query && task.originalRequest.URL.query.length > 0){
                    originalRequestQuery = [task.originalRequest.URL.query stringByRemovingPercentEncoding];
                }
                NSString *originalRequestFullPath;
                if(originalRequestQuery){
                    originalRequestFullPath = [NSString stringWithFormat:@"%@?%@", originalRequestPath, originalRequestQuery];
                } else {
                    originalRequestFullPath = originalRequestPath;
                }
                if(![originalRequestFullPath isEqualToString:path]) return;
                
                [[Jason client] success];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                 [[Jason client] error];
            }];
        } else if([method isEqualToString:@"delete"]){
            [manager DELETE:path parameters:parameters success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                // Ignore if the url is different
                NSString *originalRequestPath = task.originalRequest.URL.path;
                NSString *originalRequestQuery = nil;
                if(task.originalRequest.URL.query && task.originalRequest.URL.query.length > 0){
                    originalRequestQuery = [task.originalRequest.URL.query stringByRemovingPercentEncoding];
                }
                NSString *originalRequestFullPath;
                if(originalRequestQuery){
                    originalRequestFullPath = [NSString stringWithFormat:@"%@?%@", originalRequestPath, originalRequestQuery];
                } else {
                    originalRequestFullPath = originalRequestPath;
                }
                if(![originalRequestFullPath isEqualToString:path]) return;
                
                [[Jason client] success: responseObject];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                 [[Jason client] error];
            }];
        } else {
            [[Jason client] error];
        }

    }
}

- (void)access_token{
    NSString *host = self.options[@"host"];
    if(self.options[@"version"] && [self.options[@"version"] isEqualToString:@"0"]){
        NSString *client_id = self.options[@"client_id"];
        ACAccountStore *accountStore = [[ACAccountStore alloc] init];
        
        ACAccountType *accountTypeFacebook = [accountStore accountTypeWithAccountTypeIdentifier: ACAccountTypeIdentifierFacebook];

        NSDictionary *options;
        if([host containsString:@"facebook"]){
            options = @{
                ACFacebookAppIdKey: client_id,
                //ACFacebookPermissionsKey: @[@"user_friends", @"email"],
                ACFacebookAudienceKey: ACFacebookAudienceFriends
            };
            [accountStore requestAccessToAccountsWithType:accountTypeFacebook options:options completion:^(BOOL granted, NSError *error) {
               if(granted) {
                    NSArray *accounts = [accountStore accountsWithAccountType:accountTypeFacebook];
                    ACAccount *account = [accounts lastObject];
                    [[Jason client] success: @{@"token": account.credential.oauthToken}];
               }
            }];
        }
    } else if(self.options[@"version"] && [self.options[@"version"] isEqualToString:@"1"]){
        /*********************************************************
         * OAuth 1 flow
         *********************************************************/
        NSString *client_id = self.options[@"access"][@"client_id"];
        
        NSString *APP_NAME = [[NSBundle mainBundle] bundleIdentifier];
        
        UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:[NSString stringWithFormat:@"%@", APP_NAME]];
        NSString *access_token = [keychain stringForKey:[NSString stringWithFormat:@"%@#token", client_id]];
        [[Jason client] success: @{@"token": access_token}];
    } else {
        /*********************************************************
         * OAuth 2 flow
         *********************************************************/
        NSString *client_id = self.options[@"access"][@"client_id"];
        AFOAuthCredential *credential = [AFOAuthCredential retrieveCredentialWithIdentifier:client_id];
        [[Jason client] success:@{@"token": [credential accessToken]}];
    }
}
- (void)refresh_token:(NSString*)provider{
    NSString *client_id = self.options[@"access"][@"client_id"];
    NSString *client_secret = self.options[@"access"][@"client_secret"];
     NSLog(@"Failed. Refreshing Token...");
    AFOAuthCredential *credential = [AFOAuthCredential retrieveCredentialWithIdentifier:provider];
    if(credential && credential.isExpired){
        NSDictionary *access_options = self.options[@"access"];
        NSString *urlString = [NSString stringWithFormat:@"%@://%@", access_options[@"scheme"],access_options[@"host"]];
        NSURL *baseURL = [NSURL URLWithString:urlString];
        AFOAuth2Manager *OAuth2Manager = [[AFOAuth2Manager alloc] initWithBaseURL:baseURL
                                        clientID:client_id
                                          secret:client_secret];
        [OAuth2Manager authenticateUsingOAuthWithURLString:access_options[@"path"] refreshToken:credential.refreshToken success:^(AFOAuthCredential *credential) {
            NSLog(@"Success! your new credential is %@", credential);
            [AFOAuthCredential storeCredential:credential withIdentifier:client_id];
            [[Jason client] success];
        } failure:^(NSError *error) {
           [[Jason client] error];
        }];
    }
}
- (void)auth{
    [Jason client].oauth_in_process = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(oauth_callback:) name:@"oauth_callback" object:nil];
    
    // Use access.oauth_consumer_key(oauth1)/access.client_id(oauth2) as current_provider
    
    if(self.options[@"version"] && [self.options[@"version"] isEqualToString:@"1"]){
        /*********************************************************
         * OAuth 1 flow
         *********************************************************/
       // Example options
        /*
         
         {
             "login": {
                 "type": "$oauth.auth",
                 "options": {
                     "version": "1",
                     "request": {
                         "client_id": "{{$keys.tumblr_key}}",
                         "client_secret": "{{$keys.tumblr_secret}}",
                         "scheme": "https",
                         "host": "www.tumblr.com",
                         "path": "/oauth/request_token",
                         "data": {
                             "oauth_callback": "jasonette://oauth"
                         }
                     },
                     "authorize": {
                         "scheme": "https",
                         "host": "www.tumblr.com",
                         "path": "/oauth/authorize"
                     },
                     "access": {
                         "scheme": "https",
                         "host": "www.tumblr.com",
                         "path": "/oauth/access_token"
                     }
                 },
                 "success": {
                     "trigger": "reload"
                 }
             },
         }
         */
        NSString *client_id = self.options[@"request"][@"client_id"];
        NSString *client_secret = self.options[@"request"][@"client_secret"];
        
        NSDictionary *request_options = self.options[@"request"];
        NSDictionary *authorize_options = self.options[@"authorize"];
        if(!request_options || request_options.count == 0){
            [[Jason client] error];
        } else {
            if(!request_options[@"scheme"] || [request_options[@"scheme"] length] == 0
               || !request_options[@"host"] || [request_options[@"host"] length] == 0
               || !request_options[@"path"] || [request_options[@"path"] length] == 0){
                [[Jason client] error];
            } else {
                NSDictionary *request_params = request_options[@"data"];
                if(!request_params || request_params.count == 0){
                    [[Jason client] error];
                } else {
                    NSMutableURLRequest *request = [[TDOAuth URLRequestForPath:request_options[@"path"]
                                POSTParameters:request_params
                                          host:request_options[@"host"]
                                   consumerKey:client_id
                                consumerSecret:client_secret
                                   accessToken:nil
                                   tokenSecret:nil] mutableCopy];
                    
                    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
                    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
                    manager.requestSerializer = [AFJSONRequestSerializer serializer];
                    
                    NSURLSessionDataTask *task = [manager dataTaskWithRequest:request completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
                        // Ignore if the url is different
                        if(![request.URL.absoluteString isEqualToString:response.URL.absoluteString]) return;
                        
                        if (!error) {
                            dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                                NSString* s= [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];

                                NSString *urlToParse = [NSString stringWithFormat:@"http://localhost?%@", s];
                                NSArray *queryItems = [self extractQueryParams:urlToParse];
                                NSString *oauth_token = [self valueForKey:@"oauth_token" fromQueryItems:queryItems];
                                NSString *oauth_token_secret = [self valueForKey:@"oauth_token_secret" fromQueryItems:queryItems];
                                NSString *authorize_url;
                                if(oauth_token_secret){
                                    self.cache = [@{@"oauth1_three_legged_secret": oauth_token_secret} mutableCopy];
                                    authorize_url = [NSString stringWithFormat:@"%@://%@%@?oauth_token=%@&oauth_token_secret=%@", authorize_options[@"scheme"], authorize_options[@"host"], authorize_options[@"path"], oauth_token, oauth_token_secret];
                                } else {
                                    self.cache = nil;
                                    authorize_url = [NSString stringWithFormat:@"%@://%@%@?oauth_token=%@", authorize_options[@"scheme"], authorize_options[@"host"], authorize_options[@"path"], oauth_token];
                                }
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    NSURL *URL = [NSURL URLWithString:authorize_url];
                                    NSString *view = authorize_options[@"view"];
                                    if(view && [view isEqualToString:@"app"]){
                                        // Launch external safari for oauth
                                        [[UIApplication sharedApplication] openURL:URL];
                                    } else {
                                        // By default use SFSafariViewController
                                        SFSafariViewController *vc = [[SFSafariViewController alloc] initWithURL:URL];
                                        vc.delegate = self;
                                        [self.VC presentViewController:vc animated:NO completion:^{ }];
                                    }
                                });
                            });
                        } else {
                            [[NSNotificationCenter defaultCenter] removeObserver:self];
                            [[Jason client] error];
                        }
                    }];
                    [task resume];

                }
            }
        }

        
        
        
    } else {
        /*********************************************************
         * OAuth 2 flow
         *********************************************************/
        // Example options
        /*
         "type": "$oauth.auth",
         "options": {
             "version": "2",
             "authorize": {
                 "client_id": "{{$keys.reddit_client_id}}",
                 "scheme": "https",
                 "host": "i.reddit.com",
                 "path": "/api/v1/authorize",
                 "data": {
                     "response_type": "code",
                     "redirect_uri": "jasonette://oauth",
                     "scope": "read,mysubreddits",
                     "state": "abcdefg",
                     "duration": "permanent"
                 }
             },
             "access": { ... }
         },...
         */
        
        
        
        NSString *view = self.options[@"authorize"][@"view"];
        
        // Check for grant_type : is it a password type or code type?
        
        NSDictionary *access_options = self.options[@"access"];
        if([access_options[@"data"][@"grant_type"] isEqualToString:@"password"]){
            /********************************************************************************
            *
            * Case 1: Password type
            *
            ********************************************************************************/
            NSString *client_id = self.options[@"access"][@"client_id"];
            NSString *client_secret = self.options[@"access"][@"client_secret"];
            
            NSDictionary *access_options = self.options[@"access"];
            if(!access_options || access_options.count == 0){
                [[Jason client] error];
            } else {
                if(!access_options[@"scheme"] || [access_options[@"scheme"] length] == 0
                   || !access_options[@"host"] || [access_options[@"host"] length] == 0
                   || !access_options[@"path"] || [access_options[@"path"] length] == 0){
                    [[Jason client] error];
                } else {
                    // Setup access params
                    NSDictionary *access_data;
                    
                    if(access_options[@"data"]){
                        access_data = access_options[@"data"];
                    }
                    NSString *baseUrl = [NSString stringWithFormat:@"%@://%@", access_options[@"scheme"], access_options[@"host"]];

                    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:baseUrl]];
                    
                    manager.responseSerializer = [AFJSONResponseSerializer serializer];
                    AFJSONResponseSerializer *jsonResponseSerializer = [AFJSONResponseSerializer serializer];
                    manager.responseSerializer = jsonResponseSerializer;

                    NSMutableDictionary *parameters = [access_data mutableCopy];
                    parameters[@"client_id"] = client_id;
                    if(client_secret){
                        parameters[@"client_secret"] = client_secret;
                    }
                    
                    [manager POST:access_options[@"path"] parameters:parameters progress:^(NSProgress * _Nonnull downloadProgress) {
                        // Nothing
                    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                        // Ignore if the url is different
                        NSString *access_token = responseObject[@"access_token"];
                        NSString *refresh_token = responseObject[@"refresh_token"];
                        if(access_token){
                            NSString *token_type = responseObject[@"token_type"];
                            AFOAuthCredential *credential = [AFOAuthCredential credentialWithOAuthToken:access_token tokenType:token_type];
                            credential.refreshToken = refresh_token;
                            [AFOAuthCredential storeCredential:credential withIdentifier:client_id];
                            [[Jason client] success];
                            
                        } else {
                            [[Jason client] error];
                        }
                    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                        [[Jason client] error];
                    }];
                }
            }
        } else {
            /********************************************************************************
            *
            * Case 2: Assumes the rest will be "code" type. (May need to add more implementations?)
            *
            ********************************************************************************/
            NSString *client_id = self.options[@"authorize"][@"client_id"];
            NSString *client_secret = self.options[@"authorize"][@"client_secret"];
            
            NSDictionary *authorize_options = self.options[@"authorize"];
            if(!authorize_options || authorize_options.count == 0){
                [[Jason client] error];
            } else {
                if(!authorize_options[@"scheme"] || [authorize_options[@"scheme"] length] == 0
                   || !authorize_options[@"host"] || [authorize_options[@"host"] length] == 0
                   || !authorize_options[@"path"] || [authorize_options[@"path"] length] == 0){
                    [[Jason client] error];
                } else {
                    // First see if I can refresh the token (if it already exists but expired)
                    AFOAuthCredential *credential = [AFOAuthCredential retrieveCredentialWithIdentifier:client_id];
                    if(credential && credential.isExpired && credential.refreshToken){
                        [self refresh_token:client_id];
                    } else {
                        // Generate the final url (U) from scheme/host/path/data
                        NSString *url = [NSString stringWithFormat:@"%@://%@%@", authorize_options[@"scheme"], authorize_options[@"host"], authorize_options[@"path"]];
                        NSMutableDictionary *parameters = [authorize_options[@"data"] mutableCopy];
                        NSURLComponents *components = [NSURLComponents componentsWithString:url];
                        NSMutableArray *queryItems = [NSMutableArray array];
                        if(authorize_options[@"client_id"]){
                            parameters[@"client_id"] = authorize_options[@"client_id"];
                        }
                        if(authorize_options[@"client_secret"]){
                            parameters[@"client_secret"] = authorize_options[@"client_secret"];
                        }
                        for (NSString *key in parameters) {
                            [queryItems addObject:[NSURLQueryItem queryItemWithName:key value:parameters[key]]];
                        }
                        components.queryItems = queryItems;
                        NSURL *U = components.URL;

                        
                        if(view && [view isEqualToString:@"app"]){
                            // Launch external safari for oauth
                            [[UIApplication sharedApplication] openURL:U];
                        } else {
                            // By default use SFSafariViewController
                            SFSafariViewController *vc = [[SFSafariViewController alloc] initWithURL:U];
                            vc.delegate = self;
                            [self.VC presentViewController:vc animated:NO completion:^{ }];
                        }
                    }
                }
            }
            
        }
        
    }
    
}
- (void)oauth_callback: (NSNotification*)notification{
    if(self.options[@"version"] && [self.options[@"version"] isEqualToString:@"1"]){
        /*********************************************************
         * OAuth 1 flow
         *********************************************************/
       // Example options
        /*
         
         {
             "login": {
                 "type": "$oauth.auth",
                 "options": {
                     "version": "1",
                     "request": {
                         "scheme": "https",
                         "host": "www.tumblr.com",
                         "path": "/oauth/request_token",
                         "data": {
                             "oauth_callback": "jasonette://oauth"
                         }
                     },
                     "authorize": {
                         "scheme": "https",
                         "host": "www.tumblr.com",
                         "path": "/oauth/authorize"
                     },
                     "access": {
                         "scheme": "https",
                         "host": "www.tumblr.com",
                         "path": "/oauth/access_token"
                     }
                 },
                 "success": {
                     "trigger": "reload"
                 }
             },
         }
         */
        NSString *client_id = self.options[@"access"][@"client_id"];
        NSString *client_secret = self.options[@"access"][@"client_secret"];
        
        [self.VC.navigationController dismissViewControllerAnimated:YES completion:nil];
        NSDictionary *access_options = self.options[@"access"];
        if(!access_options || access_options.count == 0){
            [[Jason client] error];
        } else {
            if(!access_options[@"scheme"] || [access_options[@"scheme"] length] == 0
               || !access_options[@"host"] || [access_options[@"host"] length] == 0
               || !access_options[@"path"] || [access_options[@"path"] length] == 0){
                [[Jason client] error];
            } else {
                
                NSURL *url = notification.userInfo[@"url"];
                NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
                NSArray *queryItems = [components queryItems];
                NSString *oauth_token = [self valueForKey:@"oauth_token" fromQueryItems:queryItems];
                NSString *oauth_verifier = [self valueForKey:@"oauth_verifier" fromQueryItems:queryItems];
                [[NSNotificationCenter defaultCenter] removeObserver:self];
                NSDictionary *parameters = @{ @"oauth_verifier" : oauth_verifier};
                NSString *oauth1_three_legged_secret;
                if(self.cache && self.cache[@"oauth1_three_legged_secret"]){
                    oauth1_three_legged_secret = self.cache[@"oauth1_three_legged_secret"];
                }
                NSURLRequest *request = [TDOAuth URLRequestForPath:access_options[@"path"]
                            POSTParameters:parameters
                                      host:access_options[@"host"]
                               consumerKey:client_id
                            consumerSecret:client_secret
                               accessToken:oauth_token
                               tokenSecret:oauth1_three_legged_secret];
                AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
                manager.responseSerializer = [AFHTTPResponseSerializer serializer];
                manager.requestSerializer = [AFJSONRequestSerializer serializer];
                
                NSURLSessionDataTask *task = [manager dataTaskWithRequest:request completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
                    // Ignore if the url is different
                    if(![request.URL.absoluteString isEqualToString:response.URL.absoluteString]) return;
                    
                    if (!error) {
                        // Temp url just to take advantage of componentsWithURL
                        NSString* s= [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
                        NSString *urlToParse = [NSString stringWithFormat:@"http://localhost?%@",s];
                        NSURLComponents *components = [NSURLComponents componentsWithURL:[NSURL URLWithString:urlToParse] resolvingAgainstBaseURL:NO];
                        NSArray *queryItems = [components queryItems];
                        NSString *oauth_token = [self valueForKey:@"oauth_token" fromQueryItems:queryItems];
                        NSString *oauth_token_secret = [self valueForKey:@"oauth_token_secret" fromQueryItems:queryItems];
                        
                        
                        NSString *APP_NAME = [[NSBundle mainBundle] bundleIdentifier];
                        
                        UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:[NSString stringWithFormat:@"%@", APP_NAME]];
                        [keychain setString:oauth_token forKey:[NSString stringWithFormat:@"%@#token", client_id]];
                        [keychain setString:oauth_token_secret forKey:[NSString stringWithFormat:@"%@#secret", client_id]];
                        [[Jason client] success];
                    } else {
                        [[NSNotificationCenter defaultCenter] removeObserver:self];
                        [[Jason client] error];
                    }
                }];
                [task resume];
            }
        }
    } else {
        /*********************************************************
         * OAuth 2 flow
         *********************************************************/
        // Example options
        /*
         
        // Send access params as header
         "type": "$oauth.auth",
         "options": {
             "version": "2",
             "authorize": { ... },
             "access": {
                 "client_id": "{{$keys.reddit_client_id}}",
                 "client_secret": "{{$keys.reddit_client_secret}}",
                 "scheme": "https",
                 "host": "i.reddit.com",
                 "path": "/api/v1/access_token",
                 "data": {
                     "grant_type": "authorization_code",
                     "redirect_uri": "jasonette://oauth",
                 }
             }
         },...
         
        // Send access params as body
         "type": "$oauth.auth",
         "options": {
             "version": "2",
             "token_in_body": "true",
             "authorize": { ... },
             "access": {
                 "client_id": "{{$keys.reddit_client_id}}",
                 "client_secret": "{{$keys.reddit_client_secret}}",
                 "scheme": "https",
                 "host": "i.reddit.com",
                 "path": "/api/v1/access_token",
                 "data": {
                     "grant_type": "authorization_code",
                     "redirect_uri": "jasonette://oauth"
                 }
             }
         },...
         */
        
        [self.VC.navigationController dismissViewControllerAnimated:YES completion:nil];
        
        NSURL *url = notification.userInfo[@"url"];
        // extract parameters
        NSArray *returnValues = [self extractQueryParams:url.absoluteString];
        
        // Exception case (Dropbox) where authorize returns access_token directly, in which case we don't need to go forward with the next step of requesting access_token again
        NSString *access_token = [self valueForKey:@"access_token" fromQueryItems:returnValues];

        if(access_token){
            NSString *client_id = self.options[@"authorize"][@"client_id"];
            
            NSString *token_type = [self valueForKey:@"token_type" fromQueryItems:returnValues];
            AFOAuthCredential *credential = [AFOAuthCredential credentialWithOAuthToken:access_token tokenType:token_type];
            [AFOAuthCredential storeCredential:credential withIdentifier:client_id];
            [[Jason client] success];
        } else {
            NSDictionary *access_options = self.options[@"access"];
            
            // Setup access params
            NSMutableDictionary *access_data;
            
            if(access_options[@"data"]){
                access_data = [access_options[@"data"] mutableCopy];
            }
            
            NSString *client_id = self.options[@"access"][@"client_id"];
            NSString *client_secret = self.options[@"access"][@"client_secret"];
            if(!client_secret) client_secret = @"";
            
            NSString *code = [self valueForKey:@"code" fromQueryItems:returnValues];
            
            if(!access_options || access_options.count == 0
               || !access_options[@"scheme"] || [access_options[@"scheme"] length] == 0
               || !access_options[@"host"] || [access_options[@"host"] length] == 0
               || !access_options[@"path"] || [access_options[@"path"] length] == 0){
                [[Jason client] error];
            } else {
                NSString *urlString = [NSString stringWithFormat:@"%@://%@", access_options[@"scheme"], access_options[@"host"]];
                NSURL *baseURL = [NSURL URLWithString:urlString];
                    
                
                AFOAuth2Manager *OAuth2Manager = [[AFOAuth2Manager alloc] initWithBaseURL:baseURL
                                                    clientID:client_id
                                                   secret:client_secret];
                    
                // In most cases oauth endpoints don't use basic auth (although it's more secure to use basic auth)
                // So the default is 'non basic auth'
                    
                if(access_options[@"basic"]){
                    [OAuth2Manager setUseHTTPBasicAuthentication:YES];
                } else {
                    [OAuth2Manager setUseHTTPBasicAuthentication:NO];
                }
                access_data[@"code"] = code;
                
                [OAuth2Manager authenticateUsingOAuthWithURLString:access_options[@"path"]
                                                        parameters:access_data success:^(AFOAuthCredential *credential) {
                                                            [AFOAuthCredential storeCredential:credential withIdentifier:client_id];
                                                            
                                                            [[Jason client] success];
                                                        }
                                                        failure:^(NSError *error) {
                                                            NSLog(@"Error: %@", error);
                                                            NSString* ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                                                            NSLog(@"#ncoded = %@",ErrorResponse);

                                                            [[Jason client] error];
                                                        }];
            }
        }
    }
    
}
- (NSArray *)extractQueryParams:(NSString *)str{
    NSString *urlToParse = str;
    NSMutableArray *ret = [[NSMutableArray alloc]init];
    NSURLComponents *components = [NSURLComponents componentsWithURL:[NSURL URLWithString:urlToParse] resolvingAgainstBaseURL:NO];
    NSArray *items = [components queryItems];
    [ret addObjectsFromArray:items];
    if([components fragment]){
        NSString *fragmentUrlToParse = [NSString stringWithFormat:@"http://localhost?%@", [components fragment]];
        NSURLComponents *fragmentComponents = [NSURLComponents componentsWithURL:[NSURL URLWithString:fragmentUrlToParse] resolvingAgainstBaseURL:NO];
        NSArray *fragmentQueryItems = [fragmentComponents queryItems];
        [ret addObjectsFromArray:fragmentQueryItems];
    }
    return ret;
    
}
- (NSString *)valueForKey:(NSString *)key
           fromQueryItems:(NSArray *)queryItems
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name=%@", key];
    NSURLQueryItem *queryItem = [[queryItems
                                  filteredArrayUsingPredicate:predicate]
                                 firstObject];
    return queryItem.value;
}

@end
