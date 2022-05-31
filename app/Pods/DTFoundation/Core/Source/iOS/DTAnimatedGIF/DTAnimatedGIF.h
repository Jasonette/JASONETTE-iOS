//
//  DTAnimatedGIF.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 7/2/14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

#import <Availability.h>
#import <TargetConditionals.h>

#if TARGET_OS_IPHONE

#import <UIKit/UIKit.h>


/**
 Loads an animated GIF from file, compatible with UIImageView
 */
UIImage *DTAnimatedGIFFromFile(NSString *path);

/**
 Loads an animated GIF from data, compatible with UIImageView
 */
UIImage *DTAnimatedGIFFromData(NSData *data);

#endif
