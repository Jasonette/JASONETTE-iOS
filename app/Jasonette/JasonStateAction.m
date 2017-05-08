//
//  JasonStateAction.m
//  Jasonette
//
//  Copyright © 2017 Jasonette. All rights reserved.
//

#import "JasonStateAction.h"

@implementation JasonStateAction
- (void) export {

    /*************
    {
        "type": "$state.export",
        "options": {
            "username": "Ethan",
            "email": "ethan.gliechtenstein@gmail.com"
        },
        "success": {
            "type": "$close"
        }
    }
    *************/
    
    // 1. Stores the key value pair under the URL
    
    [[NSUserDefaults standardUserDefaults] setObject:self.options forKey:self.VC.url];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[Jason client] success];
}
- (void) import {

    /*************

     {
        "type": "$state.import",
        "options": {
            "db": "https://www.jasonbase.com/things/3nf.json"
        },
        "success": {
            "type": "$set",
            "options": {
                "db": "{{$jason.db}}"
            }
        }
     }
     
     1. If there's any state object stored under the URL, it will be returned.
     2. If there's no state object stored under the URL, the return value will NOT include the key/value pair
     
     *************/

    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    for(NSString *key in self.options){
        NSString *url = self.options[key];
        NSDictionary *o = [[NSUserDefaults standardUserDefaults] objectForKey:url];
        if(o){
            dict[key] = o;  // only return an object if state exists under the URL
        }
    }
    [[Jason client] success:dict];
}

@end
