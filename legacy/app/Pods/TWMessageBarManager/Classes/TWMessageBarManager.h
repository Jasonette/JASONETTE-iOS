//
//  TWMessageBarManager.h
//
//  Created by Terry Worona on 5/13/13.
//  Copyright (c) 2013 Terry Worona. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 *  Three base message bar types. Their look & feel is defined within the MessageBarStyleSheet.
 */
typedef NS_ENUM(NSInteger, TWMessageBarMessageType) {
    TWMessageBarMessageTypeError,
    TWMessageBarMessageTypeSuccess,
    TWMessageBarMessageTypeInfo
};

@protocol TWMessageBarStyleSheet <NSObject>

/**
 *  Background color of message view.
 *
 *  @param type A MessageBarMessageType (error, information, success, etc).
 *
 *  @return UIColor istance representing the message view's background color.
 */
- (nonnull UIColor *)backgroundColorForMessageType:(TWMessageBarMessageType)type;

/**
 *  Bottom stroke color of message view.
 *
 *  @param type A MessageBarMessageType (error, information, success, etc).
 *
 *  @return UIColor istance representing the message view's bottom stroke color.
 */
- (nonnull UIColor *)strokeColorForMessageType:(TWMessageBarMessageType)type;

/**
 *  Icon image of the message view.
 *
 *  @param type A MessageBarMessageType (error, information, success, etc).
 *
 *  @return UIImage istance representing the message view's icon.
 */
- (nonnull UIImage *)iconImageForMessageType:(TWMessageBarMessageType)type;

@optional

/**
 *  The (optional) UIFont to be used for the message's title.
 *
 *  Default: 16pt bold
 *
 *  @param type A MessageBarMessageType (error, information, success, etc).
 *
 *  @return UIFont instance representing the title font.
 */
- (nonnull UIFont *)titleFontForMessageType:(TWMessageBarMessageType)type;

/**
 *  The (optional) UIFont to be used for the message's description.
 *
 *  Default: 14pt regular
 *
 *  @param type A MessageBarMessageType (error, information, success, etc).
 *
 *  @return UIFont instance representing the description font.
 */
- (nonnull UIFont *)descriptionFontForMessageType:(TWMessageBarMessageType)type;

/**
 *  The (optional) UIColor to be used for the message's title.
 *
 *  Default: white
 *
 *  @param type A MessageBarMessageType (error, information, success, etc).
 *
 *  @return UIColor instance representing the title color.
 */
- (nonnull UIColor *)titleColorForMessageType:(TWMessageBarMessageType)type;

/**
 *  The (optional) UIColor to be used for the message's description.
 *
 *  Default: white
 *
 *  @param type A MessageBarMessageType (error, information, success, etc).
 *
 *  @return UIColor instance representing the description color.
 */
- (nonnull UIColor *)descriptionColorForMessageType:(TWMessageBarMessageType)type;

@end

@interface TWMessageBarManager : NSObject

/**
 *  Singleton instance through which all presentation is managed.
 *
 *  @return MessageBarManager instance (singleton).
 */
+ (nonnull TWMessageBarManager *)sharedInstance;

/**
 *  Default display duration for each message.
 *  This can be customized on a per-message basis (see presentation functions below).
 *
 *  @return Default display duration (3 seconds).
 */
+ (CGFloat)defaultDuration;

/**
 *  Flag indicating if message is currently visible on screen.
 */
@property (nonatomic, readonly, getter = isMessageVisible) BOOL messageVisible;

/**
 *  The orientations supported by the manager. 
 *  In most cases, this value will match the caller's orientation mask. 
 *
 *  @return Default behaviour - all orientations.
 */
@property (nonatomic, assign) UIInterfaceOrientationMask managerSupportedOrientationsMask;

/**
 *  An object conforming to the TWMessageBarStyleSheet protocol defines the message bar's look and feel.
 *  If no style sheet is supplied, a default class is provided on initialization (see implementation for details).
 */
@property (nonnull, nonatomic, strong) NSObject<TWMessageBarStyleSheet> *styleSheet;

/**
 *  Shows a message with the supplied title, description and type.
 *
 *  @param title        Header text in the message view.
 *  @param description  Description text in the message view.
 *  @param type         Type dictates color, stroke and icon shown in the message view.
 */
- (void)showMessageWithTitle:(nullable NSString *)title description:(nullable NSString *)description type:(TWMessageBarMessageType)type;

/**
 *  Shows a message with the supplied title, description, type & callback block.
 *
 *  @param title        Header text in the message view.
 *  @param description  Description text in the message view.
 *  @param type         Type dictates color, stroke and icon shown in the message view.
 *  @param callback     Callback block to be executed if a message is tapped.
 */
