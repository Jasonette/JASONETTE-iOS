//
//  Cache.m
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import "JasonCacheAction.h"

@implementation JasonCacheAction
- (void)reset{
    
    NSString *normalized_url = [self.VC.url lowercaseString];
    NSMutableDictionary *set = [[NSMutableDictionary alloc] init];
    [[NSUserDefaults standardUserDefaults] setObject:set forKey:normalized_url];
    [[NSUserDefaults standardUserDefaults] synchronize];
    self.VC.current_cache = set;
    [[Jason client] success: set];
    
}
/*
+ (NSDictionary *)get:(NSString *)url{
    NSString *normalized_url = [url lowercaseString];
    return [[NSUserDefaults standardUserDefaults] objectForKey:normalized_url];
}
 */
- (void)set{
    if([[self.options description] containsString:@"{{"] && [[self.options description] containsString:@"}}"]){
        [[Jason client] error];
        return;
    }
    
    @try {
        NSString *normalized_url = [self.VC.url lowercaseString];
        NSDictionary *to_set = [[NSUserDefaults standardUserDefaults] objectForKey:normalized_url];
        NSMutableDictionary *mutated;
        if(to_set && to_set.count > 0){
            mutated = [to_set mutableCopy];
            for(NSString *key in self.options){
                mutated[key] = self.options[key];
            }
        } else {
            mutated = [self.options mutableCopy];
        }
        [[NSUserDefaults standardUserDefaults] setObject:mutated forKey:normalized_url];
        [[NSUserDefaults standardUserDefaults] synchronize];

        self.VC.current_cache = mutated;
        [[Jason client] success: mutated];
    } @catch (NSException *e){
        [[Jason client] error];
    }
    
}
@end
