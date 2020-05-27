//
//  NSString+DTUTI.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 03.10.12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import "NSString+DTUTI.h"

#if TARGET_OS_IPHONE
#import <MobileCoreServices/MobileCoreServices.h>
#endif

@implementation NSString (DTUTI)

+ (NSString *)MIMETypeForFileExtension:(NSString *)extension
{
	CFStringRef typeForExt = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,(__bridge CFStringRef)extension , NULL);
	NSString *result = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass(typeForExt, kUTTagClassMIMEType);
	CFRelease(typeForExt);
	if (!result)
	{
		return @"application/octet-stream";
	}
	
	return result;
}

+ (NSString *)fileTypeDescriptionForFileExtension:(NSString *)extension
{
	CFStringRef typeForExt = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,(__bridge CFStringRef)extension , NULL);
	NSString *result = (__bridge_transfer NSString *)UTTypeCopyDescription(typeForExt);
	CFRelease(typeForExt);
	return result;
}

+ (NSString *)universalTypeIdentifierForFileExtension:(NSString *)extension
{
	return (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,(__bridge CFStringRef)extension , NULL);
}

+ (NSString *)fileExtensionForUniversalTypeIdentifier:(NSString *)UTI
{
	return (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)(UTI), kUTTagClassFilenameExtension);
}

- (BOOL)conformsToUniversalTypeIdentifier:(NSString *)conformingUTI
{
	return UTTypeConformsTo((__bridge CFStringRef)(self), (__bridge CFStringRef)conformingUTI);
}

- (BOOL)isMovieFileName
{
	NSString *extension = [self pathExtension];
    
    // without extension we cannot know
    if (![extension length])
    {
        return NO;
    }

	NSString *uti = [NSString universalTypeIdentifierForFileExtension:extension];

	return [uti conformsToUniversalTypeIdentifier:@"public.movie"];
}

- (BOOL)isAudioFileName
{
	NSString *extension = [self pathExtension];
    
    // without extension we cannot know
    if (![extension length])
    {
        return NO;
    }

	NSString *uti = [NSString universalTypeIdentifierForFileExtension:extension];
	
	return [uti conformsToUniversalTypeIdentifier:@"public.audio"];
}

- (BOOL)isImageFileName
{
	NSString *extension = [self pathExtension];

    // without extension we cannot know
    if (![extension length])
    {
        return NO;
    }
    
	NSString *uti = [NSString universalTypeIdentifierForFileExtension:extension];
	
	return [uti conformsToUniversalTypeIdentifier:@"public.image"];
}

- (BOOL)isHTMLFileName
{
	NSString *extension = [self pathExtension];
    
    // without extension we cannot know
    if (![extension length])
    {
        return NO;
    }

	NSString *uti = [NSString universalTypeIdentifierForFileExtension:extension];
	
	return [uti conformsToUniversalTypeIdentifier:@"public.html"];
}


@end