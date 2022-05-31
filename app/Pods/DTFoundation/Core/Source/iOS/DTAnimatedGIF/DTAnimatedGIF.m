//
//  DTAnimatedGIF.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 7/2/14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

#import "DTAnimatedGIF.h"

#if TARGET_OS_IPHONE

#import <ImageIO/ImageIO.h>

// returns the frame duration for a given image in 1/100th seconds
// source: http://stackoverflow.com/questions/16964366/delaytime-or-unclampeddelaytime-for-gifs
static NSUInteger DTAnimatedGIFFrameDurationForImageAtIndex(CGImageSourceRef source, NSUInteger index)
{
	NSUInteger frameDuration = 10;
	
	NSDictionary *frameProperties = CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(source,index,nil));
	NSDictionary *gifProperties = frameProperties[(NSString *)kCGImagePropertyGIFDictionary];
	
	NSNumber *delayTimeUnclampedProp = gifProperties[(NSString *)kCGImagePropertyGIFUnclampedDelayTime];
	
	if(delayTimeUnclampedProp)
	{
		frameDuration = [delayTimeUnclampedProp floatValue]*100;
	}
	else
	{
		NSNumber *delayTimeProp = gifProperties[(NSString *)kCGImagePropertyGIFDelayTime];
		
		if(delayTimeProp)
		{
			frameDuration = [delayTimeProp floatValue]*100;
		}
	}
	
	// Many annoying ads specify a 0 duration to make an image flash as quickly as possible.
	// We follow Firefox's behavior and use a duration of 100 ms for any frames that specify
	// a duration of <= 10 ms. See <rdar://problem/7689300> and <http://webkit.org/b/36082>
	// for more information.
	
	if (frameDuration < 1)
	{
		frameDuration = 10;
	}
	
	return frameDuration;
}

// returns the great common factor of two numbers
static NSUInteger DTAnimatedGIFGreatestCommonFactor(NSUInteger num1, NSUInteger num2)
{
	NSUInteger t, remainder;
	
	if (num1 < num2)
	{
		t = num1;
		num1 = num2;
		num2 = t;
	}
	
	remainder = num1 % num2;
	
	if (!remainder)
	{
		return num2;
	}
	else
	{
		return DTAnimatedGIFGreatestCommonFactor(num2, remainder);
	}
}

static UIImage *DTAnimatedGIFFromImageSource(CGImageSourceRef source)
{
	size_t const numImages = CGImageSourceGetCount(source);
	
	NSMutableArray *frames = [NSMutableArray arrayWithCapacity:numImages];
	
	// determine gretest common factor of all image durations
	NSUInteger greatestCommonFactor = DTAnimatedGIFFrameDurationForImageAtIndex(source, 0);
	
	for (NSUInteger i=1; i<numImages; i++)
	{
		NSUInteger centiSecs = DTAnimatedGIFFrameDurationForImageAtIndex(source, i);
		greatestCommonFactor = DTAnimatedGIFGreatestCommonFactor(greatestCommonFactor, centiSecs);
	}
	
	// build array of images, duplicating as necessary
	for (NSUInteger i=0; i<numImages; i++)
	{
		CGImageRef cgImage = CGImageSourceCreateImageAtIndex(source, i, NULL);
		UIImage *frame = [UIImage imageWithCGImage:cgImage];
		
		NSUInteger centiSecs = DTAnimatedGIFFrameDurationForImageAtIndex(source, i);
		NSUInteger repeat = centiSecs/greatestCommonFactor;
		
		for (NSUInteger j=0; j<repeat; j++)
		{
			[frames addObject:frame];
		}
		
		CGImageRelease(cgImage);
	}
	
	// create animated image from the array
	NSTimeInterval totalDuration = [frames count] * greatestCommonFactor / 100.0;
	return [UIImage animatedImageWithImages:frames duration:totalDuration];
}

UIImage * _Nullable DTAnimatedGIFFromFile(NSString  * _Nonnull path)
{
	NSURL *URL = [NSURL fileURLWithPath:path];
	CGImageSourceRef source = CGImageSourceCreateWithURL((__bridge CFURLRef)(URL), NULL);
	
	if (!source)
	{
		return nil;
	}
	
	UIImage *image = DTAnimatedGIFFromImageSource(source);
	CFRelease(source);
	
	return image;
}

UIImage * _Nullable DTAnimatedGIFFromData(NSData * _Nonnull data)
{
	CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)(data), NULL);
	
	if (!source)
	{
		return nil;
	}

	UIImage *image = DTAnimatedGIFFromImageSource(source);
	CFRelease(source);
	
	return image;
}

#endif
