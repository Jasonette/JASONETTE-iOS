//
//  DTProgressHUD.m
//  DTFoundation
//
//  Created by Stefan Gugarel on 07.05.14.
//  Copyright 2014 Cocoanetics. All rights reserved.
//

#import "DTProgressHUD.h"

#if TARGET_OS_IPHONE && !TARGET_OS_TV && !TARGET_OS_WATCH

#import "DTProgressHUDWindow.h"

#import "DTPieProgressIndicator.h"

#define PROGRESS_WIDTH 150.0
#define PROGRESS_HEIGHT 150.0

#define MAX_TEXT_HEIGHT 50.0

#define MARGIN 10.0

#define MARGIN_IMAGE 20.0

#define BARRIER_LENGTH 30.0

#define DEFAULT_FADE_IN_ANIMATION_DURATION 0.3
#define DEFAULT_FADE_OUT_ANIMATION_DURATION 0.7

#define OS_IS_IOS7() (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1)


@interface DTProgressHUD () <UIDynamicAnimatorDelegate, UICollisionBehaviorDelegate>

@property (nonatomic, strong) UILabel *textLabel;

@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation DTProgressHUD
{
	UIView *_hudView;
	
	HUDProgressType _currentHUDProgressType;
	
	DTPieProgressIndicator *_pieProgressIndicator;
	
	UIActivityIndicatorView *_activityIndicator;
	
	UIDynamicAnimator *_animator;
	
	UIGravityBehavior *_gravity;
	
	BOOL _hidden;
	
	DTProgressHUDWindow *_hudWindow;
}

- (instancetype)init
{
	self = [super initWithFrame:[UIScreen mainScreen].bounds];
	if (self)
	{
		[self _commonInit];
	}
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if (self)
	{
		[self _commonInit];
	}
	return self;
}

- (void)_commonInit
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
	
	CGRect bounds = CGRectMake(0, 0, PROGRESS_WIDTH, PROGRESS_HEIGHT);
	
	if (OS_IS_IOS7())
	{
		// On iOS7 we use a toolbar to blur the background
		_hudView = [[UIToolbar alloc] initWithFrame:bounds];
	}
	else
	{
		_hudView = (DTProgressHUD *)[[UIView alloc] initWithFrame:bounds];
		_hudView.backgroundColor = [UIColor colorWithWhite:0.87 alpha:0.95];
	}
	
	[self addSubview:_hudView];
	
	// center HUD in the middle of the screen
	_hudView.center = self.center;
	
	// set correct autoresizing masks
	_hudView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
	
	// Set rounded edges
	_hudView.layer.cornerRadius = 13;
	_hudView.layer.masksToBounds = YES;
	
	// initially hide
	_hudView.alpha = 0.0;
	
	// set default animation duration
	_fadeInDuration = DEFAULT_FADE_IN_ANIMATION_DURATION;
	_fadeOutDuration = DEFAULT_FADE_OUT_ANIMATION_DURATION;
	
	_contentColor = [UIColor blackColor];
	
	self.userInteractionEnabled = NO;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)deviceOrientationDidChange:(NSNotification *)notification
{
	[self _resetAnimation];
}


#pragma mark - Showing

- (void)showWithText:(NSString *)text image:(UIImage *)image
{
	[self _prepareForReuse];
	
	[self _configureTextLabel:text];
	
	[self _configureImageView];
	
	self.textLabel.text = text;
	
	self.imageView.image = image;
	
	[self _showAnimation];
}

