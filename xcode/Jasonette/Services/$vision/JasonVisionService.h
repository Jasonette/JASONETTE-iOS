//
//  JasonVisionService.h
//  Jasonette
//
//  Created by e on 10/25/17.
//  Copyright © 2017 Jasonette. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "Jason.h"
#import "JasonMemory.h"

@interface JasonVisionService : NSObject <AVCaptureMetadataOutputObjectsDelegate>
@property (nonatomic, assign) BOOL is_open;
@end
