# AFOAuth2Manager

AFOAuth2Manager is an extension for [AFNetworking](http://github.com/AFNetworking/AFNetworking/) that simplifies the process of authenticating against an [OAuth 2](https://tools.ietf.org/html/rfc6749) provider.

## Example Usage

### Authentication

```objective-c
NSURL *baseURL = [NSURL URLWithString:@"http://example.com/"];
AFOAuth2Manager *OAuth2Manager =
            [[AFOAuth2Manager alloc] initWithBaseURL:baseURL
                                            clientID:kClientID
                                              secret:kClientSecret];

[OAuth2Manager authenticateUsingOAuthWithURLString:@"/oauth/token"
                                          username:@"username"
                                          password:@"password"
                                             scope:@"email"
                                           success:^(AFOAuthCredential *credential) {
                                               NSLog(@"Token: %@", credential.accessToken);
                                           }
                                           failure:^(NSError *error) {
                                               NSLog(@"Error: %@", error);
                                           }];
```

### Authorizing Requests

```objective-c
AFHTTPSessionManager *manager =
    [[AFHTTPSessionManager alloc] initWithBaseURL:baseURL];

[manager.requestSerializer setAuthorizationHeaderFieldWithCredential:credential];

[manager GET:@"/path/to/protected/resource"
  parameters:nil
    progress:nil
     success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
         NSLog(@"Success: %@", responseObject);
     }
     failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
         NSLog(@"Failure: %@", error);
     }];
```

### Storing Credentials

```objective-c
[AFOAuthCredential storeCredential:credential
                    withIdentifier:serviceProviderIdentifier];
```

### Retrieving Credentials

```objective-c
AFOAuthCredential *credential =
        [AFOAuthCredential retrieveCredentialWithIdentifier:serviceProviderIdentifier];
```

## Documentation

Documentation for all releases of AFOAuth2Manager are [available on CocoaDocs](http://cocoadocs.org/docsets/AFOAuth2Manager/).


## License

AFOAuth2Manager is available under the MIT license. See the LICENSE file for more info.
