//
//  PasscodeViewController.h
//  LTHPasscodeViewController
//
//  Created by Roland Leth on 9/6/13.
//  Copyright (c) 2013 Roland Leth. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol LTHPasscodeViewControllerDelegate <NSObject>
@optional
/**
 @brief Called right before the passcode view controller will be dismissed or popped.
 */
- (void)passcodeViewControllerWillClose;
/**
 @brief Called when the max number of failed attempts has been reached.
 */
- (void)maxNumberOfFailedAttemptsReached;
/**
 @brief Called when the passcode was entered successfully.
 */
- (void)passcodeWasEnteredSuccessfully;
/**
 @brief Called when the passcode was enabled.
 */
- (void)passcodeWasEnabled;
/**
 @brief Called when the logout button was pressed.
 */
- (void)logoutButtonWasPressed;
/**
 @brief	  Handle here the retrieval of the duration that needs to pass while app is in background for the lock to be displayed.
 @details Called when @c +timerDuration is called and @c +useKeychain:NO was used, but falls back to the Keychain anyway if not implemented.
 @return The duration.
 */
- (NSTimeInterval)timerDuration;
/**
 @brief			 Handle here the saving of the duration that needs to pass while the app is in background for the lock to be displayed.
 @details        Called when @c +saveTimerDuration: is called and @c +useKeychain:NO was used, but falls back to the Keychain anyway if not implemented.
 @param duration The duration.
 */
- (void)saveTimerDuration:(NSTimeInterval)duration;
/**
 @brief   Handle here the retrieval of the time at which the timer started.
 @details Called when @c +timerStartTime is called and @c +useKeychain:NO was used, but falls back to the Keychain anyway if not implemented.
 @return The time at which the timer started.
 */
- (NSTimeInterval)timerStartTime;
/**
 @brief    Handle here the saving of the current time.
 @details  Called when @c +saveTimerStartTime is called and @c +useKeychain:NO was used, but falls back to the Keychain anyway if not implemented.
 */
- (void)saveTimerStartTime;
/**
 @brief      Handle here the check if the timer has ended and the lock has to be displayed.
 @details    Called when @c +didPasscodeTimerEnd is called and @c +useKeychain:NO was used, but falls back to the Keychain anyway if not implemented.
 @return @c YES if the timer ended and the lock has to be displayed.
 */
- (BOOL)didPasscodeTimerEnd;
/**
 @brief   Handle here the passcode deletion.
 @details Called when @c +deletePasscode or @c +deletePasscodeAndClose are called and @c +useKeychain:NO was used, but falls back to the Keychain anyway if not implemented.
 */
- (void)deletePasscode;
/**
 @brief   Handle here the saving of the passcode.
 @details Called if @c +useKeychain:NO was used, but falls back to the Keychain anyway if not implemented.
 @param passcode The passcode.
 */
- (void)savePasscode:(NSString *)passcode;
/**
 @brief   Retrieve here the saved passcode.
 @details Called if @c +useKeychain:NO was used, but falls back to the Keychain anyway if not implemented.
 @return The passcode.
 */
- (NSString *)passcode;
/**
 @brief   Handle here the saving of the preference for allowing the use of TouchID.
 @details Called if @c +useKeychain:NO was used, but falls back to the Keychain anyway if not implemented.
 @param allowUnlockWithTouchID The boolean for the preference for allowing the use of TouchID.
 */
- (void)saveAllowUnlockWithTouchID:(BOOL)allowUnlockWithTouchID;
/**
 @brief   Retrieve here the saved preference for allowing the use of TouchID.
 @details Called if @c +useKeychain:NO was used, but falls back to the Keychain anyway if not implemented.
 @return allowUnlockWithTouchID boolean.
 */
- (BOOL)allowUnlockWithTouchID;
@end

@interface LTHPasscodeViewController : UIViewController

/**
 @brief   The delegate.
 */
@property (nonatomic, weak) id<LTHPasscodeViewControllerDelegate> delegate;
/**
 @brief        The number of digits for the simple passcode. Default is @c 4, or the length of the passcode, if one exists.

 @b Attention: If you increase the number of digits and they do not fit on screen anymore, please decrease the @c horizontalGap accordingly.

 @b Warning:   If a passcode is present, changing this will not work, since it would not allow the user to enter his passcode anymore. Please disable the passcode first.
 */
