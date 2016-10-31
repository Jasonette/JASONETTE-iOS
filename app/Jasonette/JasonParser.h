//
//  JasonParser.h
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "Jason.h"
#import "RussianDollView.h"
#import <JavaScriptCore/JavaScriptCore.h>

@interface JasonParser : NSObject
@property (nonatomic, strong) NSDictionary *options;
+ (NSDictionary *)parse: (NSDictionary *)data with: (id)parser;
+ (NSDictionary *)parse: (NSDictionary *)data type: (NSString *) type with: (id)parser;

@end
