//
//  JasonComponentFactory.h
//  Jasonette
//
//  Copyright © 2016 gliechtenstein.
//  Copyright © 2019 Jasonelle Team.

#import <Foundation/Foundation.h>
#import "JasonComponentProtocol.h"
#import "JasonHelper.h"
#import <TTTAttributedLabel/TTTAttributedLabel.h>
#import "UIView+JasonComponentPayload.h"

@interface JasonComponentFactory : NSObject <UITextFieldDelegate, UITextViewDelegate>

@property (class, nonatomic, strong) NSMutableDictionary * imageLoaded;
@property (class, nonatomic, strong) NSMutableDictionary * stylesheet;

+ (UIView *)build:(UIView *)component
         withJSON:(NSDictionary *)child
      withOptions:(NSMutableDictionary *)options;

+ (NSMutableDictionary *)applyStylesheet:(NSDictionary *)item;

@end
