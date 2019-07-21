//
//  DTProgressHUD.h
//  DTFoundation
//
//  Created by Stefan Gugarel on 07.05.14.
//  Copyright 2014 Cocoanetics. All rights reserved.
//

/**
 Different types for showing and hiding animation
 */
typedef NS_ENUM(NSUInteger, HUDProgressAnimationType)
{
	/**
	 Fading HUD
	 */
	HUDProgressAnimationTypeFade,
	
	/**
	 Gravity falls straight down
	 */
	HUDProgressAnimationTypeGravity,
	
	/**
	 Gravity, HUD spins around own axis
	 */
	HUDProgressAnimationTypeGravityRoll,
	
	/**
	 Gravity, HUD tilts during fall down
	 */
	HUDProgressAnimationTypeGravityTilt,
	
	/**
	 Snaps to / from center of screen
	 */
	HUDProgressAnimationTypeSnap
};

/**
 Type of progress that is shown
 */
typedef NS_ENUM(NSUInteger, HUDProgressType)
{
	/**
	 Infinite progress with 'UIActivityIndicatorView'
	 */
	HUDProgressTypeInfinite,
	
	/**
	 Progess with pie 'DTPieProgressIndicator'
	 */
	HUDProgressTypePie
};

/**
 Class for displaying informations (in the middle fo the screen).
 
 The name of this class comes from Apples UIProgressHUD which is private API.
 
 You can display text with either an image or progress.
 
 There is no need to call addSubview on Superview of 'DTProgressHUD'. Creates own 'UIWindow' for displaying similar to 'UIAlertView'
 */
@interface DTProgressHUD : UIView

/**
 The duration for fading in animation when show method is called. Default value is 0.3f.
 */
@property (nonatomic, assign) NSTimeInterval fadeInDuration;

/**
 The duration for fading out anaimation when hide method is called. Default value is 0.7f.
 */
@property (nonatomic, assign) NSTimeInterval fadeOutDuration;

/**
 Here you can specify the color that is used for displayed text and pie progress if used. Default color is black.
 */
@property (nonatomic, strong) UIColor *contentColor;

/**
 The type of animation when HUD is going to hide. On iOS6 every animation you set is done with fading
 because UIKit Dynamics requires iOS7
 */
@property (nonatomic, assign) HUDProgressAnimationType hideAnimationType;

/**
 The type of animation when HUD is going to show. On iOS6 every animation you set is done with fading
 because UIKit Dynamics requires iOS7
 */
@property (nonatomic, assign) HUDProgressAnimationType showAnimationType;


/**-------------------------------------------------------------------------------------
 @name Showing of HUD
 ---------------------------------------------------------------------------------------
 */

/**
 Shows a message with image on the HUD
 @param text The text that is displayed on the HUD
 @param image The image that is displayed on the HUD
 */
- (void)showWithText:(NSString *)text image:(UIImage *)image;

/**
 Shows a message with progress on the HUD
 @param text The text that is displayed on the HUD
 @param progressType The type of progress indicator to show in animation
 */
- (void)showWithText:(NSString *)text progressType:(HUDProgressType)progressType;


/**-------------------------------------------------------------------------------------
 @name Updating of tex and image
 ---------------------------------------------------------------------------------------
 */

/**
 Update (set) text
 
 @param text The text to be (set) updated
 */
- (void)setText:(NSString *)text;

/**
 Update (set) image
 
 @param image The image to be (set) updated
 */
- (void)setImage:(UIImage *)image;


/**-------------------------------------------------------------------------------------
 @name Hiding of HUD
 ---------------------------------------------------------------------------------------
 */

/**
 Hides the displayed HUD with fading out animation
 */
- (void)hide;

/**
 Hides the displayed HUD after a given delay by fading out
 
 @param delay The time after HUD starts to fade out
 */
- (void)hideAfterDelay:(NSTimeInterval)delay;

/**-------------------------------------------------------------------------------------
 @name Progress
 ---------------------------------------------------------------------------------------
 */

/**
 Set progress when HUDProgressTypePie is used
 
 @param progress The progress percentage
 */
- (void)setProgress:(float)progress;

@end