@property (nonatomic, assign) NSInteger digitsCount;
/**
 @brief      The gap between the passcode digits. Default is @c 40 for iPhone, @c 60 for iPad.
 */
@property (nonatomic, assign) CGFloat horizontalGap;
/**
 @brief The gap between the top label and the passcode digits/field.
 */
@property (nonatomic, assign) CGFloat verticalGap;
/**
 @brief The offset between the top label and middle position.
 */
@property (nonatomic, assign) CGFloat verticalOffset;
/**
 @brief The gap between the passcode digits and the failed label.
 */
@property (nonatomic, assign) CGFloat failedAttemptLabelGap;
/**
 @brief The height for the complex passcode overlay.
 */
@property (nonatomic, assign) CGFloat passcodeOverlayHeight;
/**
 @brief The font size for the top label.
 */
@property (nonatomic, assign) CGFloat labelFontSize;
/**
 @brief The font size for the passcode digits.
 */
@property (nonatomic, assign) CGFloat passcodeFontSize;
/**
 @brief The font for the top label.
 */
@property (nonatomic, strong) UIFont *labelFont;
/**
 @brief The font for the passcode digits.
 */
@property (nonatomic, strong) UIFont *passcodeFont;
/**
 @brief The background color for the top label.
 */
@property (nonatomic, strong) UIColor *enterPasscodeLabelBackgroundColor;
/**
 @brief The background color for the view.
 */
@property (nonatomic, strong) UIColor *backgroundColor;
/**
 @brief The background image for the coverview.
 */
@property (nonatomic, strong) UIImage *backgroundImage;
/**
 @brief The background color for the cover view that appears on top of the app, visible in the multitasking.
 */
@property (nonatomic, strong) UIColor *coverViewBackgroundColor;
/**
 @brief The background color for the passcode digits.
 */
@property (nonatomic, strong) UIColor *passcodeBackgroundColor;
/**
 @brief The background color for the failed attempt label.
 */
@property (nonatomic, strong) UIColor *failedAttemptLabelBackgroundColor;
/**
 @brief The text color for the top label.
 */
@property (nonatomic, strong) UIColor *labelTextColor;
/**
 @brief The text color for the passcode digits.
 */
@property (nonatomic, strong) UIColor *passcodeTextColor;
/**
 @brief The text color for the failed attempt label.
 */
@property (nonatomic, strong) UIColor *failedAttemptLabelTextColor;
/**
 @brief The tint color to apply to the navigation items and bar button items.
 */
@property (nonatomic, strong) UIColor *navigationBarTintColor;
/**
 @brief The tint color to apply to the navigation bar background.
 */
@property (nonatomic, strong) UIColor *navigationTintColor;
/**
 @brief The color for te navigation bar's title.
 */
@property (nonatomic, strong) UIColor *navigationTitleColor;
/**
 @brief The string to be used as username for the passcode in the Keychain.
 */
@property (nonatomic, strong) NSString *keychainPasscodeUsername;
/**
 @brief The string to be used as username for the timer start time in the Keychain.
 */
@property (nonatomic, strong) NSString *keychainTimerStartUsername;
/**
 @brief The string to be used as username for the timer duration in the Keychain.
 */
@property (nonatomic, strong) NSString *keychainTimerDurationUsername;
/**
 @brief The string to be used as username for the "isSimple" in the Keychain.
 */
@property (nonatomic, strong) NSString *keychainPasscodeIsSimpleUsername;
/**
 @brief The string to be used as service name for all the Keychain entries.
 */
@property (nonatomic, strong) NSString *keychainServiceName;
/**
 @brief The string to be used as username for allow TouchID unlock in the Keychain.
 */
@property (nonatomic, strong) NSString *keychainAllowUnlockWithTouchID;
/**
 @brief The character for the passcode digit.
 */
@property (nonatomic, strong) NSString *passcodeCharacter;
/**
 @brief The table name for NSLocalizedStringFromTable.
 */
@property (nonatomic, strong) NSString *localizationTableName;
/**
 @brief The tag for the cover view.
 */
@property (nonatomic, assign) NSInteger coverViewTag;
/**
 @brief The string displayed when entering your old passcode (while changing).
 */
@property (nonatomic, strong) NSString *enterOldPasscodeString;
/**
 @brief The string displayed when entering your passcode.
 */