- (void)showWithText:(NSString *)text progressType:(HUDProgressType)progressType
{
	[self _prepareForReuse];
	
	self.textLabel.text = text;
	
	_currentHUDProgressType = progressType;
	
	switch (progressType)
	{
		case HUDProgressTypeInfinite:
		{
			if (@available(iOS 13, tvOS 13, *)) {
				_activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
			}
			else
			{
				#if TARGET_OS_TV
				_activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
				#else
				_activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
				#endif
			}
				
			_activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
			
			[_hudView addSubview:_activityIndicator];
			[_activityIndicator startAnimating];
			
			break;
		}
		case HUDProgressTypePie:
		{
			_pieProgressIndicator = [[DTPieProgressIndicator alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
			_pieProgressIndicator.translatesAutoresizingMaskIntoConstraints = NO;
			_pieProgressIndicator.color = _contentColor;
			
			[_hudView addSubview:_pieProgressIndicator];
			
			break;
		}
	}
	
	[self _configureTextLabel:text];
	
	[self _configureProgressView];
	
	[self _showAnimation];
	
}

- (void)_showAnimation
{
	switch (_showAnimationType)
	{
		case HUDProgressAnimationTypeFade:
		{
			_hudView.alpha = 0.0f;
			
			[UIView animateWithDuration:_fadeInDuration animations:^{
				self->_hudView.alpha = 1.0f;
			}];
			
			break;
		}
			
		case HUDProgressAnimationTypeGravity:
		case HUDProgressAnimationTypeGravityRoll:
		{
			_animator = [[UIDynamicAnimator alloc] initWithReferenceView:self];
			
			CGPoint centerPoint = self.center;
			
			// move outside screen
			centerPoint.y = - PROGRESS_HEIGHT;
			
			_hudView.center = centerPoint;
			_hudView.alpha = 1.0f;
			
			// add gravity behavior
			UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[_hudView]];
			gravity.gravityDirection = CGVectorMake(0.0f, 3.0f);
			
			// add collision behavior
			UICollisionBehavior *collision = [[UICollisionBehavior alloc] initWithItems:@[_hudView]];
			
			// calculate points where HUD should land and jump
			CGPoint leftPoint = CGPointMake(0, self.center.y + PROGRESS_HEIGHT / 2);
			CGPoint rightPoint = CGPointMake(self.bounds.size.width, self.center.y + PROGRESS_HEIGHT / 2);
			[collision addBoundaryWithIdentifier:@"barrier" fromPoint:leftPoint toPoint:rightPoint];
			
			// add behaviors
			[_animator addBehavior:gravity];
			[_animator addBehavior:collision];
			
			_animator.delegate = self;
			
			break;
		}
			
		case HUDProgressAnimationTypeSnap:
		{
			_animator = [[UIDynamicAnimator alloc] initWithReferenceView:self];
			
			_hudView.frame = CGRectMake(self.bounds.size.width, -PROGRESS_HEIGHT, PROGRESS_WIDTH, PROGRESS_HEIGHT);
			_hudView.alpha = 1.0f;
			
			// snap to center
			UISnapBehavior *snapBehaviour = [[UISnapBehavior alloc] initWithItem:_hudView snapToPoint:self.center];
			snapBehaviour.damping = 0.65f;
			[_animator addBehavior:snapBehaviour];
			
			_animator.delegate = self;
			
			break;
		}
		case HUDProgressAnimationTypeGravityTilt:
		{
			CGFloat offset;
			
			CGFloat halfScreenHeight = self.bounds.size.height / 2;
			
			// formula for calculating correct start position depending on height
			// Found values empirical and looked then for a formula
			//
			// height: 512	offset: 105
			// height: 384	offset: 90
			// height: 284  offset: 75.5
			// height: 240	offset: 67.5
			// height: 320	offset: 51.5
			//
			offset = 2.3246449 * pow(halfScreenHeight, 0.61329599);
			
			
			_hudView.alpha = 1.0f;
			_hudView.bounds = CGRectMake(0.0f, 0.0f, PROGRESS_WIDTH, PROGRESS_HEIGHT);
			_hudView.center = CGPointMake(self.center.x - offset, -PROGRESS_HEIGHT / 2);
			
			_animator = [[UIDynamicAnimator alloc] initWithReferenceView:self];
			
			UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[_hudView]];
			gravity.gravityDirection = CGVectorMake(0.0f, 5.0f);
			
			UICollisionBehavior *collision = [[UICollisionBehavior alloc] initWithItems:@[_hudView]];
			
			// Add some HUD behavior
			UIDynamicItemBehavior *hudBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[_hudView]];
			hudBehavior.angularResistance = 40;
			
			// calculate points for barrier
			CGFloat height = self.center.y + PROGRESS_HEIGHT / 2 + 0.5;
			CGPoint leftPoint = CGPointMake(0, height);
			CGPoint rightPoint = CGPointMake(self.bounds.size.width, height);
			
			// add a boundary that coincides with the top edge
			[collision addBoundaryWithIdentifier:@"barrier1" fromPoint:leftPoint toPoint:rightPoint];
			
			// calculate points for barrier
			leftPoint = CGPointMake(0, 0);
			rightPoint = CGPointMake(self.center.x - PROGRESS_WIDTH / 2 - offset + BARRIER_LENGTH, 0);
			[collision addBoundaryWithIdentifier:@"barrier2" fromPoint:leftPoint toPoint:rightPoint];
			
			// snap to center
			UISnapBehavior *snapBehaviour = [[UISnapBehavior alloc] initWithItem:_hudView snapToPoint:self.center];
			snapBehaviour.damping = 1.0f;
			
			collision.collisionDelegate = self;
			
			[_animator addBehavior:gravity];
			[_animator addBehavior:collision];
			[_animator addBehavior:hudBehavior];
			
			break;
		}
	}
}


