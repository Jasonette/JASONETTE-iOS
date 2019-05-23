//
//  RMActionController+Private.h
//  RMActionController-Demo
//
//  Created by Roland Moers on 19.11.16.
//  Copyright © 2016 Roland Moers. All rights reserved.
//

#import "RMActionController.h"

@interface RMActionController ()

@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, assign) BOOL hasBeenDismissed;

@property (nonatomic, weak) NSLayoutConstraint *yConstraint;

- (void)setupTopContainersTopMarginConstraint;

@end
