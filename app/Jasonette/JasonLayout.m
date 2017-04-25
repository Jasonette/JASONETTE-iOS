//
//  JasonLayout.m
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import "JasonLayout.h"

@implementation JasonLayout
static NSMutableDictionary *_stylesheet = nil;


/**
 * create a layout if it doesn't exist.
 * reuse if it already exists
 **/
+ (NSDictionary *)fill: (UIStackView *)layout with:(NSDictionary *)item atIndexPath: (NSIndexPath *)indexPath withForm: (NSDictionary *)form{
    item = [self applyStylesheet:item];
    
    /////////////////////////////////////////////////////////////
    //
    // Styling
    //
    // Step 1. Default style
    NSMutableDictionary *style;
    if(form){
        style = [@{
                   @"padding": @"10"
                   } mutableCopy];
    } else {
        style = [@{
                   @"padding": @"0"
                   } mutableCopy];
    }
    
    
    // Step 2. JasonLayout Settings
    NSString *t = item[@"type"];
    if([t isEqualToString:@"vertical"]){
        style[@"distribution"] = @"fill";
        style[@"align"] = @"fill";
    } else if([t isEqualToString:@"horizontal"]){
        style[@"distribution"] = @"fill";
        style[@"align"] = @"top";
    } else {
        // default is vertical
        style[@"distribution"] = @"fill";
        style[@"align"] = @"fill";
    }
    
    // Step 4. If the element has an inline style, overwrite those attributes
    if(item[@"style"]){
        NSDictionary *inline_style = item[@"style"];
        for(NSString *key in inline_style){
            style[key] = inline_style[key];
        }
    }
    
    if([t isEqualToString:@"vertical"] || [t isEqualToString:@"horizontal"]){
        NSMutableDictionary *stylized_item = [item mutableCopy];
        stylized_item[@"style"] = style;
        layout = [JasonLayout fillChildLayout:layout with:stylized_item atIndexPath:indexPath withForm:form];
    } else {
        // This means it's a single element layout
        // And therefore needs to be wrapped inside a simple horizontal layout
        NSDictionary *wrappedItem = @{
                                      @"type": @"vertical",
                                      @"style": style,
                                      @"components": @[item]};
        layout = [JasonLayout fillChildLayout:layout with:wrappedItem atIndexPath:indexPath withForm:form];
    }
    layout.translatesAutoresizingMaskIntoConstraints = false;
    [layout setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
    [layout setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
    [layout setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
    [layout setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
    
    return @{ @"style": style, @"layout": layout };
    
}

+ (UIStackView *)fillChildLayout: (UIStackView*)layout with:(NSDictionary *)item atIndexPath: (NSIndexPath *)indexPath withForm: (NSDictionary *)form{
    NSArray *children = item[@"components"];
    
    // isBuilding = YES means we're building this layout for the first time.
    // Otherwise, we reuse the existing layout.
    
    BOOL isBuilding = YES;
    if(layout.arrangedSubviews && layout.arrangedSubviews.count > 0){
        isBuilding = NO;
    }
    NSInteger index = 0;
    for(NSDictionary *child in children){
        if(child && child.count > 0){
            NSString *type = child[@"type"];
            if([type isEqualToString:@"vertical"] || [type isEqualToString:@"horizontal"]){
                if(isBuilding){
                    UIStackView *el = [self fillChildLayout:[[UIStackView alloc] init] with:child atIndexPath:indexPath withForm: form];
                    [layout addArrangedSubview:el];
                } else {
                    UIStackView *view_to_replace = (UIStackView *)[layout.arrangedSubviews objectAtIndex:index];
                    [self fillChildLayout:view_to_replace with:child atIndexPath:indexPath withForm: form];
                }
            } else {
                NSMutableDictionary *options = [[NSMutableDictionary alloc] init];
                if ([child[@"type"] isEqualToString:@"image"]) {
                    // image component
                    options[@"indexPath"] = indexPath;
                }
                if ([child[@"type"] isEqualToString:@"button"] && child[@"url"]){
                    // image button
                    options[@"indexPath"] = indexPath;
                }
                if (form && child[@"name"]) {
                    // get the form value first
                    NSString *value = form[child[@"name"]];
                    
                    // if the value doesn't exist but the 'value' attribute exists, use that one
                    if(!value && child[@"value"]) {
                        value = child[@"value"];
                    }
                    
                    // If after all this, the value is still nil, just use an empty string
                    if (!value) value = @"";
                    
                    options[@"value"] = value;
                }
                options[@"parent"] = item[@"type"];
                
                UIView *el;
                
                // If we're building this layout, we pass in nil to JasonComponentFactory, and it will instantiate new components
                // Otherwise we look up the relevant component and pass it to JasonComponentFactory instead.
                if(isBuilding){
                    el = nil;
                } else {
                    el = [layout.arrangedSubviews objectAtIndex:index];
                }
                
                UIView *component = [JasonComponentFactory build:el withJSON: child withOptions:options];
                
                if([component isKindOfClass:[UIImageView class]]){
                    
                    if(child[@"style"] && (child[@"style"][@"width"] || child[@"style"][@"height"])){
                        // If the style contains style and either the width or the height,
                        // everything has been taken care of from the component level.
                        // So don't do anything
                    } else {
                        // If there's no style, we need to resize the images based on the
                        // fetched image dimension
                        
                        //  Exception handling for image dimension
                        //  If there's no width or height,
                        //      If the image is part of a vertical layout,
                        //          Fix the width and set the height based on ratio
                        //      If the image is part of a horizontal layout,
                        //          Fix the height and set the width based on ratio
                        CGFloat aspectRatioMult;
                        if(child[@"url"]){
                            if(JasonComponentFactory.imageLoaded[child[@"url"]]){
                                @try{
                                    CGSize size = [JasonComponentFactory.imageLoaded[child[@"url"]] CGSizeValue];
                                    if(size.width > 0 && size.height > 0){
                                        aspectRatioMult = (size.height / size.width);
                                    } else {
                                        aspectRatioMult = (((UIImageView *)component).image.size.height / ((UIImageView *)component).image.size.width);
                                    }
                                }
                                @catch (NSException *e){
                                    aspectRatioMult = (((UIImageView *)component).image.size.height / ((UIImageView *)component).image.size.width);
                                }
                            } else {
                                aspectRatioMult = (((UIImageView *)component).image.size.height / ((UIImageView *)component).image.size.width);
                            }
                            
                            
                            // The order is important
                            // Step 1. Add constraint
                            NSLayoutConstraint *new_constraint;
                            new_constraint = [NSLayoutConstraint constraintWithItem:component
                                                                          attribute:NSLayoutAttributeHeight
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:component
                                                                          attribute:NSLayoutAttributeWidth
                                                                         multiplier:aspectRatioMult
                                                                           constant:0];
                            [new_constraint setPriority:UILayoutPriorityRequired];
                            [component addConstraint:new_constraint];
                            
                            // Step 2. remove all constraints with "ratio" identifier
                            for(NSLayoutConstraint *constraint in component.constraints){
                                if([constraint.identifier isEqualToString:@"ratio"]){
                                    [component removeConstraint:constraint];
                                }
                            }
                            
                            // Step 3. Set the new_constraint's identifier "ratio"
                            new_constraint.identifier = @"ratio";
                            [component setNeedsLayout];
                        }
                        
                    }
                    
                    
                }
                if(isBuilding){
                    [layout addArrangedSubview:component];
                }
            }
        }
        index++;
    }
    
    if([item[@"type"] isEqualToString:@"vertical"]){
        [layout setAxis:UILayoutConstraintAxisVertical];
    }else if([item[@"type"] isEqualToString:@"horizontal"]){
        [layout setAxis:UILayoutConstraintAxisHorizontal];
    }
    
    NSDictionary *default_style = item[@"style"];
    
    NSMutableDictionary *style;
    if(default_style){
        style = [default_style mutableCopy];
    } else {
        style = [@{} mutableCopy];
    }
    
    
    if(!style[@"padding"]) style[@"padding"] = @"0";
    if(!style[@"background"]) style[@"background"] = @"#ffffff";
    if(!style[@"opacity"]) style[@"opacity"] = @"1";
    
    // Step 2. JasonLayout Settings
    NSString *t = item[@"type"];
    if([t isEqualToString:@"vertical"]){
        if(!style[@"distribution"]) style[@"distribution"] = @"fill";
        if(!style[@"align"]) style[@"align"] = @"fill";
    } else if([t isEqualToString:@"horizontal"]){
        if(!style[@"distribution"]) style[@"distribution"] = @"fill";
        if(!style[@"align"]) style[@"align"] = @"top";
    } else {
        // default is vertical
        if(!style[@"distribution"]) style[@"distribution"] = @"fill";
        if(!style[@"align"]) style[@"align"] = @"fill";
    }
    
    
    
    NSDictionary *alignment_map = @{
                                    @"fill": @(UIStackViewAlignmentFill),
                                    @"firstbaseline": @(UIStackViewAlignmentFirstBaseline),
                                    @"lastbaseline": @(UIStackViewAlignmentLastBaseline),
                                    @"left": @(UIStackViewAlignmentLeading),
                                    @"top": @(UIStackViewAlignmentTop),
                                    @"right": @(UIStackViewAlignmentTrailing),
                                    @"bottom": @(UIStackViewAlignmentBottom),
                                    @"center": @(UIStackViewAlignmentCenter)
                                    };
    if(style[@"align"]){
        UIStackViewAlignment alignment = [[alignment_map valueForKey:style[@"align"]] intValue];
        [layout setAlignment:alignment];
    }
    
    NSDictionary *distribution_map = @{
                                       @"fill": @(UIStackViewDistributionFill),
                                       @"equalsize": @(UIStackViewDistributionFillEqually),
                                       @"proportional": @(UIStackViewDistributionFillProportionally),
                                       @"equalspace": @(UIStackViewDistributionEqualSpacing),
                                       @"equalcentertocenter": @(UIStackViewDistributionEqualCentering)
                                       };
    if(style[@"distribution"]){
        layout.distribution = [[distribution_map valueForKey:style[@"distribution"]] intValue];
    }
    
    if(style[@"spacing"]){
        layout.spacing = [JasonHelper pixelsInDirection:item[@"type"] fromExpression:style[@"spacing"]];
    }
    
    NSString *padding_left;
    NSString *padding_right;
    NSString *padding_top;
    NSString *padding_bottom;
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
    layout.layoutMargins = UIEdgeInsetsMake([JasonHelper pixelsInDirection:@"vertical" fromExpression:padding_top], [JasonHelper pixelsInDirection:@"horizontal" fromExpression:padding_left], [JasonHelper pixelsInDirection:@"vertical" fromExpression:padding_bottom], [JasonHelper pixelsInDirection:@"horizontal" fromExpression:padding_right]);

    layout.layoutMargins = UIEdgeInsetsMake([padding_top floatValue], [padding_left floatValue], [padding_bottom floatValue], [padding_right floatValue]);
    layout.layoutMarginsRelativeArrangement = true;
    
    if(style && style[@"opacity"]){
        CGFloat opacity = [style[@"opacity"] floatValue];
        layout.alpha = opacity;
    } else {
        layout.alpha = 1.0;
    }
    
    
    return layout;
}

+ (NSMutableDictionary *)stylesheet{
    if(_stylesheet == nil){
        _stylesheet = [[NSMutableDictionary alloc] init];
    }
    return _stylesheet;
}
+ (void)setStylesheet:(NSMutableDictionary *)stylesheet{
    if (stylesheet != _stylesheet){
        _stylesheet = [stylesheet mutableCopy];
    }
}
// Common
+ (NSMutableDictionary *)applyStylesheet:(NSDictionary *)item{
    NSMutableDictionary *new_style = [[NSMutableDictionary alloc] init];
    if(item[@"class"]){
        NSString *class_string = item[@"class"];
        NSMutableArray *classes = [[class_string componentsSeparatedByString:@" "] mutableCopy];
        [classes removeObject:@""];
        for(NSString *c in classes){
            NSString *class_selector = c;
            NSDictionary *class_style = self.stylesheet[class_selector];
            for(NSString *key in [class_style allKeys]){
                new_style[key] = class_style[key];
            }
        }
        
    }
    if(item[@"style"]){
        for(NSString *key in item[@"style"]){
            new_style[key] = item[@"style"][key];
        }
    }
    
    NSMutableDictionary *stylized_item = [item mutableCopy];
    stylized_item[@"style"] = new_style;
    return stylized_item;
}

@end
