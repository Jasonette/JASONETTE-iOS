//
//  AHKActionSheet.h
//  AHKActionSheetExample
//
//  Created by Arkadiusz on 08-04-14.
//  Copyright (c) 2014 Arkadiusz Holko. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, AHKActionSheetButtonType) {
    AHKActionSheetButtonTypeDefault = 0,
	AHKActionSheetButtonTypeDisabled,
    AHKActionSheetButtonTypeDestructive
};

@class AHKActionSheet;
typedef void(^AHKActionSheetHandler)(AHKActionSheet *actionSheet);


/// A block-based alternative to the `UIAlertView`.
@interface AHKActionSheet : UIView <UIAppearanceContainer>

// Appearance - all of the following properties should be set before showing the action sheet. See `+initialize` to learn the default values of all properties.

/**
 *  See UIImage+AHKAdditions.h/.m to learn how these three properties are used.
 */
@property (nonatomic) CGFloat blurRadius UI_APPEARANCE_SELECTOR;
@property (strong, nonatomic) UIColor *blurTintColor UI_APPEARANCE_SELECTOR;
@property (nonatomic) CGFloat blurSaturationDeltaFactor UI_APPEARANCE_SELECTOR;

/// Height of the button (internally it's a `UITableViewCell`).
@property (nonatomic) CGFloat buttonHeight UI_APPEARANCE_SELECTOR;
/// Height of the cancel button.
@property (nonatomic) CGFloat cancelButtonHeight UI_APPEARANCE_SELECTOR;
/**
 *  If set, a small shadow (a gradient layer) will be drawn above the cancel button to separate it visually from the other buttons.
 *  It's best to use a color similar (but maybe with a lower alpha value) to blurTintColor.
 *  See "Advanced" example in the example project to see it used.
 */
@property (strong, nonatomic) UIColor *cancelButtonShadowColor UI_APPEARANCE_SELECTOR;
/// Boxed (@YES, @NO) boolean value (enabled by default). Isn't supported on iOS 6.
@property (strong, nonatomic) NSNumber *automaticallyTintButtonImages UI_APPEARANCE_SELECTOR;
/// Boxed boolean value. Useful when adding buttons without images (in that case text looks better centered). Disabled by default.
@property (strong, nonatomic) NSNumber *buttonTextCenteringEnabled UI_APPEARANCE_SELECTOR;
/// Color of the separator between buttons.
@property (strong, nonatomic) UIColor *separatorColor UI_APPEARANCE_SELECTOR;
/// Background color of the button when it's tapped (internally it's a UITableViewCell)
@property (strong, nonatomic) UIColor *selectedBackgroundColor UI_APPEARANCE_SELECTOR;
/// Text attributes of the title (passed in initWithTitle: or set via `title` property)
@property (copy, nonatomic) NSDictionary *titleTextAttributes UI_APPEARANCE_SELECTOR;
@property (copy, nonatomic) NSDictionary *buttonTextAttributes UI_APPEARANCE_SELECTOR;
@property (copy, nonatomic) NSDictionary *disabledButtonTextAttributes UI_APPEARANCE_SELECTOR;
@property (copy, nonatomic) NSDictionary *destructiveButtonTextAttributes UI_APPEARANCE_SELECTOR;
@property (copy, nonatomic) NSDictionary *cancelButtonTextAttributes UI_APPEARANCE_SELECTOR;
/// Duration of the show/dismiss animations. Defaults to 0.5.
@property (nonatomic) NSTimeInterval animationDuration UI_APPEARANCE_SELECTOR;

/// Boxed boolean value. Enables/disables control hiding with pan gesture. Enabled by default.
@property (strong, nonatomic) NSNumber *cancelOnPanGestureEnabled UI_APPEARANCE_SELECTOR;

/// Boxed boolean value. Enables/disables control hiding when tapped on empty area. Disabled by default.
@property (strong, nonatomic) NSNumber *cancelOnTapEmptyAreaEnabled UI_APPEARANCE_SELECTOR;

/// A handler called on every type of dismissal (tapping on "Cancel" or swipe down or flick down).
@property (strong, nonatomic) AHKActionSheetHandler cancelHandler;
@property (copy, nonatomic) NSString *cancelButtonTitle;

/// String to display above the buttons.
@property (copy, nonatomic) NSString *title;
/// View to display above the buttons (only if the title isn't set).
@property (strong, nonatomic) UIView *headerView;
/// Window visible before the actionSheet was presented.
@property (weak, nonatomic, readonly) UIWindow *previousKeyWindow;


/**
 *  Initializes the action sheet with a specified title. `headerView` can be used if a string is insufficient for the title; set `title` as `nil` in this case.
 *
 *  It's the designated initializer.
 *
 *  @param title A string to display in the title area, above the buttons.
 *
 *  @return A newly initialized action sheet.
 */
- (instancetype)initWithTitle:(NSString *)title;

/**
 *  Adds a button without an image. Has to be called before showing the action sheet.
 *
 *  @param handler A completion handler block to execute when a dismissal animation (after the user tapped on the button) has finished.
 */
- (void)addButtonWithTitle:(NSString *)title type:(AHKActionSheetButtonType)type handler:(AHKActionSheetHandler)handler;

/**
 *  Adds a button with an image. Has to be called before showing the action sheet.
 *
 *  @param image   The image to display on the left of the title.
 *  @param handler A completion handler block to execute when a dismissal animation (after the user tapped on the button) has finished.
 */
- (void)addButtonWithTitle:(NSString *)title image:(UIImage *)image type:(AHKActionSheetButtonType)type handler:(AHKActionSheetHandler)handler;

/// Displays the action sheet.
- (void)show;

/// Dismisses the action sheet with an optional animation.
- (void)dismissAnimated:(BOOL)animated;

@end
