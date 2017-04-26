//
//  JasonTextfieldComponent.m
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import "JasonTextfieldComponent.h"

@implementation JasonTextfieldComponent
+ (UIView *)build: (UITextField *)component withJSON: (NSDictionary *)json withOptions: (NSDictionary *)options{
    if(!component){
        CGRect frame = CGRectMake(0,0,[[UIScreen mainScreen] bounds].size.width, 50);
        component = [[UITextField alloc] initWithFrame:frame];
    }
    
    NSMutableDictionary *payload = [[NSMutableDictionary alloc] init];
    if(json[@"name"]){
        payload[@"name"] = json[@"name"];
    }
    if(json[@"action"]){
        payload[@"action"] = json[@"action"];
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
    
    
    [component addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    
    // 1. Apply Common Style
    [self stylize:json component:component];
    
    // 2. Custom Style
    NSDictionary *style = json[@"style"];
    
    if(style[@"padding"]){
        int padding = [style[@"padding"] intValue];
        component.layer.sublayerTransform = CATransform3DMakeTranslation(padding, 0, 0);
    }
 
    
    
    if(style){
        if(style[@"secure"] && [style[@"secure"] boolValue]){
            ((UITextField *)component).secureTextEntry = YES;
        } else {
            ((UITextField *)component).secureTextEntry = NO;
        }
    }
    if(json[@"placeholder"]){
        UIColor *placeholder_color;
        NSString *placeholder_raw_str = json[@"placeholder"];
        
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
+(BOOL)textFieldShouldBeginEditing:(UITextField*)textField {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"adjustViewForKeyboard" object:nil userInfo:@{@"view": textField}];
    return YES;
}
+ (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    return YES;
}
+ (void)textFieldDidChange:(UITextField *)textField{
    if(textField.payload && textField.payload[@"name"]){
      [self updateForm:@{textField.payload[@"name"]: textField.text}];
    }
    if(textField.payload && textField.payload[@"action"]){
        [[Jason client] call:textField.payload[@"action"]];
    }
}

@end
