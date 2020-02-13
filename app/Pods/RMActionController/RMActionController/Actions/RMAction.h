//
//  RMAction.h
//  RMActionController-Demo
//
//  Created by Roland Moers on 19.11.16.
//  Copyright © 2016 Roland Moers. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RMActionController<T : UIView *>;

/**
 *  RMActionStyle is used to determine the display style of RMAction and where it is positioned. There are 4 styles available: Done, cancel, additional and the default style, which is the done style.
 */
typedef NS_ENUM(NSInteger, RMActionStyle) {
    /** The button is displayed with a regular font and positioned right below the content view. */
    RMActionStyleDone,
    /** The button is displayed with a bold font and positioned below all done buttons (or the content view if there are no done buttons). */
    RMActionStyleCancel,
    /** The button is displayed with a standard destructive and positioned right below the content view. Currently only supported when blur effects are disabled.*/
    RMActionStyleDestructive,
    /** The button is displayed with a regular font and positioned above the content view. */
    RMActionStyleAdditional,
    /** The button is displayed and positioned like a done button. */
    RMActionStyleDefault = RMActionStyleDone
};

/**
 *  A RMAction instance represents an action that can be tapped by the use when a RMActionController is presented. It has a title or image for identifying the action and a handler which is calledwhen the action has been tapped by the user.
 *
 *  If both title and image are given, the title is displayed.
 */
@interface RMAction<T : UIView *> : NSObject

/// @name Getting an Instance
#pragma mark - Getting an Instance

/**
 *  Returns a new instance of RMAction with the given properties set.
 *
 *  @param title   The title of the action.
 *  @param style   The style of the action.
 *  @param handler A block that is called when the action has been tapped.
 *
 *  @return The new instance of RMAction.
 */
+ (nullable instancetype)actionWithTitle:(nonnull NSString *)title style:(RMActionStyle)style andHandler:(nullable void (^)(RMActionController<T> * __nonnull controller))handler;

/**
 *  Returns a new instance of RMAction with the given properties set.
 *
 *  @param image   The image of the action.
 *  @param style   The style of the action.
 *  @param handler A block that is called when the action has been tapped.
 *
 *  @return The new instance of RMAction.
 */
+ (nullable instancetype)actionWithImage:(nonnull UIImage *)image style:(RMActionStyle)style andHandler:(nullable void (^)(RMActionController<T> * __nonnull controller))handler;

/**
 *  Returns a new instance of RMAction with the given properties set.
 *
 *  @param title   The title of the action.
 *  @param image   The image of the action.
 *  @param style   The style of the action.
 *  @param handler A block that is called when the action has been tapped.
 *
 *  @return The new instance of RMAction.
 */
+ (nullable instancetype)actionWithTitle:(nonnull NSString *)title image:(nonnull UIImage *)image style:(RMActionStyle)style andHandler:(nullable void (^)(RMActionController<UIView *> * __nonnull controller))handler;

/// @name Properties
#pragma mark - Properties

/**
 *  The controller your action is added to.
 */
@property (nullable, nonatomic, weak, readonly) RMActionController *controller;

/**
 *  The title of the action.
 */
@property (nullable, nonatomic, readonly) NSString *title;

/**
 *  The image of the action.
 */
@property (nullable, nonatomic, readonly) UIImage *image;

/**
 *  The style of the action.
 */
@property (nonatomic, readonly) RMActionStyle style;

/**
 *  Control whether or not the RMActionController to whom the RMAction has been added is dismissed when the RMAction has been tapped.
 */
@property (nonatomic, assign) BOOL dismissesActionController;

/**
 *  Gives you access to the actual view of the RMAction.
 */
@property (nonnull, nonatomic, readonly) UIView *view;

/**
 *  Called when the RMAction is expected to load it's view. In subclasses return your custom content view here. Do not call manually.
 */
- (nonnull UIView *)loadView;

/**
 *  Call this method when you want to indicate, that this action has been tapped by the user. For example, this method can be used as the selector for an UIButton.
 */
- (void)actionTapped:(nullable id)sender;

@end

