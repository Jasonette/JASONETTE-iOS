//
//  JasonConstraintsViewController.h
//  Jasonette
//
//  Created by Camilo Castro on 15-07-19.
//  Copyright © 2019 Jasonette. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface JasonConstraintsViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIView * fullscreen;

+ (CGRect) fullScreenBounds;

@end

NS_ASSUME_NONNULL_END