- (void)showMessageWithTitle:(nullable NSString *)title description:(nullable NSString *)description type:(TWMessageBarMessageType)type callback:(nullable void (^)())callback;

/**
 *  Shows a message with the supplied title, description, type & duration.
 *
 *  @param title        Header text in the message view.
 *  @param description  Description text in the message view.
 *  @param type         Type dictates color, stroke and icon shown in the message view.
 *  @param duration     Default duration is 3 seconds, this can be overridden by supplying an optional duration parameter.
 */
- (void)showMessageWithTitle:(nullable NSString *)title description:(nullable NSString *)description type:(TWMessageBarMessageType)type duration:(CGFloat)duration;

/**
 *  Shows a message with the supplied title, description, type, duration and callback block.
 *
 *  @param title        Header text in the message view.
 *  @param description  Description text in the message view.
 *  @param type         Type dictates color, stroke and icon shown in the message view.
 *  @param duration     Default duration is 3 seconds, this can be overridden by supplying an optional duration parameter.
 *  @param callback     Callback block to be executed if a message is tapped.
 */
- (void)showMessageWithTitle:(nullable NSString *)title description:(nullable NSString *)description type:(TWMessageBarMessageType)type duration:(CGFloat)duration callback:(nullable void (^)())callback;

/**
 *  Shows a message with the supplied title, description, type, status bar style and callback block.
 *
 *  @param title            Header text in the message view.
 *  @param description      Description text in the message view.
 *  @param type             Type dictates color, stroke and icon shown in the message view.
 *  @param statusBarStyle   Applied during the presentation of the message. If not supplied, style will default to UIStatusBarStyleDefault.
 *  @param callback         Callback block to be executed if a message is tapped.
 */
- (void)showMessageWithTitle:(nullable NSString *)title description:(nullable NSString *)description type:(TWMessageBarMessageType)type statusBarStyle:(UIStatusBarStyle)statusBarStyle callback:(nullable void (^)())callback;

/**
 *  Shows a message with the supplied title, description, type, duration, status bar style and callback block.
 *
 *  @param title            Header text in the message view.
 *  @param description      Description text in the message view.
 *  @param type             Type dictates color, stroke and icon shown in the message view.
 *  @param duration         Default duration is 3 seconds, this can be overridden by supplying an optional duration parameter.
 *  @param statusBarStyle   Applied during the presentation of the message. If not supplied, style will default to UIStatusBarStyleDefault.
 *  @param callback         Callback block to be executed if a message is tapped.
 */
- (void)showMessageWithTitle:(nullable NSString *)title description:(nullable NSString *)description type:(TWMessageBarMessageType)type duration:(CGFloat)duration statusBarStyle:(UIStatusBarStyle)statusBarStyle callback:(nullable void (^)())callback;

/**
 *  Shows a message with the supplied title, description, type, status bar hidden toggle and callback block.
 *
 *  @param title            Header text in the message view.
 *  @param description      Description text in the message view.
 *  @param type             Type dictates color, stroke and icon shown in the message view.
 *  @param statusBarHidden  Status bars are shown by default. To hide it during the presentation of a message, set to NO.
 *  @param callback         Callback block to be executed if a message is tapped.
 */
- (void)showMessageWithTitle:(nullable NSString *)title description:(nullable NSString *)description type:(TWMessageBarMessageType)type statusBarHidden:(BOOL)statusBarHidden callback:(nullable void (^)())callback;

/**
 *  Shows a message with the supplied title, description, type, duration, status bar hidden toggle and callback block.
 *
 *  @param title            Header text in the message view.
 *  @param description      Description text in the message view.
 *  @param type             Type dictates color, stroke and icon shown in the message view.
 *  @param duration         Default duration is 3 seconds, this can be overridden by supplying an optional duration parameter.
 *  @param statusBarHidden  Status bars are shown by default. To hide it during the presentation of a message, set to NO.
 *  @param callback         Callback block to be executed if a message is tapped.
 */
- (void)showMessageWithTitle:(nullable NSString *)title description:(nullable NSString *)description type:(TWMessageBarMessageType)type duration:(CGFloat)duration statusBarHidden:(BOOL)statusBarHidden callback:(nullable void (^)())callback;

/**
 *  Hides the topmost message and removes all remaining messages in the queue.
 *
 *  @param animated     Animates the current message view off the screen.
 */
- (void)hideAllAnimated:(BOOL)animated;
- (void)hideAll; // non-animated

@end

@interface UIDevice (Additions)

/**
 *  Determines if the device instance is running iOS 7 or later.
 *
 *  @return YES if the device instance is running an OS >= 7, otherwise NO.
 */
- (BOOL)tw_isRunningiOS7OrLater;

@end
