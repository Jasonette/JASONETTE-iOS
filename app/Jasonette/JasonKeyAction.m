//
//  JasonKeyAction.m
//  Jasonette
//
//  Copyright © 2017 Jasonette. All rights reserved.
//

#import "JasonKeyAction.h"
@interface JasonKeyAction(){
    NSString *origin;
    BOOL authenticated;
}
@end
    
@implementation JasonKeyAction

- (void) auth: (NSString *) o {
    // 1. Save the original action
    origin = o;
    authenticated = NO;

    [LTHPasscodeViewController sharedUser].hidesCancelButton = NO;
    [LTHPasscodeViewController sharedUser].hidesBackButton = NO;
    [LTHPasscodeViewController sharedUser].delegate = self;

    // 2. Run authentication
    if ([LTHPasscodeViewController doesPasscodeExist]) {
        // Request user to enter passcode
        if ([LTHPasscodeViewController didPasscodeTimerEnd]) {
            [[LTHPasscodeViewController sharedUser] showLockScreenWithAnimation:YES
                                                                     withLogout:YES
                                                                 andLogoutTitle:@"Cancel"];
        }
    } else {
        [[LTHPasscodeViewController sharedUser] showForEnablingPasscodeInViewController:[[Jason client] getVC] asModal:YES];
    }

}

- (void) request {
    /*
     1. Check if passcode exists
        => If yes, request for passcode
        => If no, run $key.password
     */
    

    NSDictionary *parsed = [self _parse];
    NSString *url = parsed[@"url"];
    NSArray *items = self.options[@"items"];
    BOOL isRemote = [parsed[@"remote"] boolValue];
    
    // 1. If the request is for a remote url
    //   - No need to ask for passcode
    //   - But only return public objects
    if (isRemote) {
        [self _fetch:url withQuery: items remote:isRemote];
    
    // 2. If the request is for the current url
    //   - MUST ask for passcode, since it will be returning private content as well
    } else {
        if (authenticated) {
            [self _fetch:url withQuery: items remote:isRemote];
        } else {
            [self auth: @"request"];
        }
    }

}


/*******************
{
	"type": "$key.add",
	"options": {
        "index": 1,
        "item": {
            "type": {
                "value": "ETH",
                "read": "public"
            },
            "publickey": {
                "value": "0xjdnfenfkdewfhk384b4"
            },
            "name": {
                "value": "Ethereum"
            },
            "privatekey": {
                "value": "0x8dbgjenb8fngjwev742gfh47gh8ds87fh3bv"
            }
        }
	}
}
*******************/
- (void) add {

    if (!self.options || self.options.count == 0) {
        [[Jason client] error: @{@"message": @"Must specify an item to add"}];
        return;
    }
    
    if (self.options[@"item"]) {
        NSDictionary *parsed = [self _parse];
        NSString *url = parsed[@"url"];
        BOOL isRemote = [parsed[@"remote"] boolValue];
        
        if (isRemote) {
            [[Jason client] error: @{@"message": @"You are not allowed to add keys remotely"}];
        } else {
            NSMutableArray *items = [[self deserialize:url] mutableCopy];
            if (self.options[@"index"]) {
                [items insertObject:self.options[@"item"] atIndex:[self.options[@"index"] intValue]];
            } else {
                [items addObject:self.options[@"item"]];
            }
            [self serialize:items atUrl:url];
            [[Jason client] success: @{@"items": items}];
        }
    } else {
        [[Jason client] error: @{@"message": @"Must specify an item to add"}];
    }
}
/*******************
{
	"type": "$key.remove",
	"options": {
         "index": 1
	}
}
*******************/
- (void) remove {
    NSDictionary *parsed = [self _parse];
    NSString *url = parsed[@"url"];
    BOOL isRemote = [parsed[@"remote"] boolValue];
    
    // Can only add keys locally
    if (isRemote) {
        [[Jason client] error: @{@"message": @"You can only add keys from the owner view"}];
    } else {
        if (authenticated) {
            if (self.options[@"index"]) {
                int index = [self.options[@"index"] intValue];
                NSMutableArray *items = [[self deserialize:url] mutableCopy];
                if (items.count > index) {
                    [items removeObjectAtIndex:index];
                    [self serialize:items atUrl:url];
                    [[Jason client] success: @{@"items": items}];
                } else {
                    [[Jason client] error: @{@"message": @"Invalid index"}];
                }
            } else {
                [[Jason client] error: @{@"message": @"Need to specify an index to remove from"}];
            }
        } else {
            [self auth:@"remove"];
        }
    }
}