@property (nonatomic, strong) NSString *enterPasscodeString;
/**
 @brief The string used to explain the reason of setting passcode.
 @details The given string is oprional and is displayed below passcode field.
 */
@property (nonatomic, strong) NSString *enterPasscodeInfoString;
/**
 @brief A Boolean value that indicates whether the @c enterPasscodeInfoString is displayed (@c YES) or not (@c NO). Default is @c YES.
 */
@property (nonatomic, assign) BOOL displayAdditionalInfoDuringSettingPasscode;
/**
 @brief The string displayed when entering your new passcode (while changing).
 */
@property (nonatomic, strong) NSString *enterNewPasscodeString;
/**
 @brief The string displayed when enabling your passcode.
 */
@property (nonatomic, strong) NSString *enablePasscodeString;
/**
 @brief The string displayed when changing your passcode.
 */
@property (nonatomic, strong) NSString *changePasscodeString;
/**
 @brief The string displayed when disabling your passcode.
 */
@property (nonatomic, strong) NSString *turnOffPasscodeString;
/**
 @brief The string displayed when reentering your passcode.
 */
@property (nonatomic, strong) NSString *reenterPasscodeString;
/**
 @brief The string displayed when reentering your new passcode (while changing).
 */
@property (nonatomic, strong) NSString *reenterNewPasscodeString;
/**
 @brief The string displayed while user unlocks with TouchID.
 */
@property (nonatomic, strong) NSString *touchIDString;
/**
 @brief The duration of the lock animation.
 */
@property (nonatomic, assign) CGFloat lockAnimationDuration;
/**
 @brief The duration of the slide animation.
 */
@property (nonatomic, assign) CGFloat slideAnimationDuration;
/**
 @brief The maximum number of failed attempts allowed.
 */
@property (nonatomic, assign) NSInteger maxNumberOfAllowedFailedAttempts;
/**
 @brief The navigation bar, if one was used.
 */
@property (nonatomic, strong) UINavigationBar *navBar;
/**
 @brief A Boolean value that indicates whether the navigation bar is translucent (@c YES) or not (@c NO).
 */
@property (nonatomic, assign) BOOL navigationBarTranslucent;
/**
 @brief A Boolean value that indicates whether the back bar button is hidden (@c YES) or not (@c NO). Default is @c YES.
 */
@property (nonatomic, assign) BOOL hidesBackButton;

/**
 @brief A Boolean value that indicates whether the right bar button is hidden (@c YES) or not (@c NO). Default is @c YES.
 */
@property (nonatomic, assign) BOOL hidesCancelButton;

/**
 @brief A Boolean value that indicates whether TouchID can be used (@c YES) or not (@c NO). Default is @c YES.
 */
@property (nonatomic, assign) BOOL allowUnlockWithTouchID;


// MARK: - Methods

/**
 @brief				Used for displaying the lock. The passcode view is added directly on the keyWindow.
 @param hasLogout   Set to @c YES for a navBar with a Logout button, set to @c NO for no navBar.
 @param logoutTitle The title of the Logout button.
 */
- (void)showLockScreenWithAnimation:(BOOL)animated withLogout:(BOOL)hasLogout andLogoutTitle:(NSString *)logoutTitle;
/**
 @brief				Used for displaying the lock over a view; the lock will have the same size and center as the @c superview.
 @param superview   The @c view where the lock will be added to and presented over.
 @param hasLogout   Set to @c YES for a navBar with a Logout button, set to @c NO for no navBar.
 @param logoutTitle The title of the Logout button.
 */
- (void)showLockScreenOver:(UIView *)superview withAnimation:(BOOL)animated withLogout:(BOOL)hasLogout andLogoutTitle:(NSString *)logoutTitle;
/**
 @brief				   Used for enabling the passcode.
 @details              The back bar button is hidden by default. Set @c hidesBackButton to @c NO if you want it to be visible.
 @param	viewController The view controller where the passcode view controller will be displayed.
 @param isModal        Set to @c YES to present as a modal, or to @c NO to push on the current nav stack.
 */
- (void)showForEnablingPasscodeInViewController:(UIViewController *)viewController asModal:(BOOL)isModal;
/**
 @brief				   Used for changing the passcode.
 @details              The back bar button is hidden by default. Set @c hidesBackButton to @c NO if you want it to be visible.
 @param	viewController The view controller where the passcode view controller will be displayed.
 @param isModal        Set to @c YES to present as a modal, or to @c NO to push on the current nav stack.
 */
