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
    BOOL isRemote = [parsed[@"remote"] boolValue];
    // 1. If the request is for a remote url
    //   - No need to ask for passcode
    //   - But only return public objects
    if (isRemote) {
        [self _fetch:url remote:isRemote];
    
    // 2. If the request is for the current url
    //   - MUST ask for passcode, since it will be returning private content as well
    } else {
        if (authenticated) {
            [self _fetch:url remote:isRemote];
        } else {
            [self auth: @"request"];
        }
    }

}


/*******************
{
	"type": "$key.add",
	"options": {
		"components": [{
			"key": "type",
			"val": "ETH"
		}, {
			"key": "publickey",
			"val": "0xjdnfenfkdewfhk384b4"
		}, {
			"key": "name",
			"val": "Ethereum"
		}, {
			"key": "privatekey",
			"val": "0x8dbgjenb8fngjwev742gfh47gh8ds87fh3bv"
		}]
	}
}
*******************/
- (void) add {

    if (!self.options || self.options.count == 0) {
        [[Jason client] error: @{@"message": @"Must specify an item to add"}];
        return;
    }
    
    NSArray *components = self.options[@"components"];
    if (!components) {
        [[Jason client] error: @{@"message": @"A key item must have at least one component"}];
        return;
    }
    
    if (components && components.count > 0) {
        NSDictionary *parsed = [self _parse];
        NSString *url = parsed[@"url"];
        BOOL isRemote = [parsed[@"remote"] boolValue];
        
        if (isRemote) {
            [[Jason client] error: @{@"message": @"You are not allowed to add keys remotely"}];
        } else {
            NSMutableArray *items = [[self deserialize:url] mutableCopy];
            [items addObject:self.options];
            [self serialize:items atUrl:url];
            [[Jason client] success: @{@"items": items}];
        }
    } else {
        [[Jason client] error: @{@"message": @"A key must have at least a single component"}];
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
	"type": "$key.set",
	"options": {
		"index": "{{$jason.index}}",
		"components": [{
			"key": "name",
			"val": "{{$jason.new_value}}"
		}]
	},
	"success": {
		"type": "$render"
	}
}
*********************************/
- (void) set {
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
                    NSDictionary *item = items[index];
                    NSMutableArray *components = item[@"components"];
                    
                    
                    /*
                     item := {
                         components: [{
                             "key": "",
                             "val": ""
                         }, {
                             "key": "",
                             "val": ""
                         }]
                     }
                     */
                    
                    if (self.options[@"components"] && [self.options[@"components"] isKindOfClass:[NSArray class]] && [self.options[@"components"] count] > 0) {
                        for (int i=0; i<[self.options[@"components"] count]; i++) {
                            // Find the component to update
                            NSDictionary *new_component = self.options[@"components"][i];
                            for (int j=0; j<components.count; j++) {
                                if ([components[j][@"key"] isEqualToString:new_component[@"key"]]) {
                                    // Match found!
                                    // 1. Make a temp component
                                    NSMutableDictionary *to_update = [components[j] mutableCopy];
                                    // 2. Update the temp component's val
                                    to_update[@"val"] = new_component[@"val"];
                                    // 3. Update the original component with the updated component
                                    components[j] = to_update;
                                    break;
                                }
                            }
                        }
                        
                        // replace the item at index with the new set of components
                        [items replaceObjectAtIndex:index withObject:@{@"components": components}];
                        [self serialize:items atUrl:url];
                        [[Jason client] success: @{@"items": items}];
                        
                    } else {
                        [[Jason client] error: @{@"message": @"Please specify at least one component to update"}];
                    }
                } else {
                    [[Jason client] error: @{@"message": @"Invalid index"}];
                }
            } else {
                [[Jason client] error: @{@"message": @"Need to specify an index to set value of"}];
            }

        } else {
            [self auth:@"set"];
        }
    }
}

- (void) reset {
    NSDictionary *parsed = [self _parse];
    NSString *url = parsed[@"url"];
    BOOL isRemote = [parsed[@"remote"] boolValue];
    
    // Can only add keys locally
    if (isRemote) {
        [[Jason client] error: @{@"message": @"You can only reset keys from the owner view"}];
    } else {
        if (authenticated) {
            NSArray *items = [[NSArray alloc] init];
            [self serialize:items atUrl:url];
            [[Jason client] success: @{@"items": items}];

        } else {
            [self auth: @"reset"];
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
- (void) _fetch: (NSString *) url remote: (BOOL) isRemote{
    
    UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:url];
    NSData *data = [keychain dataForKey:@"$key"];
    NSDictionary *key_root = (NSDictionary*) [NSKeyedUnarchiver unarchiveObjectWithData:data];
    NSArray *items = key_root[@"items"];
    
    if (!items) {
        items = @[];
    } else {
        if (isRemote) {
            // Get only the public components
            NSMutableArray *filtered_items = [[NSMutableArray alloc] init];
            for(int i=0; i<items.count; i++) {
                if (!items[i][@"components"]) {
                    [[Jason client] error: @{@"message": @"Invalid format"}];
                    return;
                }
                
                NSArray *components = items[i][@"components"];
                
                // Filtering only the public components
                NSMutableArray *filtered_components = [[NSMutableArray alloc] init];
                for(int j=0; j<components.count; j++) {
                    NSString *read = components[j][@"read"];
                    // If "read": "public", add the component to the filtered components array
                    if (read && [read isEqualToString:@"public"]) {
                        [filtered_components addObject:components[j]];
                    }
                }

                // Add the filtered item into filtered_items array
                [filtered_items addObject:@{@"components": filtered_components}];
            }
            items = filtered_items;
        } else {
            // Current view, so return the entire array of public/private parts
            // Therefore don't need to do anything here
        }
    }
    
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
    } else if ([origin isEqualToString:@"set"]) {
        [self set];
    } else if ([origin isEqualToString:@"reset"]) {
        [self reset];
    }
}


@end
