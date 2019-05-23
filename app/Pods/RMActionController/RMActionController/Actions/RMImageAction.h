//
//  RMImageAction.h
//  RMImageAction-Demo
//
//  Created by Roland Moers on 19.11.16.
//  Copyright © 2016 Roland Moers. All rights reserved.
//

#import "RMAction.h"

/**
 *  Like RMAction, RMImageAction represents an action that can be tapped by the use when a RMActionController is presented.
 *
 *  In contrast to RMAction, it show an image with a title below the image (very much like the Apple share sheet).
 */
@interface RMImageAction<T : UIView *> : RMAction<T>

@end
