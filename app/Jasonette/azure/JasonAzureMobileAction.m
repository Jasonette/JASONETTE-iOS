//
//  JasonAzureAction.m
//  Jasonette
//
//  Copyright © 2016 seletz. All rights reserved.
//

#import "JasonAppDelegate.h"
#import "JasonAzuremobileAction.h"
#import <MicrosoftAzureMobile/MicrosoftAzureMobile.h>

@implementation JasonAzuremobileAction

@synthesize client;


#pragma mark Singleton Methods

+ (id)sharedInstance {
    static JasonAzuremobileAction *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (id)init {
    if (self = [super init]) {
        NSURL *file = [[NSBundle mainBundle] URLForResource:@"settings" withExtension:@"plist"];
        NSDictionary *plist = [NSDictionary dictionaryWithContentsOfURL:file];
        NSDictionary *azure_settings = plist[@"azure"];
        
        if (!azure_settings) {
            NSLog(@"Unable to initialise Azure Services -- no azure settings.");
            return nil;
        }
        
        // Azure Mobile Services
        NSString *app_url = azure_settings[@"app_url"];
        if (app_url) {
            NSLog(@"Azure Mobile App URL: %@", app_url);
            client = [MSClient clientWithApplicationURLString: app_url];
        }
    }
    return self;
}

#pragma mark -- Azure Mobile Table Actions

/**
 Query a table and return results.  Optionally pass a query string.
 
 Example:
 
     "type": "$AzureMobile.query",
        "options": {
            "table": "todoitem",
            "query": "complete == NO"
        },
        "success": {
            "type": "$log.debug",
            "options": {
                "text": "SUCCESS"
            }
        },
     }

 */
-(void)query {
    if(self.options){
        NSString *table_name = self.options[@"table"];
        NSString *query_string = self.options[@"query"];
        
        if (!client) {
            NSLog(@"Error: azure client not initialised.");
            [[Jason client] error];
            return;
        }
        
        if (!table_name) {
            NSLog(@"Error: AzureMobile: insert: no table.");
            [[Jason client] error];
            return;
        }
        
        MSTable *table = [client tableWithName: table_name];
        
        if (query_string) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:query_string];
            [table readWithPredicate:predicate
                          completion:^(MSQueryResult *result, NSError *error) {
                              if(error) {
                                  NSLog(@"ERROR %@", error);
                                  [[Jason client] error];
                                  return;
                              }
                              
                              [[Jason client] success:@{@"count": [NSNumber numberWithLong: result.totalCount], @"items": result.items}];
                              
                          }];
        } else {
            [table readWithCompletion:^(MSQueryResult *result, NSError *error) {
                if(error) {
                    NSLog(@"ERROR %@", error);
                    [[Jason client] error];
                    return;
                }
                
                [[Jason client] success:@{@"count": [NSNumber numberWithLong: result.totalCount], @"items": result.items}];
                
            }];
            
        }
    }
    
    
}

-(void)insert {
    if(self.options){
        NSString *table_name = self.options[@"table"];
        NSDictionary *data = self.options[@"data"];
        
        if (!table_name) {
            NSLog(@"Error: AzureMobile: insert: no table.");
            [[Jason client] error];
            return;
        }
        
        if (!data) {
            NSLog(@"Error: AzureMobile: insert: no data.");
            [[Jason client] error];
            return;
        }
        
        if (!client) {
            NSLog(@"Error: azure client not initialised.");
            [[Jason client] error];
            return;
        }
        
        MSTable *table = [client tableWithName: table_name];
        [table insert:data completion:^(NSDictionary *insertedItem, NSError *error) {
            if (error) {
                NSLog(@"Error: AzureMobile: insert: %@", error);
                [[Jason client] error];
                
            } else {
                NSLog(@"AzureMobile: Item inserted, id: %@", [insertedItem objectForKey:@"id"]);
                [[Jason client] success: insertedItem];
            }
        }];
    }
    [[Jason client] success];
    
}

#pragma mark -- APNS Push Related

-(void)registerDeviceToken {
    if(self.options) {
        NSData *token = self.options[@"device_token"];
        if (!token) {
            NSLog(@"Error: AzureMobile: registerDeviceToken: no token.");
            [[Jason client] error];
            return;
        }
        
        [client.push registerDeviceToken:token completion:^(NSError *error) {
            if (error) {
                [[Jason client] error: error];
            } else {
                [[Jason client] success];
            }
        }];
        
    }
}

@end
