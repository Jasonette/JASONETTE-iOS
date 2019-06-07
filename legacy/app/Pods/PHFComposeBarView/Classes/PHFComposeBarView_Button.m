#import "PHFComposeBarView_Button.h"

@implementation PHFComposeBarView_Button

- (void)setHighlighted:(BOOL)highlighted {
    if (highlighted) {
        [self setAlpha:0.2f];
    } else {
        [UIView animateWithDuration:0.2
                              delay:0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             [self setAlpha:1.0f];
                         }
                         completion:NULL];
    }
}

@end