/*********************************
{
	"type": "$key.update",
	"options": {
		"index": "{{$jason.index}}",
		"item": {
            "name": {
                "value": "{{$jason.new_value}}"
            }
		}
	},
	"success": {
		"type": "$render"
	}
}
*********************************/
- (void) update {
    NSDictionary *parsed = [self _parse];
    NSString *url = parsed[@"url"];
    BOOL isRemote = [parsed[@"remote"] boolValue];
    
    // Can only add keys locally
    if (isRemote) {
        [[Jason client] error: @{@"message": @"You can only set keys from the owner view"}];
    } else {
        if (authenticated) {
            if (self.options[@"index"]) {
                int index = [self.options[@"index"] intValue];
                NSMutableArray *items = [[self deserialize:url] mutableCopy];
                if (items.count > index) {
                    NSDictionary *item = [items[index] mutableCopy];
                    
                    if (self.options[@"item"]) {

                        NSDictionary *query_item = self.options[@"item"];

                        /**
                         
                        query_item := {
                            "name": {
                                "value": "{{$jason.new_value}}",
                                "read": "public"
                            },
                            "type": {
                                "value": "BTC"
                            }
                        }
                         
                         **/

                        for (NSString *key in query_item) {
                            for (NSString *attr_key in query_item[key]) {
                                item[key][attr_key] = query_item[key][attr_key];
                            }
                        }
                        
                        items[index] = item;
                        [self serialize:items atUrl:url];
                        [[Jason client] success: @{@"items": items}];
                        
                    } else {
                        [[Jason client] error: @{@"message": @"Please specify a query"}];
                    }
                } else {
                    [[Jason client] error: @{@"message": @"Invalid index"}];
                }
            } else {
                [[Jason client] error: @{@"message": @"Need to specify an index to set value of"}];
            }

        } else {
            [self auth:@"update"];
        }
    }
}

/*********************************
{
	"type": "$key.clear",
	"success": {
		"type": "$render"
	}
}
*********************************/
- (void) clear {
    NSDictionary *parsed = [self _parse];
    NSString *url = parsed[@"url"];
    BOOL isRemote = [parsed[@"remote"] boolValue];
    
    // Can only add keys locally
    if (isRemote) {
        [[Jason client] error: @{@"message": @"You can only clear keys from the owner view"}];
    } else {
        if (authenticated) {
            NSArray *items = [[NSArray alloc] init];
            [self serialize:items atUrl:url];
            [[Jason client] success: @{@"items": items}];
            
        } else {
            [self auth: @"clear"];
        }
    }
}
/*
 Update Password
 */
- (void) password {
    // Request user to register a password
    [LTHPasscodeViewController sharedUser].hidesCancelButton = NO;
    [LTHPasscodeViewController sharedUser].hidesBackButton = NO;
    [[LTHPasscodeViewController sharedUser] showForChangingPasscodeInViewController:[[Jason client] getVC] asModal:YES];
}