#pragma mark - Updating

- (void)setText:(NSString *)text
{
	self.textLabel.text = text;
	
	[self _configureTextLabel:text];
}

- (void)setImage:(UIImage *)image
{
	self.imageView.image = image;
}


#pragma mark - Hiding

- (void)hide
{
	_hidden = YES;
	
	switch (_hideAnimationType)
	{
		case HUDProgressAnimationTypeFade:
		{
			[UIView animateWithDuration:_fadeOutDuration animations:^{
				
				// fade out
				self->_hudView.alpha = 0.0f;
			} completion:^(BOOL finished) {
				//
				
			}];
			break;
		}
		case HUDProgressAnimationTypeGravity:
		{
			_animator = [[UIDynamicAnimator alloc] initWithReferenceView:self];
			_gravity = [[UIGravityBehavior alloc] initWithItems:@[_hudView]];
			_gravity.gravityDirection = CGVectorMake(0.0f, 3.0f);
			[_animator addBehavior:_gravity];
			
			_animator.delegate = self;
			
			break;
		}
		case HUDProgressAnimationTypeGravityRoll:
		{
			_animator = [[UIDynamicAnimator alloc] initWithReferenceView:self];
			
			UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[_hudView]];
			gravity.gravityDirection = CGVectorMake(0.0f, 3.0f);
			
			UIDynamicItemBehavior *hudBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[_hudView]];
			hudBehavior.elasticity = 0.0;
			hudBehavior.resistance = 1.0f;
			
			UICollisionBehavior *collision = [[UICollisionBehavior alloc] initWithItems:@[_hudView]];
			
			// calculate points for barrier
			CGFloat height = self.center.y + PROGRESS_HEIGHT / 2 + BARRIER_LENGTH;
			CGPoint leftPoint = CGPointMake(0, height);
			CGPoint rightPoint = CGPointMake(self.center.x - PROGRESS_WIDTH/2 + BARRIER_LENGTH, height);
			
			// add a boundary that coincides with the top edge
			[collision addBoundaryWithIdentifier:@"barrier" fromPoint:leftPoint toPoint:rightPoint];
			
			[_animator addBehavior:gravity];
			[_animator addBehavior:collision];
			[_animator addBehavior:hudBehavior];
			
			_animator.delegate = self;
			
			break;
		}
		case HUDProgressAnimationTypeSnap:
		{
			_animator = [[UIDynamicAnimator alloc] initWithReferenceView:self];
			
			// calculate snap point
			CGPoint toSnapPoint = CGPointMake(0 - PROGRESS_WIDTH, CGRectGetMaxY(self.bounds) + PROGRESS_HEIGHT);
			
			UISnapBehavior *snapBehaviour = [[UISnapBehavior alloc] initWithItem:_hudView snapToPoint:toSnapPoint];
			snapBehaviour.damping = 0.9f;
			[_animator addBehavior:snapBehaviour];
			
			_animator.delegate = self;
			
			break;
		}
		case HUDProgressAnimationTypeGravityTilt:
		{
			
			_animator = [[UIDynamicAnimator alloc] initWithReferenceView:self];
			
			UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[_hudView]];
			gravity.gravityDirection = CGVectorMake(0.0f, 6.0f);
			
			UIDynamicItemBehavior *hudBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[_hudView]];
			hudBehavior.angularResistance = 8;
			
			UICollisionBehavior *collision = [[UICollisionBehavior alloc] initWithItems:@[_hudView]];
			
			// calculate points for barrier
			CGFloat height = self.center.y + PROGRESS_HEIGHT / 2;
			CGPoint leftPoint = CGPointMake(0, height);
			CGPoint rightPoint = CGPointMake(self.center.x - PROGRESS_WIDTH/2 + BARRIER_LENGTH, height);
			
			// add a boundary that coincides with the top edge
			[collision addBoundaryWithIdentifier:@"barrier" fromPoint:leftPoint toPoint:rightPoint];
			
			[_animator addBehavior:gravity];
			[_animator addBehavior:collision];
			[_animator addBehavior:hudBehavior];
			
			_animator.delegate = self;
			
			break;
		}
	}
}

