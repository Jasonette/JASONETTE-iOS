//
//  JasonTextareaComponent.m
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import "JasonTextareaComponent.h"

@implementation JasonTextareaComponent
+ (UIView *)build: (SZTextView *)component withJSON: (NSDictionary *)json withOptions: (NSDictionary *)options{
    if(!component){
        CGRect frame = CGRectMake(0,0,[[UIScreen mainScreen] bounds].size.width, 50);
        component = [[SZTextView alloc] initWithFrame:frame];
    }
    
    NSDictionary *style = json[@"style"];
    
    NSMutableDictionary *mutated_json = [json mutableCopy];
    if(style){
        if(!style[@"height"]){
            mutated_json[@"style"][@"height"] = @"100";
        }
    } else {
        mutated_json[@"style"] = @{@"height": @"100"};
    }
    
    NSMutableDictionary *payload = [[NSMutableDictionary alloc] init];
    if(mutated_json[@"name"]){
        payload[@"name"] = mutated_json[@"name"];
    }
    if(mutated_json[@"action"]){
        payload[@"action"] = mutated_json[@"action"];
    }
    component.payload = payload;

    
    
    
    if(options && options[@"value"]){
        component.text = options[@"value"];
    } else if(json && json[@"value"]){
        component.text = json[@"value"];
    }
    if(component.text){
        if(component.payload && component.payload[@"name"]){
            [self updateForm:@{component.payload[@"name"]: component.text}];
        }
    }

    
    component.delegate = [self self];
    
    
    // 1. Apply Common Style
    [self stylize:mutated_json component:component];
    
    // 2. Custom Style
    
    if(style[@"padding"]){
        int padding = [style[@"padding"] intValue];
        int lineFragmentPadding = component.textContainer.lineFragmentPadding;

        component.textContainerInset = UIEdgeInsetsMake(padding, padding-lineFragmentPadding, padding, padding-lineFragmentPadding);
    }
    
    if(mutated_json[@"placeholder"]){
        UIColor *placeholder_color;
        NSString *placeholder_raw_str = mutated_json[@"placeholder"];
        
        // Color
        if(style[@"placeholder_color"]){
            placeholder_color = [JasonHelper colorwithHexString:style[@"placeholder_color"] alpha:1.0];
        } else if(style[@"color:placeholder"]){
            placeholder_color = [JasonHelper colorwithHexString:style[@"color:placeholder"] alpha:1.0];
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
