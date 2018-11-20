/* Copyright 2017 Urban Airship and Contributors */

#import "UANotificationAction.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Clone of UNTextInputNotificationAction for iOS 8-10 support.
 *
 * Note that in iOS 8, UATextInputNotificationAction actions will not be registered 
 * as custom actions with the operating system, as text input notification actions 
 * are not supported in iOS 8.
 */
@interface UATextInputNotificationAction : UANotificationAction

///---------------------------------------------------------------------------------------
/// @name Text Input Notification Action Properties
///---------------------------------------------------------------------------------------

/**
 * The localized string to use as the title of the text input button.
 */
@property(nonatomic, copy, readonly) NSString *textInputButtonTitle;

/**
 * The localized string to display in the text input field.
 */
@property(nonatomic, copy, readonly) NSString *textInputPlaceholder;

/**
 * Note: There appears to be a bug in iOS 9 that prevents the return 
 * of the user's response when the UIUserNotificationActivationMode
 * is UIUserNotificationActivationModeForeground.  
 *
 * If forceBackgroundActivationModeInIOS9 is YES (which is the default), 
 * the UIUserNotificationActivationMode will be forced to
 * UIUserNotificationActivationModeBackground.
 *
 * Set forceBackgroundActivationModeInIOS9 to NO to use 
 * UIUserNotificationActivationModeForeground.
 */
@property(nonatomic, assign) BOOL forceBackgroundActivationModeInIOS9;

///---------------------------------------------------------------------------------------
/// @name Text Input Notification Action Initialization
///---------------------------------------------------------------------------------------

/**
 * Init method.
 *
 * @param identifier The action's identifier.
 * @param title The action's title.
 * @param textInputButtonTitle The title of the text input button.
 * @param textInputPlaceholder The text to display in the text input field.
 * @param options The action's options.
 */
- (instancetype)initWithIdentifier:(NSString *)identifier
                             title:(NSString *)title
              textInputButtonTitle:(NSString *)textInputButtonTitle
              textInputPlaceholder:(NSString *)textInputPlaceholder
                           options:(UANotificationActionOptions)options;

/**
 * Creates an action with the specified title and options.
 * 
 * @param identifier The unique string that you use internally to identify the action. 
 *        When the user selects the action, the system passes this string to your
 *        app and asks you to perform the related task. This parameter must not be nil.
 * @param title The localized string to display to the user.
 *        This string is displayed in interface elements such as buttons that are
 *        used to represent actions. This parameter must not be nil.
 * @param textInputButtonTitle The localized title of the text input button that is
 *        displayed to the user.
 * @param textInputPlaceholder The localized placeholder text to display in the text
 *        input field.
 * @param options Additional options for how the action should be performed. Add options
 *        sparingly and only when you require the related behavior. For a list of
 *        possible values, see UANotificationActionOptions.
 */
+ (instancetype)actionWithIdentifier:(NSString *)identifier
                               title:(NSString *)title
                textInputButtonTitle:(NSString *)textInputButtonTitle
                textInputPlaceholder:(NSString *)textInputPlaceholder
                             options:(UANotificationActionOptions)options;

@end

NS_ASSUME_NONNULL_END