- (void)showForChangingPasscodeInViewController:(UIViewController *)viewController asModal:(BOOL)isModal;
/**
 @brief				   Used for disabling the passcode.
 @details              The back bar button is hidden by default. Set @c hidesBackButton to @c NO if you want it to be visible.
 @param	viewController The view controller where the passcode view controller will be displayed.
 @param isModal        Set to @c YES to present as a modal, or to @c NO to push on the current nav stack.
 */
- (void)showForDisablingPasscodeInViewController:(UIViewController *)viewController asModal:(BOOL)isModal;
/**
 @brief Closes the passcode view controller.
 */
+ (void)close;

// MARK: - Passcode related methods

/**
 @brief  Returns a Boolean value that indicates whether a simple, N digit (4 by default or digitsCount) (@c YES) or a complex passcode will be used (@c NO).
 @return @c YES if the passcode is simple, @c NO if the passcode is complex
 */
- (BOOL)isSimple;
/**
 @brief                 Sets if the passcode should be simple (@c 4 digits by default) or complex.
 @param isSimple        Set to @c YES for a simple passcode, and to @c NO for a complex passcode.
 @param viewController  The view controller where the passcode view controller will be displayed.
 @param isModal         Set to @c YES to present as a modal, or to @c NO to push on the current nav stack.
 @details               @c inViewController and @c asModal are needed because the delegate is of type id, and the passcode needs to be presented somewhere and with a specific style - modal or pushed.
 */
- (void)setIsSimple:(BOOL)isSimple inViewController:(UIViewController *)viewController asModal:(BOOL)isModal;
/**
 @brief The passcode view will be shown by default when entering the app from background. This method disables this behavior by removing the observers for UIApplicationDidEnterBackgroundNotification and UIApplicationWillEnterForegroundNotification.
 */
- (void)disablePasscodeWhenApplicationEntersBackground;
/**
 @brief The passcode view will be shown by default when entering the app from background. `disablePasscodeWhenApplicationEntersBackground` can disable that behavior and this method enables it again, by adding back the observers for UIApplicationDidEnterBackgroundNotification and UIApplicationWillEnterForegroundNotification
 */
- (void)enablePasscodeWhenApplicationEntersBackground;
/**
 @brief  Returns a Boolean value that indicates whether a passcode exists (@c YES) or not (@c NO).
 @return @c YES if a passcode is enabled. This also means it is enabled, unless custom logic was added to the library.
 */
+ (BOOL)doesPasscodeExist;
/**
 @brief	 Retrieves from the keychain the duration while app is in background after which the lock has to be displayed.
 @return The duration.
 */
+ (NSTimeInterval)timerDuration;
/**
 @brief			 Saves in the keychain the duration that needs to pass while app is in background  for the lock to be displayed.
 @param duration The duration.
 */
+ (void)saveTimerDuration:(NSTimeInterval)duration;
/**
 @brief  Retrieves from the keychain the time at which the timer started.
 @return The time, as @c timeIntervalSinceReferenceDate, at which the timer started.
 */
+ (NSTimeInterval)timerStartTime;
/**
 @brief Saves the current time, as @c timeIntervalSinceReferenceDate.
 */
+ (void)saveTimerStartTime;
/**
 @brief  Returns a Boolean value that indicates whether the timer has ended (@c YES) and the lock has to be displayed or not (@c NO).
 @return @c YES if the timer ended and the lock has to be displayed.
 */
+ (BOOL)didPasscodeTimerEnd;
/**
 @brief Removes the passcode from the keychain.
 */
+ (void)deletePasscode;
/**
 @brief Removes the passcode from the keychain and closes the passcode view controller.
 */
+ (void)deletePasscodeAndClose;
/**
 @brief             Call this if you want to save and read the passcode and timers to and from somewhere else rather than the Keychain.
 @attention         All the protocol methods will fall back to the Keychain if not implemented, even if calling this method with @c NO. This allows for flexibility over what and where you save.
 @param useKeychain Set to @c NO if you want to save and read the passcode and timers to and from somewhere else rather than the Keychain. Default is @c YES.
 */
+ (void)useKeychain:(BOOL)useKeychain;
/**
 @brief  Returns the shared instance of the passcode view controller.
 */
+ (instancetype)sharedUser;
/**
 @brief  Resets the passcode.
 */
- (void)resetPasscode;

@end
