/* Copyright 2017 Urban Airship and Contributors */

#import "UADefaultMessageCenterListCell.h"
#import "UAInboxMessage.h"
#import "UAMessageCenterDateUtils.h"
#import "UADefaultMessageCenterStyle.h"

@implementation UADefaultMessageCenterListCell

- (void)setData:(UAInboxMessage *)message {
    self.date.text = [UAMessageCenterDateUtils formattedDateRelativeToNow:message.messageSent];
    self.title.text = message.title;
    self.unreadIndicator.hidden = !message.unread;
}

- (void)setStyle:(UADefaultMessageCenterStyle *)style {
    _style = style;

    BOOL hidden = !style.iconsEnabled;
    self.listIconView.hidden = hidden;

    // if the icon view is hidden, set a zero width constraint to allow related views to fill its space
    if (hidden) {
        UIImageView *iconView = self.listIconView;

        NSArray *zeroWidthConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[iconView(0)]"
                                                                                options:0
                                                                                metrics:nil
                                                                                  views:NSDictionaryOfVariableBindings(iconView)];

        [self.listIconView addConstraints:zeroWidthConstraints];
    }

    self.listIconView.hidden = !style.iconsEnabled;

    if (style.cellColor) {
        self.backgroundColor = style.cellColor;
    }

    if (style.cellHighlightedColor) {
        UIView *bgColorView = [[UIView alloc] init];
        bgColorView.backgroundColor = style.cellHighlightedColor;
        self.selectedBackgroundView = bgColorView;
    }

    if (style.cellTitleFont) {
        self.title.font = style.cellTitleFont;
    }

    if (style.cellTitleColor) {
        self.title.textColor = style.cellTitleColor;
    }

    if (style.cellTitleHighlightedColor) {
        self.title.highlightedTextColor = style.cellTitleHighlightedColor;
    }

    if (style.cellDateFont) {
        self.date.font = style.cellDateFont;
    }
    
    if (style.cellDateColor) {
        self.date.textColor = style.cellDateColor;
    }

    if (style.cellDateHighlightedColor) {
        self.date.highlightedTextColor = style.cellDateHighlightedColor;
    }

    if (style.cellTintColor) {
        self.tintColor = style.cellTintColor;
    }

    // Set unread indicator background color if explicitly provided, otherwise try to apply
    // tints lowest-level first, up the view hierarchy
    if (style.unreadIndicatorColor) {
        self.unreadIndicator.backgroundColor = style.unreadIndicatorColor;
    } else if (style.cellTintColor) {
        self.unreadIndicator.backgroundColor = self.style.cellTintColor;
    } else if (style.tintColor) {
        self.unreadIndicator.backgroundColor = self.style.tintColor;
    }
    
    // needed for retina displays because the unreadIndicator is configured to rasterize in
    // UADefaultMessageCenterListCell.xib via user-defined runtime attributes (layer.shouldRasterize)
    self.unreadIndicator.layer.rasterizationScale = [[UIScreen mainScreen] scale];
}

// Override to prevent the default implementation from covering up the unread indicator
 - (void)setSelected:(BOOL)selected animated:(BOOL)animated {
     if (selected) {
         UIColor *defaultColor = self.unreadIndicator.backgroundColor;
         [super setSelected:selected animated:animated];
         self.unreadIndicator.backgroundColor = defaultColor;
     } else {
         [super setSelected:selected animated:animated];
     }
}

// Override to prevent the default implementation from covering up the unread indicator
- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    if (highlighted) {
        UIColor *defaultColor = self.unreadIndicator.backgroundColor;
        [super setHighlighted:highlighted animated:animated];
        self.unreadIndicator.backgroundColor = defaultColor;

    } else {
        [super setHighlighted:highlighted animated:animated];
    }
}

@end
