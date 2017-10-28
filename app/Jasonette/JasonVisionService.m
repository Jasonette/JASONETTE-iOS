//
//  JasonVisionService.m
//  Jasonette
//
//  Created by e on 10/25/17.
//  Copyright © 2017 Jasonette. All rights reserved.
//

#import "JasonVisionService.h"

/**
 * When a code is recognized, this service:
 *
 * [1] triggers the event "$vision.onscan" with the following payload:
 *
 * {
 *   "$jason": {
 *     "type": "org.iso.QRCode",
 *     "content": "hello world"
 *   }
 * }
 *
 * the "type" attribute is different for iOS and Android. In case of Android it returns a number code specified at:
 *  https://developers.google.com/android/reference/com/google/android/gms/vision/barcode/Barcode.html#constants
 *
 * [2] Then immediately stops scanning.
 * [3] To start scanning again, you need to call $vision.scan again
 *
 */


@implementation JasonVisionService
- (void) initialize: (NSDictionary *)launchOptions {
    self.is_open = NO;
}
- (void)captureOutput:(AVCaptureOutput *)output didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    
    if(!self.is_open) return;
    
    NSDictionary *events = [[[Jason client] getVC] valueForKey:@"events"];
    if(![JasonMemory client].executing) {
      for (AVMetadataObject *metadata in metadataObjects) {
          AVMetadataMachineReadableCodeObject *transformed = (AVMetadataMachineReadableCodeObject *)metadata;
          self.is_open = NO;
          [[Jason client] call: events[@"$vision.onscan"] with: @{
              @"$jason": @{
                  @"content": transformed.stringValue,
                  @"type": transformed.type
                  //                   @"corners": transformed.corners,
                  //                   @"bounds": @{
                  //                       @"left": [NSNumber numberWithFloat: transformed.bounds.origin.x],
                  //                       @"top": [NSNumber numberWithFloat: transformed.bounds.origin.y],
                  //                       @"width": [NSNumber numberWithFloat: transformed.bounds.size.width],
                  //                       @"height": [NSNumber numberWithFloat: transformed.bounds.size.height]
                  //                   }
              }
          }];
          return;
      }
    }
}

@end
