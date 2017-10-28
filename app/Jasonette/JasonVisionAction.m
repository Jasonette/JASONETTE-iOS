//
//  JasonVisionAction.m
//  Jasonette
//
//  Created by e on 10/25/17.
//  Copyright © 2017 Jasonette. All rights reserved.
//

#import "JasonVisionAction.h"

@implementation JasonVisionAction
/**
* {
*     "type": "$vision.scan"
* }
*
* Scans code specified in
*   https://developer.apple.com/documentation/avfoundation/avmetadataobjecttype?language=objc for iOS
*   https://developers.google.com/vision/android/barcodes-overview for Android
*/

- (void) scan {
    JasonVisionService *service = [Jason client].services[@"JasonVisionService"];
    service.is_open = YES;
    [[Jason client] success];
}
@end
