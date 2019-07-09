//
//  JasonComponent.m
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//  Copyright © 2019 Jasonelle Team.

#import "JasonComponent.h"
#import <DTFoundation/DTLog.h>

@implementation JasonComponent

+ (UIView *)build:(UIView *)component
         withJSON:(NSDictionary *)json
      withOptions:(NSDictionary *)options
{
    DTLogWarning (@"The component should overide this method %@", json);
    return [UIView new];
}

+ (void)stylize:(NSDictionary *)json
      component:(UIView *)component
{
    NSDictionary * style = json[@"style"];

    if (style) {
        DTLogInfo (@"Component Will Start to Apply Styles");
        DTLogDebug (@"Applying Styles To Component %@", json);

        // background
        if ([component respondsToSelector:@selector(backgroundColor)]) {
            component.backgroundColor = [UIColor clearColor];

            if (style && style[@"background"]) {
                DTLogInfo (@"Applying Background");
                NSString * colorHex = style[@"background"];

                if (colorHex) {
                    component.backgroundColor = [JasonHelper
                                                 colorwithHexString:colorHex
                                                              alpha:1.0];
                }
            }
        }

        // opacity
        if ([component respondsToSelector:@selector(alpha)]) {
            component.alpha = 1.0;
            DTLogInfo (@"Applying Opacity");

            if (style && style[@"opacity"]) {
                CGFloat opacity = [style[@"opacity"] floatValue];
                component.alpha = opacity;
            }
        }

        // color
        if (style[@"color"]) {
            UIColor * color = [JasonHelper
                               colorwithHexString:style[@"color"]
                                            alpha:1.0];

            if ([component respondsToSelector:@selector(textColor)]) {
                DTLogInfo (@"Applying Text Color");
                [component setValue:color forKey:@"textColor"];
            } else if ([component respondsToSelector:@selector(tintColor)]) {
                DTLogInfo (@"Applying Tint Color");
                [component setValue:color forKey:@"tintColor"];
            }
        }

        // ratio
        if (style[@"ratio"]) {
            NSLayoutConstraint * ratio_constraint = [NSLayoutConstraint constraintWithItem:component
                                                                                 attribute:NSLayoutAttributeWidth
                                                                                 relatedBy:NSLayoutRelationEqual
                                                                                    toItem:component
                                                                                 attribute:NSLayoutAttributeHeight
                                                                                multiplier:[JasonHelper
                                                                 parseRatio:style[@"ratio"]]
                                                                                  constant:0];
            ratio_constraint.identifier = @"ratio";
            DTLogInfo (@"Applying Ratio");
            [component addConstraint:ratio_constraint];
        }

        // width
        if (style[@"width"]) {
            NSString * widthStr = style[@"width"];

            DTLogInfo (@"Applying Width %@", widthStr);

            CGFloat width = [JasonHelper
                             pixelsInDirection:@"horizontal"
                                fromExpression:widthStr];

            // Look for any width constraint
            NSLayoutConstraint * constraint_to_update = nil;

            for (NSLayoutConstraint * constraint in component.constraints) {
                if ([constraint.identifier isEqualToString:@"width"]) {
                    constraint_to_update = constraint;
                    break;
                }
            }

            // if the width constraint exists, we just update. Otherwise create and add.
            if (constraint_to_update) {
                constraint_to_update.constant = width;
            } else {
                NSLayoutConstraint * constraint = [NSLayoutConstraint constraintWithItem:component
                                                                               attribute:NSLayoutAttributeWidth
                                                                               relatedBy:NSLayoutRelationEqual
                                                                                  toItem:nil
                                                                               attribute:NSLayoutAttributeNotAnAttribute
                                                                              multiplier:1.0
                                                                                constant:width];
                constraint.identifier = @"width";
                [component addConstraint:constraint];
            }

            [component setContentHuggingPriority:UILayoutPriorityRequired
                                         forAxis:UILayoutConstraintAxisHorizontal];

            [component setContentCompressionResistancePriority:UILayoutPriorityRequired
                                                       forAxis:UILayoutConstraintAxisHorizontal];
        }

        // height
        if (style[@"height"]) {
            NSString * heightStr = style[@"height"];

            DTLogInfo (@"Applying Hieght %@", heightStr);

            CGFloat height = [JasonHelper
                              pixelsInDirection:@"vertical"
                                 fromExpression:heightStr];

            // Look for any height constraint
            NSLayoutConstraint * constraint_to_update = nil;

            for (NSLayoutConstraint * constraint in component.constraints) {
                if ([constraint.identifier isEqualToString:@"height"]) {
                    constraint_to_update = constraint;
                    break;
                }
            }

            // if the height constraint exists, we just update. Otherwise create and add.
            if (constraint_to_update) {
                constraint_to_update.constant = height;
            } else {
                NSLayoutConstraint * constraint = [NSLayoutConstraint constraintWithItem:component
                                                                               attribute:NSLayoutAttributeHeight
                                                                               relatedBy:NSLayoutRelationEqual
                                                                                  toItem:nil
                                                                               attribute:NSLayoutAttributeNotAnAttribute
                                                                              multiplier:1.0
                                                                                constant:height];
                constraint.identifier = @"height";
                [component addConstraint:constraint];
            }

            [component setContentHuggingPriority:UILayoutPriorityRequired
                                         forAxis:UILayoutConstraintAxisVertical];

            [component setContentCompressionResistancePriority:UILayoutPriorityRequired
                                                       forAxis:UILayoutConstraintAxisVertical];
        }

        // corner radius
        component.layer.cornerRadius = 0;

        if (style[@"corner_radius"]) {
            DTLogInfo (@"Applying Corner Radius %@", style[@"corner_radius"]);

            CGFloat radius = [style[@"corner_radius"] floatValue];
            component.layer.cornerRadius = radius;
            component.clipsToBounds = YES;
        }

        // border width
        component.layer.borderWidth = 0;

        if (style[@"border_width"]) {
            DTLogInfo (@"Applying Border Width %@", style[@"border_width"]);
            CGFloat borderWidth = [style[@"border_width"] floatValue];
            component.layer.borderWidth = borderWidth;
        }

        // border color
        component.layer.borderColor = nil;

        if (style[@"border_color"]) {
            DTLogInfo (@"Applying Border Color");
            UIColor * color = [JasonHelper
                               colorwithHexString:style[@"border_color"]
                                            alpha:1.0];

            component.layer.borderColor = color.CGColor;
        }
    }

    DTLogInfo (@"Applied Standard Styles To Component");
    // text styling
    [self stylize:json text:component];
}

