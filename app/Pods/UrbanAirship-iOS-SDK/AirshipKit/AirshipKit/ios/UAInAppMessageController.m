/* Copyright 2017 Urban Airship and Contributors */

#import "UAInAppMessageController+Internal.h"
#import "UAInAppMessage.h"
#import "UAUtils.h"
#import "UAInAppMessageButtonActionBinding.h"
#import "UAActionRunner+Internal.h"
#import "UAirship.h"
#import "UAInAppMessaging.h"
#import "UAInAppResolutionEvent+Internal.h"
#import "UAirship.h"
#import "UAAnalytics.h"
#import "UAInAppMessageControllerDefaultDelegate.h"

#define kUAInAppMessageMinimumLongPressDuration 0.2

// Don't detect a swipe unless the velocity is at least 100 points per second
#define kUAInAppMessageMinimumSwipeVelocity 100.0

@interface UAInAppMessageController ()

@property (nonatomic, strong) UAInAppMessage *message;
@property (nonatomic, strong) UIView *messageView;
@property (nonatomic, copy) void (^dismissalBlock)(UAInAppMessageController *);
@property (nonatomic, strong) NSDate *startDisplayDate;
@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizer;
@property (nonatomic, assign) BOOL swipeDetected;
@property (nonatomic, assign) BOOL tapDetected;
@property (nonatomic, assign) BOOL longPressDetected;
@property (nonatomic, assign) BOOL isShown;
@property (nonatomic, assign) BOOL isDismissed;

/**
 * A timer set for the duration of the message, after wich the view is dismissed.
 */
@property(nonatomic, strong) NSTimer *dismissalTimer;

/**
 * An array of dictionaries containing localized button titles and
 * action name/argument value bindings.
 */
@property(nonatomic, strong) NSArray *buttonActionBindings;

/**
 * A settable reference to self, so we can self-retain for the message
 * display duration.
 */
@property(nonatomic, strong) UAInAppMessageController *referenceToSelf;

@end

@implementation UAInAppMessageController

- (instancetype)initWithMessage:(UAInAppMessage *)message
                       delegate:(id<UAInAppMessageControllerDelegate>)delegate
                 dismissalBlock:(void (^)(UAInAppMessageController *))dismissalBlock {

    self = [super init];
    if (self) {
        self.message = message;
        self.buttonActionBindings = message.buttonActionBindings;
        self.userDelegate = delegate;
        self.defaultDelegate = [[UAInAppMessageControllerDefaultDelegate alloc] initWithMessage:message];
        self.dismissalBlock = dismissalBlock;
    }
    return self;
}

+ (instancetype)controllerWithMessage:(UAInAppMessage *)message
                             delegate:(id<UAInAppMessageControllerDelegate>)delegate
                       dismissalBlock:(void(^)(UAInAppMessageController *))dismissalBlock {

    return [[self alloc] initWithMessage:message delegate:delegate dismissalBlock:dismissalBlock];
}

// Delegate helper methods

- (UIView *)messageViewWithParentView:(UIView *)parentView {
    if ([self.userDelegate respondsToSelector:@selector(viewForMessage:parentView:)]) {
        return [self.userDelegate viewForMessage:self.message parentView:parentView];
    } else {
        return [self.defaultDelegate viewForMessage:self.message parentView:parentView];
    }
}

- (UIControl *)buttonAtIndex:(NSUInteger)index {
    if ([self.userDelegate respondsToSelector:@selector(messageView:buttonAtIndex:)]) {
        return [self.userDelegate messageView:self.messageView buttonAtIndex:index];
    } else {
        return [self.defaultDelegate messageView:self.messageView buttonAtIndex:index];
    }
}


// Optional delegate methods
- (void)handleTouchState:(BOOL)touchDown {
    // Only call our default delegate if the user delegate is not set, as our handling of touch state
    // will not work universally.
    if (self.userDelegate) {
        if ([self.userDelegate respondsToSelector:@selector(messageView:didChangeTouchState:)]) {
            [self.userDelegate messageView:self.messageView didChangeTouchState:touchDown];
        }
    } else {
        [self.defaultDelegate messageView:self.messageView didChangeTouchState:touchDown];
    }
}

