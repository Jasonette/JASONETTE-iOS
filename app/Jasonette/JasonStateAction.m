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

}
- (void) import {

    /*************
     Case 1:

     {
        "type": "$state.import",
        "options": {
            "username": "username@https://www.jasonbase.com/things/3nf.json"
        },
        "success": {
            "type": "$set",
            "options": {
                "username": "{{$jason.username}}"
            }
        }
     }
     *************/

    for(NSString *key in self.options){
        [self extract:self.options[key]];
    }
}

- (void) extract: (NSString *) url{
    NSError* regexError = nil;
    NSString *pattern = @"(([^$\"@]+)@)?([^$\"]+)";
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive|NSRegularExpressionDotMatchesLineSeparators error:&regexError];
    NSArray *matches = [regex matchesInString:url options:NSMatchingWithoutAnchoringBounds range:NSMakeRange(0, url.length)];
    for(int i = 0; i<matches.count; i++){
        NSTextCheckingResult* match = matches[i];
        NSRange group1 = [match rangeAtIndex:1];
        NSRange group2 = [match rangeAtIndex:2];
        NSRange group3 = [match rangeAtIndex:3];
        if(group1.length > 0){
            
        }
        if(group2.length > 0){
            NSString *path = [url substringWithRange:group2];
            NSLog(@"Path : %@", path);
        }
        if(group3.length > 0){
            NSString *u = [url substringWithRange:group3];
            NSLog(@"URL : %@", u);
        }
    }
}
@end
