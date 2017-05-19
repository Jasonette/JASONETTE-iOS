//
//  JasonStateAction.m
//  Jasonette
//
//  Copyright © 2017 Jasonette. All rights reserved.
//

#import "JasonStateAction.h"

@implementation JasonStateAction
- (void) set {
    /*************
     {
         "type": "$state.set",
         "options": {
            "username@https://www.jasonbase.com/things/3n3.json": "ethan",
            "email@https://www.jasonbase.com/things/3nf.json": "ethan.gliechtenstein@gmail.com"
         },
         "success": {
             "type": "$render"
         }
     }
     *************/
    for(NSString *key in self.options){
        id value = self.options[key];
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:value];
        [[NSUserDefaults standardUserDefaults] setObject:data forKey:key];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[Jason client] success];

}
- (void) reset {
    /*************
     {
         "type": "$state.reset",
         "options": ["username@https://www.jasonbase.com/things/3n3.json", "email@https://www.jasonbase.com/things/3nf.json"],
         "success": {
             "type": "$render"
         }
     }
     *************/
    if([self.options isKindOfClass:[NSArray class]]){
        for(int i = 0 ; i < [self.options count] ; i++){
            NSString *key = self.options[i];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
        }
    } else {
        [[Jason client] error: @{@"error": @"Need to pass an array"}];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[Jason client] success];
    
}
- (void) get {
    /*************
     {
        "type": "$state.get",
        "options": {
            "username": "username@https://www.jasonbase.com/things/3n3.json",
            "email": "email@https://www.jasonbase.com/things/3nf.json"
        },
        "success": {
            "type": "$set",
            "options": {
                "username": "{{$jason.username}}",
                "email": "{{$jason.email}}"
            }
         }
     }
     *************/

    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    for(NSString *var in self.options){
        NSString *state_key = self.options[var];
        NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:state_key];
        if(data){
            id o =[NSKeyedUnarchiver unarchiveObjectWithData:data];
            if(o){
                dict[var] = o;
            }
        }
    }
    [[Jason client] success:dict];
}
@end