# pragma mark - internal
- (NSDictionary *) _parse{
    // 1. Determine the URL key to query
    // 2. Detect if the request is a remote request or local request
    NSString *url = [self.options[@"url"] lowercaseString];
    JasonViewController *current_vc = (JasonViewController *)[[Jason client] getVC];
    
    Boolean isRemote;
    if (url) {
        // Another view
        isRemote = YES;
    } else {
        // Current view
        url = [current_vc.url lowercaseString];
        isRemote = NO;
    }

    if (isRemote) {
        return @{
            @"remote": @YES,
            @"url": url
        };
    } else {
        return @{
            @"remote": @NO,
            @"url": url
        };
    }
}
- (NSArray *) deserialize: (NSString *) url {
    UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:url];
    NSData *data = [keychain dataForKey:@"$key"];
    NSDictionary *key_root = (NSDictionary*) [NSKeyedUnarchiver unarchiveObjectWithData:data];
    NSArray *items = key_root[@"items"];
    if (items) {
        return items;
    } else {
        return @[];
    }
}
- (void) serialize: (NSArray *) items atUrl: (NSString *) url{
    UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:url];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:@{@"items": items}];
    [keychain setData:data forKey:@"$key"];
}
- (NSArray *) _filter_public: (NSArray *)items {
    
    /**
     
    items := [{
        "type": {
            "value": "BTC",
            "read": "public"
        },
        "name": {
            "value": "Bitcoin",
            "read": "public"
        },
        "publickey": {
            "value": "0xm4ng83ng8wengn3kngdn3ngknal32ng".
            "read": "public"
        },
        "privatekey": {
            "value": "0xngn4bgbebgbgbejbgjbjbjbebsdjbdskb328fg3bgjewh2112hfdhg"
        }
    }, {
        ...
    }, {
        ...
    }]
     
     **/
    
    NSMutableArray *filtered_items = [[NSMutableArray alloc] init];
    for(int i=0; i<items.count; i++) {
        NSDictionary *item = items[i];
        NSMutableDictionary *filtered_item = [[NSMutableDictionary alloc] init];
        for(NSString *key in item) {
            if (item[key][@"read"] && [item[key][@"read"] isEqualToString:@"public"]) {
                // it's a match!
                filtered_item[key] = item[key];
            }
        }
        [filtered_items addObject:filtered_item];
    }
    items = filtered_items;
    return items;
}
- (NSArray *) _filter: (NSArray *) items withQuery: (NSArray *) query_items {

    /**
     
        query_items := [{
            "type": {
                "value": "BTC"
            },
            "name": {
                "value": "Bitcoin"
            }
        }, {
            "type": {
                "value": "ETH"
            }
        }]

     **/
    if (query_items) {
        NSMutableArray *filtered_items = [[NSMutableArray alloc] init];
        for(int i=0; i<items.count; i++) {
            NSDictionary *item = items[i];
            for(int j=0; j<query_items.count; j++) {
                NSDictionary *query_item = query_items[j];
                BOOL its_a_match = YES;
                for(NSString *key in query_item) {
                    if([query_item[key][@"value"] isEqual:item[key][@"value"]]) {
                        // this condition must match, every time.
                        // Otherwise it needs to fail out.
                    } else {
                        its_a_match = NO;
                        break;
                    }
                }
                if (its_a_match) {
                    [filtered_items addObject:item];
                }
            }
        }
        return filtered_items;
    } else {
        return items;
    }
}

- (void) _fetch: (NSString *) url withQuery: (NSArray *) query_items remote: (BOOL) isRemote{
    
    UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:url];
    NSData *data = [keychain dataForKey:@"$key"];
    NSDictionary *key_root = (NSDictionary*) [NSKeyedUnarchiver unarchiveObjectWithData:data];
    NSArray *items = key_root[@"items"];
    
    if (!items) {
        items = @[];
    } else {
        if (isRemote) {
            // Get only the public components
            items = [self _filter_public: items];
        } else {
            // Current view, so return the entire array of public/private parts
            // Therefore don't need to do anything here
        }
    }
    
    items = [self _filter: items withQuery: query_items];
    
    [[Jason client] success: @{@"items": items}];

}


# pragma mark - LTHPasscodeViewController Delegates -

- (void)passcodeViewControllerWillClose {
    // need to disable, otherwise the library will trigger passcode evertime the app comes back from the background
    [[LTHPasscodeViewController sharedUser] disablePasscodeWhenApplicationEntersBackground];
}

- (void)maxNumberOfFailedAttemptsReached {
//    [LTHPasscodeViewController deletePasscodeAndClose];
    NSLog(@"Max Number of Failed Attempts Reached");
    [LTHPasscodeViewController close];
    [[Jason client] error: @{@"message": @"Mas Number of Failed Attempts Reached"}];
}

- (void)passcodeWasEnteredSuccessfully {
    /*
        Accessed from $key.request
        1. Fetch keys tied to this url
        2. run the success callback with keys
     */
    [self onsuccess];
}

- (void)logoutButtonWasPressed {
    // Cancel button pressed
    [LTHPasscodeViewController close];
    [[Jason client] error: @{@"message": @"Requires passcode"}];
}

- (void)passcodeWasEnabled {
    // The first time the passcode was enabled
    // Execute the original action that triggered this
    [self onsuccess];
}

- (void) onsuccess {
    authenticated = YES;
    if ([origin isEqualToString:@"request"]) {
        [self request];
    } else if ([origin isEqualToString:@"remove"]) {
        [self remove];
    } else if ([origin isEqualToString:@"update"]) {
        [self update];
    } else if ([origin isEqualToString:@"clear"]) {
        [self clear];
    }
}


@end