- (void)animateInWithParentView:(UIView *)parentView completionHandler:(void (^)(void))completionHandler {
    if ([self.userDelegate respondsToSelector:@selector(messageView:animateInWithParentView:completionHandler:)]) {
        [self.userDelegate messageView:self.messageView animateInWithParentView:parentView completionHandler:completionHandler];
    } else if ([self.userDelegate respondsToSelector:@selector(viewForMessage:parentView:)]) {
        // Skip animation if user delegate is partially implemented because of constraints
        completionHandler();
    } else {
        [self.defaultDelegate messageView:self.messageView animateInWithParentView:parentView completionHandler:completionHandler];
    }
}

- (void)animateOutWithParentView:(UIView *)parentView completionHandler:(void (^)(void))completionHandler {
    if ([self.userDelegate respondsToSelector:@selector(messageView:animateOutWithParentView:completionHandler:)]) {
        [self.userDelegate messageView:self.messageView animateOutWithParentView:parentView completionHandler:completionHandler];
    } else if ([self.userDelegate respondsToSelector:@selector(viewForMessage:parentView:)]) {
        // Skip animation if user delegate is partially implemented because of constraints
        completionHandler();
    } else {
        [self.defaultDelegate messageView:self.messageView animateOutWithParentView:parentView completionHandler:completionHandler];
    }
}

/**
 * Signs self up for control events on the message view.
 * This method has the side effect of adding self as a target for
 * button, pan(swipe) and tap events.
 */
- (void)signUpForControlEventsWithMessageView:(UIView *)messageView parentView:(UIView *)parentView {
    // add a pan gesture recognizer for detecting swipes
    self.panGestureRecognizer  = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panWithGestureRecognizer:)];

    // don't get in the way of anything
    self.panGestureRecognizer.delaysTouchesBegan = NO;
    self.panGestureRecognizer.delaysTouchesEnded = NO;
    self.panGestureRecognizer.cancelsTouchesInView = NO;

    // add to the parent view
    [parentView addGestureRecognizer:self.panGestureRecognizer];

    // add tap and long press gesture recognizers if an onClick action is present in the model
    if (self.message.onClick) {
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapWithGestureRecognizer:)];
        tapGestureRecognizer.delegate = self;
        [messageView addGestureRecognizer:tapGestureRecognizer];


        UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressWithGestureRecognizer:)];
        longPressGestureRecognizer.minimumPressDuration = kUAInAppMessageMinimumLongPressDuration;
        longPressGestureRecognizer.delegate = self;

        [messageView addGestureRecognizer:longPressGestureRecognizer];
    }

    UIControl *button1 = [self buttonAtIndex:0];
    UIControl *button2 = [self buttonAtIndex:1];

    // sign up for button touch events
    [button1 addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [button2 addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)scheduleDismissalTimer {
    self.dismissalTimer = [NSTimer timerWithTimeInterval:self.message.duration
                                                  target:self
                                                selector:@selector(timedOut)
                                                userInfo:nil
                                                 repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:self.dismissalTimer forMode:NSDefaultRunLoopMode];
}

- (void)invalidateDismissalTimer {
    [self.dismissalTimer invalidate];
}

- (void)listenForAppStateTransitions {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActive)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:[UIApplication sharedApplication]];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillResignActive)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:[UIApplication sharedApplication]];
}

- (void)resignAppStateTransitions {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)isShowing {
    return self.isShown && !self.isDismissed;
}

- (BOOL)show {

    if (self.isShown) {
        UA_LDEBUG(@"In-app message has already been displayed");
        return NO;
    }

    // use the main app window as the parent view
    UIView *parentView = [UAUtils mainWindow];

    // if a parent view could not be found, bail early.
    if (!parentView) {
        UA_LDEBUG(@"Unable to find parent view, canceling in-app message display");
        return NO;
    }

    // retain self for the duration of the message display, so that avoiding premature deallocation
    // is not directly dependent on arbitrary container/object lifecycles
    self.referenceToSelf = self;

    UIView *messageView = [self messageViewWithParentView:parentView];

    // force a layout in case autolayout is used, so that the view's geometry is defined
    [messageView layoutIfNeeded];

    self.messageView = messageView;

    [self signUpForControlEventsWithMessageView:messageView parentView:parentView];

    self.isShown = YES;

    // animate the message view into place, starting the timer when the animation has completed
    [self animateInWithParentView:parentView completionHandler:^{
        [self listenForAppStateTransitions];
        [self scheduleDismissalTimer];
        self.startDisplayDate = [NSDate date];
    }];

    return YES;
}