- (void)hideAfterDelay:(NSTimeInterval)delay
{
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		[self hide];
	});
}


#pragma mark - UI layouting

/**
 Configures size and position of textLabel calculated by text
 */
- (void)_configureTextLabel:(NSString *)text
{
	NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text];
	
	NSRange textRange = NSMakeRange(0, text.length);
	
	NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
	paragraphStyle.alignment = self.textLabel.textAlignment;
	
	[attributedString addAttribute:NSFontAttributeName value:self.textLabel.font range:textRange];
	[attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:textRange];
	
	// calculate needed size of textLabel
	CGRect textRect = [attributedString boundingRectWithSize:CGSizeMake(PROGRESS_WIDTH - MARGIN * 2, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin context:nil];
	
	// limit max height of textLabel to 3 lines
	CGFloat maxHeight = MIN(MAX_TEXT_HEIGHT, textRect.size.height);
	
	_textLabel.frame = CGRectMake(MARGIN, _hudView.bounds.size.height - maxHeight - MARGIN, PROGRESS_WIDTH - 2 * MARGIN, maxHeight);
}

/**
 Configure size and position of progress element
 */
- (void)_configureProgressView
{
	switch (_currentHUDProgressType)
	{
		case HUDProgressTypeInfinite:
		{
			[self _centerView:_activityIndicator];
			
			break;
		}
		case HUDProgressTypePie:
		{
			[self _centerView:_pieProgressIndicator];
			
			break;
		}
	}
}
/**
 Configures size and postion of image view
 */
- (void)_configureImageView
{
	CGRect imageRect = _hudView.bounds;
	
	imageRect.size.height -= self.textLabel.bounds.size.height;
	
	CGRect imageFrameWithInsets = UIEdgeInsetsInsetRect(imageRect, UIEdgeInsetsMake(MARGIN_IMAGE, MARGIN_IMAGE, MARGIN_IMAGE, MARGIN_IMAGE));
	
	self.imageView.frame = imageFrameWithInsets;
}

/**
 Centers progress views at the available space (textLabel is calculated dynamically depening on length of text)
 */
