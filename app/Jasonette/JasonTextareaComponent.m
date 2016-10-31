//
//  JasonTextareaComponent.m
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import "JasonTextareaComponent.h"

@implementation JasonTextareaComponent
+ (UIView *)build:(NSDictionary *)json withOptions:(NSDictionary *)options{
    CGRect frame = CGRectMake(0,0,[[UIScreen mainScreen] bounds].size.width, 50);
    SZTextView *component = [[SZTextView alloc] initWithFrame:frame];
    if(options && options[@"value"]){
        component.text = options[@"value"];
    }
    
    NSDictionary *style = json[@"style"];
    
    NSMutableDictionary *payload = [[NSMutableDictionary alloc] init];
    if(json[@"name"]){
        payload[@"name"] = json[@"name"];
    }
    if(json[@"action"]){
        payload[@"action"] = json[@"action"];
    }
    component.payload = payload;
    
    component.delegate = [self self];
    
    
    // 1. Apply Common Style
    [self stylize:json component:component];
    
    // 2. Custom Style
    if(json[@"placeholder"]){
        UIColor *placeholder_color;
        NSString *placeholder_raw_str = json[@"placeholder"];
        
        // Color
        if(style[@"placeholder_color"]){
            placeholder_color = [JasonHelper colorwithHexString:style[@"placeholder_color"] alpha:1.0];
        } else {
            placeholder_color = [UIColor grayColor];
        }
        
        

        NSMutableAttributedString *placeholderStr = [[NSMutableAttributedString alloc] initWithString:placeholder_raw_str];
        [placeholderStr addAttribute:NSForegroundColorAttributeName value:placeholder_color range:NSMakeRange(0,placeholderStr.length)];
        
        // Alignment
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc]init] ;
        if(style[@"align"]){
            NSDictionary *alignment_map = @{
                                            @"left": @(NSTextAlignmentLeft),
                                            @"center": @(NSTextAlignmentCenter),
                                            @"right": @(NSTextAlignmentRight),
                                            @"justified": @(NSTextAlignmentJustified),
                                            @"natural": @(NSTextAlignmentNatural)
                                            };
            [paragraphStyle setAlignment:[alignment_map[style[@"align"]] intValue]];
        } else {
            [paragraphStyle setAlignment:NSTextAlignmentCenter];
        }
        [placeholderStr addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, placeholderStr.length)];
        
        
        // Font
        NSString *font = @"HelveticaNeue";
        if(style[@"font"]){
            font = style[@"font"];
        }
        CGFloat size = 14.0;
        if(style[@"size"]){
            size = [style[@"size"] floatValue];
        }
        UIFont *f = [UIFont fontWithName:font size:size];
        [placeholderStr addAttribute:NSFontAttributeName value:f range:NSMakeRange(0, placeholderStr.length)];
        
        
        component.attributedPlaceholder = placeholderStr;
    }
    
    return component;
}

+ (void)textViewDidChange:(UITextView *)textView
{
    if(textView.payload && textView.payload[@"name"]){
        [self updateForm:@{textView.payload[@"name"]: textView.text}];
    }
    if(textView.payload && textView.payload[@"action"]){
        [[Jason client] call:textView.payload[@"action"]];
    }
}
+(BOOL)textViewShouldBeginEditing:(UITextView *)textView{
    if([textView isKindOfClass:[SZTextView class]]){
        [[NSNotificationCenter defaultCenter] postNotificationName:@"adjustViewForKeyboard" object:nil userInfo:@{@"view": textView}];
    }
    return YES;
}

@end
