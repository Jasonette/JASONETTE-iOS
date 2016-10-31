//
//  APImageExtractor 
//  AddressBook
//
//  Created by Alexey Belkevich on 29.09.15.
//  Copyright © 2015 alterplay. All rights reserved.
//

#import "APImageExtractor.h"

@implementation APImageExtractor

#pragma mark - public

+ (UIImage *)thumbnailWithRecordRef:(ABRecordRef)recordRef
{
    return [self imageWithRecordRef:recordRef fullSize:NO];
}

+ (UIImage *)photoWithRecordRef:(ABRecordRef)recordRef
{
    return [self imageWithRecordRef:recordRef fullSize:YES];
}

#pragma mark - private

+ (UIImage *)imageWithRecordRef:(ABRecordRef)recordRef fullSize:(BOOL)isFullSize
{
    ABPersonImageFormat format = isFullSize ? kABPersonImageFormatOriginalSize :
                                 kABPersonImageFormatThumbnail;
    NSData *data = (__bridge_transfer NSData *)ABPersonCopyImageDataWithFormat(recordRef, format);
    return [UIImage imageWithData:data scale:UIScreen.mainScreen.scale];
}

@end