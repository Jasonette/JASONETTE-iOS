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
*     "type": "$vision.scan",
*     "options": {
*         "type": "qrcode"
*     }
* }
*/

/* Triggers "$vision.onscan" event */

- (void) scan {
    // Add output to the session
    JasonVisionService *service = [Jason client].services[@"JasonVisionService"];
    service.is_open = YES;
    [[Jason client] success];
}
@end
