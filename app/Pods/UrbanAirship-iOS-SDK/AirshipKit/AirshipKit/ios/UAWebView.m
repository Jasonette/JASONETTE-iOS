/* Copyright 2017 Urban Airship and Contributors */

#import "UAWebView+Internal.h"
#import "UAirship.h"
#import "UAConfig.h"

// Had to create this class because Interface Builder doesn't directly support WKWebView
@implementation UAWebView

- (instancetype)initWithCoder:(NSCoder *)coder {
    // An initial frame for initialization must be set, but it will be overridden
    // below by the autolayout constraints set in interface builder.
    CGRect frame = [[UIScreen mainScreen] bounds];
    WKWebViewConfiguration *myConfiguration = [WKWebViewConfiguration new];
    
    self = [super initWithFrame:frame configuration:myConfiguration];
    
    // Apply constraints from interface builder.
    self.translatesAutoresizingMaskIntoConstraints = NO;
 
    return self;
}

@end
