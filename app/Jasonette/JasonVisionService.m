//
//  JasonVisionService.m
//  Jasonette
//
//  Created by e on 10/25/17.
//  Copyright © 2017 Jasonette. All rights reserved.
//

#import "JasonVisionService.h"

@implementation JasonVisionService
- (void) initialize: (NSDictionary *)launchOptions {
    self.is_open = NO;
}
- (void)captureOutput:(AVCaptureOutput *)output didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    
    if(!self.is_open) return;
    
    NSDictionary *events = [[[Jason client] getVC] valueForKey:@"events"];
    if(![JasonMemory client].executing) {
      for (AVMetadataObject *metadata in metadataObjects) {
        if ([metadata.type isEqualToString:AVMetadataObjectTypeQRCode]) {
            AVMetadataMachineReadableCodeObject *transformed = (AVMetadataMachineReadableCodeObject *)metadata;
            self.is_open = NO;
            [[Jason client] call: events[@"$vision.onscan"] with: @{
                @"$jason": @{
                   @"content": transformed.stringValue,
                   @"corners": transformed.corners,
                   @"type": transformed.type,
                   @"bounds": @{
                       @"left": [NSNumber numberWithFloat: transformed.bounds.origin.x],
                       @"top": [NSNumber numberWithFloat: transformed.bounds.origin.y],
                       @"width": [NSNumber numberWithFloat: transformed.bounds.size.width],
                       @"height": [NSNumber numberWithFloat: transformed.bounds.size.height]
                   }
                }
           }];
           return;
        }
      }
    }
}

@end
