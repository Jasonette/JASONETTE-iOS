//
//  JasonLabelComponent.m
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//  Copyright © 2019 Jasonelle Team.

#import "JasonLabelComponent.h"
#import <DTFoundation/DTLog.h>

@implementation JasonLabelComponent

+ (UIView *)build:(TTTAttributedLabel *)component
         withJSON:(NSDictionary *)json
      withOptions:(NSDictionary *)options
{
    DTLogDebug (@"Creating label Component With JSON %@", json);

    if (!component) {
        component = (TTTAttributedLabel *)[[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
    }

    if (json) {
        // Enable automatic number of lines in label.
        component.numberOfLines = 0;

        if (json[@"text"] && ![json[@"text"] isEqual:[NSNull null]]) {
            component.text = [json[@"text"] description];
        } else {
            DTLogWarning (@"Label component with empty text %@", json);
        }
    }

    // Apply Common Style
    [self stylize:json
        component :component];

    return component;
}

@end
