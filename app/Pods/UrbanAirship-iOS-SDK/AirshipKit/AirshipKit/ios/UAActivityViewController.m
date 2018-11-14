/* Copyright 2017 Urban Airship and Contributors */

#import "UAActivityViewController.h"
#import "UAUtils.h"

@implementation UAActivityViewController

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (self.dismissalBlock) {
        self.dismissalBlock();
    }
}

- (CGRect)sourceRect {
    CGRect windowBounds = [UAUtils mainWindow].bounds;

    // Return a smaller rectangle by 25% on each axis, producing a 50% smaller rectangle inset.
    return CGRectInset(windowBounds, CGRectGetWidth(windowBounds)/4.0, CGRectGetHeight(windowBounds)/4.0);
}

// Called whenever a rotation is about to occur for iOS 8.0+ iPad
- (void)popoverPresentationController:(UIPopoverPresentationController *)popoverPresentationController
          willRepositionPopoverToRect:(inout CGRect *)rect
                               inView:(inout UIView *__autoreleasing *)view {
    // Override the passed rect with our desired dimensions
    *rect = [self sourceRect];
}

@end
