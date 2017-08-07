//
//  JasonGlobalAction.m
//  Jasonette
//
//  Created by e on 6/18/17.
//  Copyright © 2017 Jasonette. All rights reserved.
//

#import "JasonGlobalAction.h"

@implementation JasonGlobalAction
- (void)reset{
    
    /********************
    
     The following resets a global variable named "db".
     When a variable is reset, the key itself gets destroyed, so when you check ('db' in $global), it will return false
     
     {
       "type": "$global.reset",
       "options": {
         "items": ["db"]
       }
     }
     
     ********************/
    
    @try {
        NSString *global = @"$global";
        id data = [[NSUserDefaults standardUserDefaults] objectForKey:global];
        NSMutableDictionary *mutated;

        BOOL deprecated = ![data isKindOfClass:[NSData class]];
        NSDictionary *to_reset;
        if(data) {
            if(deprecated) {
                // string type (old version, will deprecate)
                to_reset = (NSDictionary *)data;
            } else {
                to_reset = (NSDictionary*) [NSKeyedUnarchiver unarchiveObjectWithData:data];
            }
        } else {
            to_reset = nil;
        }
        if(to_reset && to_reset.count > 0){
            mutated = [to_reset mutableCopy];
            if(self.options && self.options[@"items"]){
                for(NSString *key in self.options[@"items"]){
                    [mutated removeObjectForKey:key];
                }
            }
        } else {
            mutated = [@{} mutableCopy];
        }
        NSData *updated = [NSKeyedArchiver archivedDataWithRootObject:mutated];
        [[NSUserDefaults standardUserDefaults] setObject:updated forKey:global];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [Jason client].global = mutated;
        [[Jason client] success: mutated];
    } @catch (NSException *e){
        [[Jason client] error];
    }
    
}
- (void)set{
    
    /********************
     
     The following sets a global variable named "db".
     
     {
       "type": "$global.set",
       "options": {
         "db": ["a", "b", "c", "d"]
       }
     }
     
     Once set, you can access them through template expressions from ANYWHERE within the app, like this:
     
     {
       "items": {
         "{{#each $global.db}}": {
           "type": "label",
           "text": "{{this}}"
         }
       }
     }
     
     ********************/

    
    if([[self.options description] containsString:@"{{"] && [[self.options description] containsString:@"}}"]){
        [[Jason client] error];
        return;
    }
    
    @try {
        NSString *global = @"$global";
        
        id data = [[NSUserDefaults standardUserDefaults] objectForKey:global];
        NSDictionary *to_set;
        NSMutableDictionary *mutated;

        if(data) {
            // already set once before
            BOOL deprecated = ![data isKindOfClass:[NSData class]];
            if(data) {
                if(deprecated) {
                    // string type (old version, will deprecate)
                    to_set = (NSDictionary *)data;
                } else {
                    to_set = (NSDictionary*) [NSKeyedUnarchiver unarchiveObjectWithData:data];
                }
            } else {
                to_set = nil;
            }
            if(to_set && to_set.count > 0){
                mutated = [to_set mutableCopy];
                for(NSString *key in self.options){
                    mutated[key] = self.options[key];
                }
            } else {
                mutated = [self.options mutableCopy];
            }
            
            NSData *updated = [NSKeyedArchiver archivedDataWithRootObject:mutated];
            [[NSUserDefaults standardUserDefaults] setObject:updated forKey:global];
            [[NSUserDefaults standardUserDefaults] synchronize];

        } else {
            // first time using global
            NSData *updated = [NSKeyedArchiver archivedDataWithRootObject:self.options];
            [[NSUserDefaults standardUserDefaults] setObject:updated forKey:global];
            [[NSUserDefaults standardUserDefaults] synchronize];
            mutated = [self.options mutableCopy];
        }
        
        
        
        [Jason client].global = mutated;
        [[Jason client] success: mutated];
    } @catch (NSException *e){
        [[Jason client] error];
    }
    
}

@end
