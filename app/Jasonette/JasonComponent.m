//
//  JasonComponent.m
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import "JasonComponent.h"

@implementation JasonComponent
+ (UIView *)build: (UIView*)component withJSON: (NSDictionary *)json withOptions: (NSDictionary *)options{
    // Override this
    return [[UIView alloc] init];
}
+ (void) stylize: (NSDictionary *)json component: (UIView *)component{
    NSDictionary *style = json[@"style"];
    if(style){
        // background
        if([component respondsToSelector:@selector(backgroundColor)]){
            if(style && style[@"background"]){
                NSString *colorHex = style[@"background"];
                if(colorHex){
                    component.backgroundColor = [JasonHelper colorwithHexString:colorHex alpha:1.0];
                } else {
                    component.backgroundColor = [UIColor clearColor];
                }
            } else {
                component.backgroundColor = [UIColor clearColor];
            }
        }
        
        // opacity
        if([component respondsToSelector:@selector(alpha)]){
            if(style && style[@"opacity"]){
                CGFloat opacity = [style[@"opacity"] floatValue];
                component.alpha = opacity;
            } else {
                component.alpha = 1.0;
            }
        }
        
        // color
        if(style[@"color"]){
            UIColor *color = [JasonHelper colorwithHexString:style[@"color"] alpha:1.0];
            if([component respondsToSelector:@selector(textColor)]){
                [component setValue:color forKey:@"textColor"];
            }else if([component respondsToSelector:@selector(tintColor)]){
                [component setValue:color forKey:@"tintColor"];
            }
        }
        
        // ratio
        if(style[@"ratio"]){
            NSLayoutConstraint *ratio_constraint = [NSLayoutConstraint constraintWithItem: component
                                                                         attribute:NSLayoutAttributeWidth
                                                                         relatedBy:NSLayoutRelationEqual
                                                                         toItem:component
                                                                         attribute:NSLayoutAttributeHeight
                                                                         multiplier:[JasonHelper parseRatio:style[@"ratio"]]
                                                                                 constant:0];
            ratio_constraint.identifier = @"ratio";
            [component addConstraint:ratio_constraint];
        }
        
        // width
        if(style[@"width"]){
            NSString *widthStr = style[@"width"];
            CGFloat width = [JasonHelper pixelsInDirection:@"horizontal" fromExpression:widthStr];

            // Look for any width constraint
            NSLayoutConstraint *constraint_to_update = nil;
            for(NSLayoutConstraint *constraint in component.constraints){
                if([constraint.identifier isEqualToString:@"width"]){
                    constraint_to_update = constraint;
                    break;
                }
            }
            
            // if the width constraint exists, we just update. Otherwise create and add.
            if(constraint_to_update){
                constraint_to_update.constant = width;
            } else {
                NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:component
                                                                              attribute:NSLayoutAttributeWidth
                                                                              relatedBy:NSLayoutRelationEqual
                                                                                 toItem:nil
                                                                              attribute:NSLayoutAttributeNotAnAttribute
                                                                             multiplier:1.0
                                                                               constant:width];
                constraint.identifier = @"width";
                [component addConstraint:constraint];
            }
            [component setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
            [component setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        }
        
        // height
        if(style[@"height"]){
            NSString * heightStr = style[@"height"];
            CGFloat height = [JasonHelper pixelsInDirection:@"vertical" fromExpression:heightStr];

            // Look for any height constraint
            NSLayoutConstraint *constraint_to_update = nil;
            for(NSLayoutConstraint *constraint in component.constraints){
                if([constraint.identifier isEqualToString:@"height"]){
                    constraint_to_update = constraint;
                    break;
                }
            }
            
            // if the height constraint exists, we just update. Otherwise create and add.
            if(constraint_to_update){
                constraint_to_update.constant = height;
            } else {
                NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:component
                                                                              attribute:NSLayoutAttributeHeight
                                                                              relatedBy:NSLayoutRelationEqual
                                                                                 toItem:nil
                                                                              attribute:NSLayoutAttributeNotAnAttribute
                                                                             multiplier:1.0
                                                                               constant:height];
                constraint.identifier = @"height";
                [component addConstraint:constraint];
            }            
            [component setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
            [component setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        }
        
        // corner radius
        if(style[@"corner_radius"]){
            CGFloat radius = [style[@"corner_radius"] floatValue];
            component.layer.cornerRadius = radius;
            component.clipsToBounds = YES;
        } else {
            component.layer.cornerRadius = 0;
        }
        
        // border width
        if(style[@"border_width"]){
            CGFloat borderWidth = [style[@"border_width"] floatValue];
            component.layer.borderWidth = borderWidth;
        } else {
            component.layer.borderWidth = 0;
        }
        
        // border color
        if(style[@"border_color"]){
            UIColor *color = [JasonHelper colorwithHexString:style[@"border_color"] alpha:1.0];
            component.layer.borderColor = color.CGColor;
        } else {
            component.layer.borderColor = nil;
        }
        
        // text styling
    }
    [self stylize:json text:component];
    
}
+ (void)stylize:(NSDictionary *)json text:(UIView *)el{
    NSDictionary *style = json[@"style"];
    if(style){
        
        
        // Alignment
        if(style[@"align"]){
            NSDictionary *alignment_map = @{
                                            @"left": @(NSTextAlignmentLeft),
                                            @"center": @(NSTextAlignmentCenter),
                                            @"right": @(NSTextAlignmentRight),
                                            @"justified": @(NSTextAlignmentJustified),
                                            @"natural": @(NSTextAlignmentNatural)
                                            };
            
     
            if([el respondsToSelector:@selector(textAlignment)]){
                NSTextAlignment align = [alignment_map[style[@"align"]] intValue];
                if([el isKindOfClass:[UITextView class]]){
                    ((UITextView *)el).textAlignment = align;
                } else if([el isKindOfClass:[UITextField class]]){
                    ((UITextField *)el).textAlignment = align;
                } else if([el isKindOfClass:[UILabel class]]){
                    ((UILabel *)el).textAlignment = align;
                }
            }
        }
        
        
        if(style[@"autocorrect"]){
            if([el isKindOfClass:[UITextView class]]){
                ((UITextView *)el).autocorrectionType = UITextAutocorrectionTypeYes;
            }
            if([el isKindOfClass:[UITextField class]]){
                ((UITextField *)el).autocorrectionType = UITextAutocorrectionTypeYes;
            }
        } else {
            if([el isKindOfClass:[UITextView class]]){
                ((UITextView *)el).autocorrectionType = UITextAutocorrectionTypeNo;
            }
            if([el isKindOfClass:[UITextField class]]){
                ((UITextField *)el).autocorrectionType = UITextAutocorrectionTypeNo;
            }
        }
        
        if(style[@"autocapitalize"]){
            if([el isKindOfClass:[UITextView class]]){
                ((UITextView *)el).autocapitalizationType = UITextAutocapitalizationTypeSentences;
            }
            if([el isKindOfClass:[UITextField class]]){
                ((UITextField *)el).autocapitalizationType = UITextAutocapitalizationTypeSentences;
            }
        } else {
            if([el isKindOfClass:[UITextView class]]){
                ((UITextView *)el).autocapitalizationType = UITextAutocapitalizationTypeNone;
            }
            if([el isKindOfClass:[UITextField class]]){
                ((UITextField *)el).autocapitalizationType = UITextAutocapitalizationTypeNone;
            }
        }
        
        if(style[@"spellcheck"]){
            if([el isKindOfClass:[UITextView class]]){
                ((UITextView *)el).spellCheckingType = UITextSpellCheckingTypeYes;
            }
            if([el isKindOfClass:[UITextField class]]){
                ((UITextField *)el).spellCheckingType = UITextSpellCheckingTypeYes;
            }
        } else {
            if([el isKindOfClass:[UITextView class]]){
                ((UITextView *)el).spellCheckingType = UITextSpellCheckingTypeNo;
            }
            if([el isKindOfClass:[UITextField class]]){
                ((UITextField *)el).spellCheckingType = UITextSpellCheckingTypeNo;
            }
        }
        
        if([el isKindOfClass:[UILabel class]] && [el respondsToSelector:@selector(textInsets)]){

            // Padding Handling
            NSString *padding_left = @"0";
            NSString *padding_right = @"0";
            NSString *padding_top = @"0";
            NSString *padding_bottom = @"0";
            if(style[@"padding"]){
                NSString *padding = style[@"padding"];
                padding_left = padding;
                padding_top = padding;
                padding_right = padding;
                padding_bottom = padding;
            }
            if(style[@"padding_left"]) padding_left = style[@"padding_left"];
            if(style[@"padding_right"]) padding_right = style[@"padding_right"];
            if(style[@"padding_top"]) padding_top = style[@"padding_top"];
            if(style[@"padding_bottom"]) padding_bottom = style[@"padding_bottom"];
            ((TTTAttributedLabel*)el).textInsets = UIEdgeInsetsMake([JasonHelper pixelsInDirection:@"vertical" fromExpression:padding_top], [JasonHelper pixelsInDirection:@"horizontal" fromExpression:padding_left], [JasonHelper pixelsInDirection:@"vertical" fromExpression:padding_bottom], [JasonHelper pixelsInDirection:@"horizontal" fromExpression:padding_right]);

            ((TTTAttributedLabel *)el).lineBreakMode = NSLineBreakByTruncatingTail;
        }
        
        // Font
        NSString *font;
        if(style[@"font"]){
            font = style[@"font"];
        }
        CGFloat size = 14.0;
        if(style[@"size"]){
            size = [style[@"size"] floatValue];
        }
        
        UIFont *f;
        if(font){
            f = [UIFont fontWithName:font size:size];
        } else {
            f = [UIFont systemFontOfSize:size];
        }
        
        if([el respondsToSelector:@selector(font)]){
            [el setValue:f forKey:@"font"];
        }
        
        // A hack for handling TTTAttributedLabel BUG
        // The text MUST be set AFTER setting the font.
        // Therefore we need to set the text one more time here.
        if([el isKindOfClass:[UILabel class]]){
            if(json[@"text"]){
                [el setValue:json[@"text"] forKey:@"text"];
            }
        }
    }
}
+ (void)updateForm:(NSDictionary *)kv{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"updateForm" object:nil userInfo:kv];
}
@end