- (void)dismissWithRunloopDelay {
    // dispatch with a delay of zero to postpone the block by a runloop cycle, so that
    // the animation isn't disrupted

    dispatch_async(dispatch_get_main_queue(), ^{
        [self animateOutWithParentView:self.messageView.superview completionHandler:^{
            if (self.dismissalBlock) {
                self.dismissalBlock(self);
            }

            [self finishTeardown];
        }];
    });
}

/**
 * Finalizes dismissal by removing the message view from its
 * parent, and releasing the reference to self
 */
- (void)finishTeardown {

    [self.messageView removeFromSuperview];

    self.messageView = nil;

    // release self
    self.referenceToSelf = nil;
}

/**
 * Prepares the message view for dismissal by disabling interaction, removing
 * the pan gesture recognizer and releasing resources that can be disposed of
 * prior to starting the dismissal animation.
 */
- (void)beginTeardown {
    // prevent additional user interaction once the view starts to go away
    self.messageView.userInteractionEnabled = NO;

    // remove our pan gesture recognizer from the parent
    [self.messageView.superview removeGestureRecognizer:self.panGestureRecognizer];

    // invalidate the timer
    [self.dismissalTimer invalidate];
    self.dismissalTimer = nil;

    // remove ourself as an observer of app state
    [self resignAppStateTransitions];
}

/**
 * Releases all resources. This method can be safely called
 * in dealloc as a protection against unexpected early release.
 */
- (void)teardown {
    [self beginTeardown];
    [self finishTeardown];
}

- (void)dismiss {
    if (self.isDismissed) {
        UA_LDEBUG(@"In-app message has already been dismissed");
        return;
    }

    self.isDismissed = YES;

    [self beginTeardown];
    [self dismissWithRunloopDelay];
}

- (void)applicationDidBecomeActive {
    [self scheduleDismissalTimer];
    self.startDisplayDate = [NSDate date];
}

- (void)applicationWillResignActive {
    [self invalidateDismissalTimer];
}

- (void)panWithGestureRecognizer:(UIPanGestureRecognizer *)recognizer {

    // if the gesture is finished
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        CGPoint velocity = [recognizer velocityInView:self.messageView.superview];
        CGPoint translation = [recognizer translationInView:self.messageView.superview];
        CGPoint touchPoint = [recognizer locationInView:self.messageView];

        // absolute velocity regardless of direction
        CGFloat absoluteVelocityX = fabs(velocity.x);
        CGFloat absoluteVelocityY = fabs(velocity.y);

        // if the y-axis velocity exceeds the threshold and exceeds the x-axis velocity
        // (i.e. if the touch is moving fast enough, and more up/down than left/right)
        if (absoluteVelocityY > kUAInAppMessageMinimumSwipeVelocity && absoluteVelocityY > absoluteVelocityX) {
            // if the gesture ended within the bounds of our message view
            if (CGRectContainsPoint(self.messageView.bounds, touchPoint)) {
                // if the y axis translation and message position line up
                // (i.e. if the swipe is moving in the right direction)
                if ((translation.y > 0 && self.message.position == UAInAppMessagePositionBottom) ||
                    (translation.y < 0 && self.message.position == UAInAppMessagePositionTop)) {
                    if (!self.tapDetected && !self.longPressDetected) {
                        self.swipeDetected = YES;

                        //UAInAppMessagingDelegate messageDismissed
                        id<UAInAppMessagingDelegate> strongDelegate = [UAirship inAppMessaging].messagingDelegate;
                        if ([strongDelegate respondsToSelector:@selector(messageDismissed:timeout:)]) {
                            [strongDelegate messageDismissed:self.message timeout:NO];
                        };

                        // dismiss and add the appropriate analytics event
                        [self dismiss];
                        UAInAppResolutionEvent *event = [UAInAppResolutionEvent dismissedResolutionWithMessage:self.message
                                                                                               displayDuration:[self displayDuration]];
                        [[UAirship shared].analytics addEvent:event];
                    }
                }
            }
        }

    }
}

/**
 * Called when a message is clicked.
 */
- (void)messageClicked {
    //UAInAppMessagingDelegate messageTapped
    id<UAInAppMessagingDelegate> strongDelegate = [UAirship inAppMessaging].messagingDelegate;
    if ([strongDelegate respondsToSelector:@selector(messageTapped:)]) {
        [strongDelegate messageTapped:self.message];
    };

    UAInAppResolutionEvent *event = [UAInAppResolutionEvent messageClickedResolutionWithMessage:self.message
                                                                                displayDuration:[self displayDuration]];
    [[UAirship shared].analytics addEvent:event];


    [UAActionRunner runActionsWithActionValues:self.message.onClick
                                     situation:UASituationForegroundInteractiveButton
                                      metadata:nil
                             completionHandler:nil];
}

