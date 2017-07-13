//
//  RussianDollView.h
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import <Foundation/Foundation.h>

@protocol RussianDollView <NSObject>
@optional
@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) NSDictionary *data;
@property (nonatomic, strong) NSDictionary *options;
@property (nonatomic, strong) NSDictionary *parser;
@property (nonatomic, strong) NSDictionary *callback;
@property (nonatomic, strong) NSDictionary *nav;
@property (strong, nonatomic) NSDictionary *current_cache;

@property (strong, nonatomic) UIView *background;

@property (nonatomic, strong) NSString *mode;
@property (nonatomic, strong) NSString *from;
@property (nonatomic, assign) BOOL isModal;
@property (nonatomic, assign) BOOL contentLoaded;
@property (nonatomic, assign) BOOL touching;
@property (nonatomic, assign) BOOL fresh;
@property (nonatomic, assign) BOOL loading;
@property (nonatomic, assign) BOOL offline;
@property (nonatomic, assign) BOOL isFinal;

@property (strong, nonatomic) NSMutableDictionary *old_header;
@property (strong, nonatomic) NSMutableDictionary *old_footer;

@property (strong, nonatomic) NSDictionary *events;
@property (strong, nonatomic) NSDictionary *style;
@property (strong, nonatomic) NSDictionary *rendered;
@property (strong, nonatomic) NSDictionary *original;
@property (strong, nonatomic) NSMutableDictionary *menu;
@property (strong, nonatomic) NSMutableDictionary *form;
@property (strong, nonatomic) NSMutableDictionary *requires;
@property (strong, nonatomic) NSMutableDictionary *timers;
@property (strong, nonatomic) NSMutableDictionary *audios;
@property (nonatomic, strong) NSMutableArray *log;
@property (nonatomic, strong) NSMutableArray *playing;
- (void)right:(NSDictionary *)action;
- (void)left;
- (void)reload: (NSDictionary *)res final: (BOOL) final;
@end