- (void)_centerView:(UIView *)view
{
	
	CGFloat height = PROGRESS_HEIGHT - _textLabel.bounds.size.height;
	
	// constraint for centering Y - offset (because of text label below)
	NSLayoutConstraint *centerYConstraint = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_hudView attribute:NSLayoutAttributeCenterY multiplier:1.0f constant:(height-PROGRESS_HEIGHT)/2];
	[_hudView addConstraint:centerYConstraint];
	
	// constraint for centering X
	NSLayoutConstraint *centerXConstraint = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_hudView attribute:NSLayoutAttributeCenterX multiplier:1.0f constant:0.0f];
	[_hudView addConstraint:centerXConstraint];
	
	// constraint for width
	NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0f constant:view.bounds.size.width];
	[_hudView addConstraint:widthConstraint];
	
	// constraint for height
	NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0f constant:view.bounds.size.height];
	[_hudView addConstraint:heightConstraint];
}

/**
 Remove all UI elements that could change
 */
- (void)_prepareForReuse
{
	_hidden = NO;
	
	if (!_hudWindow)
	{
		// use own window
		_hudWindow = [[DTProgressHUDWindow alloc] initWithProgressHUD:self];
		[_hudWindow makeKeyAndVisible];
	}
	
	if (_animator)
	{
		[self _resetAnimation];
	}
	
	if (_pieProgressIndicator)
	{
		[_pieProgressIndicator removeFromSuperview];
		_pieProgressIndicator = nil;
	}
	
	if (_activityIndicator)
	{
		[_activityIndicator removeFromSuperview];
		_activityIndicator = nil;
	}
	
	if (_imageView)
	{
		[_imageView removeFromSuperview];
		_imageView = nil;
	}
}

- (void)_resetAnimation
{
	if (_animator && !_hidden)
	{
		[_animator removeAllBehaviors];
		
		// remove all transformations, rotations, ...
		_hudView.transform = CGAffineTransformIdentity;
		
		// set to original bounds
		_hudView.bounds = CGRectMake(0, 0, PROGRESS_WIDTH, PROGRESS_HEIGHT);
		
		// center HUD
		_hudView.center = self.center;
		
		// reset autoresizingMask
		_hudView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
		
		_animator = nil;
	}
}


#pragma mark - Progress

- (void)setProgress:(float)progress
{
	if (_pieProgressIndicator)
	{
		_pieProgressIndicator.progressPercent = progress;
	}
}


#pragma mark - UIDynamicAnimator

- (void)dynamicAnimatorDidPause:(UIDynamicAnimator *)animator
{
	[self _resetAnimation];
}


#pragma mark - Properties

- (UILabel *)textLabel
{
	if (!_textLabel)
	{
		_textLabel = [[UILabel alloc] init];
		_textLabel.textColor = _contentColor;
		_textLabel.font = [UIFont boldSystemFontOfSize:13.0];
		_textLabel.backgroundColor = [UIColor clearColor];
		_textLabel.textAlignment = NSTextAlignmentCenter;
		_textLabel.numberOfLines = 0;
		
		[_hudView addSubview:_textLabel];
	}
	
	return _textLabel;
}

- (UIImageView *)imageView
{
	// Image
	if (!_imageView)
	{
		_imageView = [[UIImageView alloc] init];
		_imageView.contentMode = UIViewContentModeScaleAspectFit;
		[_hudView addSubview:_imageView];
	}
	
	return _imageView;
}

- (void)setShowAnimationType:(HUDProgressAnimationType)showAnimationType
{
	if (OS_IS_IOS7())
	{
		_showAnimationType = showAnimationType;
	}
	else
	{
		_showAnimationType = HUDProgressAnimationTypeFade;
	}
}

- (void)setHideAnimationType:(HUDProgressAnimationType)hideAnimationType
{
	if (OS_IS_IOS7())
	{
		_hideAnimationType = hideAnimationType;
	}
	else
	{
		_hideAnimationType = HUDProgressAnimationTypeFade;
	}
}

@end

#endif
