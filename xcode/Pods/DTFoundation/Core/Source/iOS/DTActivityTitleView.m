//
//  DTActivityTitleView.m
//  DTFoundation
//
//  Created by Rene Pirringer on 12.09.12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import "DTActivityTitleView.h"

@interface DTActivityTitleView ()

@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) UILabel *titleLabel;

@end


@implementation DTActivityTitleView

- (id)init
{
	self = [super init];
	
	if (self)
	{
		self.titleLabel = [[UILabel alloc] init];
		self.titleLabel.backgroundColor = [UIColor clearColor];
		
		self.activityIndicator.hidesWhenStopped = YES;
		
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		{
#if TARGET_OS_TV
			self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
#else
            self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
#endif
			self.titleLabel.textColor = [UIColor colorWithRed:113.0/255.0 green:120.0/255.0 blue:128.0/255.0 alpha:1.0];
			self.titleLabel.shadowOffset = CGSizeMake(0, 1);
			self.titleLabel.shadowColor = [UIColor whiteColor];
		}
		else
		{
			self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
			self.titleLabel.textColor = [UIColor whiteColor];
			self.titleLabel.shadowOffset = CGSizeMake(0, -1);
			self.titleLabel.shadowColor = [UIColor blackColor];
		}
		
		self.titleLabel.font = [UIFont boldSystemFontOfSize:20];
		[self addSubview:self.titleLabel];
		[self addSubview:self.activityIndicator];
	}
	return self;
}

- (void)layoutSubviews
{
	[super layoutSubviews];
}

#pragma mark - Properties

- (void)setBusy:(BOOL)busy
{
	if (busy)
	{
		[self.activityIndicator startAnimating];
	}
	else
	{
		[self.activityIndicator stopAnimating];
	}
	
	[self setNeedsLayout];
}

- (BOOL)busy
{
	return self.activityIndicator.isAnimating;
}

- (void)setTitle:(NSString *)title
{
	self.titleLabel.text = title;
	CGFloat gap = 5.0;
	CGFloat height = self.activityIndicator.frame.size.height;
	
#if __IPHONE_OS_VERSION_MIN_REQUIRED > __IPHONE_6_1
	// issue 60: sizeWithFont: is deprecated with deployment target >= iOS 7
	NSDictionary *attribs = @{NSFontAttributeName:self.titleLabel.font};
	CGSize neededSize = [self.titleLabel.text sizeWithAttributes:attribs];
#else
	CGSize neededSize = [self.titleLabel.text sizeWithFont:self.titleLabel.font];
#endif
	
	if (height < neededSize.height)
	{
		height = neededSize.height;
	}
	
	CGRect titleRect = CGRectMake(self.activityIndicator.frame.size.width+gap, 0, neededSize.width, height);
	self.titleLabel.frame = titleRect;
	self.bounds  = CGRectMake(0, 0, self.activityIndicator.frame.size.width+neededSize.width+gap, height);
	[self setNeedsLayout];
}

- (NSString *)title
{
	return self.titleLabel.text;
}

@synthesize activityIndicator = _activityIndicator;

@end