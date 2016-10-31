#import "PHFComposeBarView_TextView.h"

@implementation PHFComposeBarView_TextView

// Only allow iOS to set the offset when the user scrolls or is selecting
// text. This is needed in order to suppress the animation when a line breaks.
// This animation is not present in the Messages.app. The scrolling to the
// correct position is handled in -scrollToCaretIfNeeded of the main view.
- (void)setContentOffset:(CGPoint)contentOffset {
    if ([self selectedRange].length || [self isTracking] || [self isDecelerating])
        [super setContentOffset:contentOffset];
}

// Expose the original -setContentOffset: method.
- (void)PHFComposeBarView_setContentOffset:(CGPoint)contentOffset {
    [super setContentOffset:contentOffset];
}

@end