/**
 * Called when the view times out.
 */
- (void)timedOut {
    [self dismiss];

    //UAInAppMessagingDelegate messageDismissed by timeout
    id<UAInAppMessagingDelegate> strongDelegate = [UAirship inAppMessaging].messagingDelegate;
    if ([strongDelegate respondsToSelector:@selector(messageDismissed:timeout:)]) {
        [strongDelegate messageDismissed:self.message timeout:YES];
    };

    UAInAppResolutionEvent *event = [UAInAppResolutionEvent timedOutResolutionWithMessage:self.message
                                                                          displayDuration:[self displayDuration]];
    [[UAirship shared].analytics addEvent:event];
}

/**
 * A tap should result in a brief color inversion (0.1 seconds),
 * running the associated actions, and dismissing the message.
 */
- (void)tapWithGestureRecognizer:(UIGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        if (!self.swipeDetected && !self.longPressDetected) {
            self.tapDetected = YES;
            [self handleTouchState:YES];
            [self messageClicked];



            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self handleTouchState:NO];
                [self dismiss];
            });
        }
    }
}

/**
 * A long press should result in a color inversion as long as the finger
 * remains within the view boundaries (à la UIButton). Actions should only
 * be run (and the message dismissed) if the gesture ends within these boundaries.
 */
- (void)longPressWithGestureRecognizer:(UIGestureRecognizer *)recognizer {

    CGPoint touchPoint = [recognizer locationInView:self.messageView];

    if (recognizer.state == UIGestureRecognizerStateBegan) {
        [self handleTouchState:YES];
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        if (CGRectContainsPoint(self.messageView.bounds, touchPoint)) {
            [self handleTouchState:YES];
        } else {
            [self handleTouchState:NO];
        }
    } else if (recognizer.state == UIGestureRecognizerStateEnded) {
        if (CGRectContainsPoint(self.messageView.bounds, touchPoint)) {

            if (!self.swipeDetected && !self.tapDetected) {
                self.longPressDetected = YES;
                [self handleTouchState:NO];
                [self messageClicked];

                dispatch_async(dispatch_get_main_queue(), ^{
                    [self dismiss];
                });
            }
        }
    }
}

/**
 * Delegate method for the tap and long press recognizer that rejects touches originating from either
 * of the action buttons.
 */
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    // Ignore touches within the action buttons
    if ([touch.view isKindOfClass:[UIControl class]]) {
        return NO;
    }
    return YES;
}

- (void)buttonTapped:(id)sender {
    UAInAppMessageButtonActionBinding *binding;

    UIControl *button1 = [self buttonAtIndex:0];
    UIControl *button2 = [self buttonAtIndex:1];

    // Retrieve the binding associated with the tapped button
    if ([sender isEqual:button1]) {
        binding = self.buttonActionBindings[0];
    } else if ([sender isEqual:button2])  {
        binding = self.buttonActionBindings[1];
    }

    if (binding) {
        id<UAInAppMessagingDelegate> strongDelegate = [UAirship inAppMessaging].messagingDelegate;
        if ([strongDelegate respondsToSelector:@selector(messageButtonTapped:buttonIdentifier:)]) {
            [strongDelegate messageButtonTapped:self.message buttonIdentifier:binding.identifier];
        };
    }

    // Run all the bound actions
    if (binding.actions) {
        [UAActionRunner runActionsWithActionValues:binding.actions
                                         situation:binding.situation
                                          metadata:nil
                                 completionHandler:nil];
    }

    UAInAppResolutionEvent *event = [UAInAppResolutionEvent buttonClickedResolutionWithMessage:self.message
                                                                              buttonIdentifier:binding.identifier
                                                                                   buttonTitle:binding.title
                                                                               displayDuration:[self displayDuration]];
    [[UAirship shared].analytics addEvent:event];
    
    
    [self dismiss];
}

/**
 * Returns the current display duration.
 * @return The current display duration.
 */
- (NSTimeInterval)displayDuration {
    return [[NSDate date] timeIntervalSinceDate:self.startDisplayDate];
}

- (void)dealloc {
    // release resources if dismissal has not already occured.
    // in the case where the message has already been dismissed, this
    // will be a no-op.
    [self teardown];
}

@end
