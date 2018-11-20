/* Copyright 2017 Urban Airship and Contributors */

#import "UIWebView+UAAdditions.h"
#import "UAUser.h"
#import "UAUtils.h"
#import "UAirship.h"

@implementation UIWebView (UAAdditions)

- (void)injectInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {

    switch (toInterfaceOrientation) {
        case UIDeviceOrientationPortrait:
            [self stringByEvaluatingJavaScriptFromString:@"window.__defineGetter__('orientation',function(){return 0;});window.onorientationchange();"];
            break;
        case UIDeviceOrientationLandscapeLeft:
            [self stringByEvaluatingJavaScriptFromString:@"window.__defineGetter__('orientation',function(){return 90;});window.onorientationchange();"];
            break;
        case UIDeviceOrientationLandscapeRight:
            [self stringByEvaluatingJavaScriptFromString:@"window.__defineGetter__('orientation',function(){return -90;});window.onorientationchange();"];
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            [self stringByEvaluatingJavaScriptFromString:@"window.__defineGetter__('orientation',function(){return 180;});window.onorientationchange();"];
            break;
        default:
            break;
    }
}

@end