+ (void)stylize:(NSDictionary *)json
           text:(UIView *)el
{
    DTLogInfo (@"Begin Applying Styles for Text");
    DTLogDebug (@"Applying Styles for Text To Component %@", json);

    NSDictionary * style = json[@"style"];

    if (style) {
        // Alignment
        if (style[@"align"]) {
            DTLogInfo (@"Applying Align %@", style[@"align"]);

            NSDictionary * alignment_map = @{
                    @"left": @(NSTextAlignmentLeft),
                    @"center": @(NSTextAlignmentCenter),
                    @"right": @(NSTextAlignmentRight),
                    @"justified": @(NSTextAlignmentJustified),
                    @"natural": @(NSTextAlignmentNatural)
            };

            if ([el respondsToSelector:@selector(textAlignment)]) {
                NSTextAlignment align = [alignment_map[style[@"align"]] intValue];

                if ([el isKindOfClass:[UITextView class]]) {
                    ((UITextView *)el).textAlignment = align;
                } else if ([el isKindOfClass:[UITextField class]]) {
                    ((UITextField *)el).textAlignment = align;
                } else if ([el isKindOfClass:[UILabel class]]) {
                    ((UILabel *)el).textAlignment = align;
                }
            }
        }

        if (style[@"autocorrect"]) {
            DTLogInfo (@"Applying Autocorrect On");

            if ([el isKindOfClass:[UITextView class]]) {
                ((UITextView *)el).autocorrectionType = UITextAutocorrectionTypeYes;
            }

            if ([el isKindOfClass:[UITextField class]]) {
                ((UITextField *)el).autocorrectionType = UITextAutocorrectionTypeYes;
            }
        } else {
            DTLogInfo (@"Applying Autocorrect Off");

            if ([el isKindOfClass:[UITextView class]]) {
                ((UITextView *)el).autocorrectionType = UITextAutocorrectionTypeNo;
            }

            if ([el isKindOfClass:[UITextField class]]) {
                ((UITextField *)el).autocorrectionType = UITextAutocorrectionTypeNo;
            }
        }

        if (style[@"autocapitalize"]) {
            DTLogInfo (@"Applying Autocapitalize On");

            if ([el isKindOfClass:[UITextView class]]) {
                ((UITextView *)el).autocapitalizationType = UITextAutocapitalizationTypeSentences;
            }

            if ([el isKindOfClass:[UITextField class]]) {
                ((UITextField *)el).autocapitalizationType = UITextAutocapitalizationTypeSentences;
            }
        } else {
            DTLogInfo (@"Applying Autocapitalize Off");

            if ([el isKindOfClass:[UITextView class]]) {
                ((UITextView *)el).autocapitalizationType = UITextAutocapitalizationTypeNone;
            }

            if ([el isKindOfClass:[UITextField class]]) {
                ((UITextField *)el).autocapitalizationType = UITextAutocapitalizationTypeNone;
            }
        }

        if (style[@"spellcheck"]) {
            DTLogInfo (@"Applying SpellCheck On");

            if ([el isKindOfClass:[UITextView class]]) {
                ((UITextView *)el).spellCheckingType = UITextSpellCheckingTypeYes;
            }

            if ([el isKindOfClass:[UITextField class]]) {
                ((UITextField *)el).spellCheckingType = UITextSpellCheckingTypeYes;
            }
        } else {
            DTLogInfo (@"Applying SpellCheck Off");

            if ([el isKindOfClass:[UITextView class]]) {
                ((UITextView *)el).spellCheckingType = UITextSpellCheckingTypeNo;
            }

            if ([el isKindOfClass:[UITextField class]]) {
                ((UITextField *)el).spellCheckingType = UITextSpellCheckingTypeNo;
            }
        }

        if ([el isKindOfClass:[UILabel class]] && [el respondsToSelector:@selector(textInsets)]) {
            DTLogInfo (@"Applying Padding");

            // Padding Handling
            NSString * padding_left = @"0";
            NSString * padding_right = @"0";
            NSString * padding_top = @"0";
            NSString * padding_bottom = @"0";

            if (style[@"padding"]) {
                NSString * padding = style[@"padding"];
                padding_left = padding;
                padding_top = padding;
                padding_right = padding;
                padding_bottom = padding;
            }

            if (style[@"padding_left"]) {
                padding_left = style[@"padding_left"];
            }

            if (style[@"padding_right"]) {
                padding_right = style[@"padding_right"];
            }

            if (style[@"padding_top"]) {
                padding_top = style[@"padding_top"];
            }

            if (style[@"padding_bottom"]) {
                padding_bottom = style[@"padding_bottom"];
            }

            ((TTTAttributedLabel *)el).textInsets = UIEdgeInsetsMake ([JasonHelper
                                                                       pixelsInDirection:@"vertical"
                                                                          fromExpression:padding_top],

                                                                      [JasonHelper
                                                                       pixelsInDirection:@"horizontal"
                                                                          fromExpression:padding_left],

                                                                      [JasonHelper
                                                                       pixelsInDirection:@"vertical"
                                                                          fromExpression:padding_bottom],

                                                                      [JasonHelper
                                                                       pixelsInDirection:@"horizontal"
                                                                          fromExpression:padding_right]
                                                                      );

            ((TTTAttributedLabel *)el).lineBreakMode = NSLineBreakByTruncatingTail;
        }

        // Font
        NSString * font;

        if (style[@"font"]) {
            DTLogInfo (@"Applying Font");
            font = style[@"font"];
        }

        CGFloat size = 14.0;

        if (style[@"size"]) {
            DTLogInfo (@"Applying Size");
            size = [style[@"size"] floatValue];
        }

        UIFont * f;

        if (font) {
            f = [UIFont fontWithName:font size:size];
        } else {
            f = [UIFont systemFontOfSize:size];
        }

        if ([el respondsToSelector:@selector(font)]) {
            [el setValue:f forKey:@"font"];
        }

        // A hack for handling TTTAttributedLabel BUG
        // The text MUST be set AFTER setting the font.
        // Therefore we need to set the text one more time here.
        if ([el isKindOfClass:[UILabel class]]) {
            if (json[@"text"]) {
                DTLogInfo (@"ReSetting Text");
                [el setValue:[json[@"text"] description] forKey:@"text"];
            }
        }
    }

    DTLogInfo (@"End Applying Styles for Text");
}

+ (void)updateForm:(NSDictionary *)kv
{
    DTLogInfo (@"Updating Form");
    DTLogDebug (@"Updating Form %@", kv);
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"updateForm"
                   object:nil
                 userInfo:kv];
}

@end
