//
//  RMAction.m
//  RMActionController-Demo
//
//  Created by Roland Moers on 19.11.16.
//  Copyright © 2016 Roland Moers. All rights reserved.
//

#import "RMAction+Private.h"

#import "RMActionController+Private.h"
#import "NSProcessInfo+RMActionController.h"

@interface RMAction ()

@property (nonatomic, strong, readwrite) UIView *view;

@property (nonatomic, strong, readwrite) NSString *title;
@property (nonatomic, strong, readwrite) UIImage *image;

@end

@implementation RMAction

#pragma mark - Class
+ (instancetype)actionWithTitle:(NSString *)title style:(RMActionStyle)style andHandler:(void (^)(RMActionController<UIView *> * _Nonnull))handler {
    RMAction *action = [[self class] actionWithStyle:style andHandler:handler];
    action.title = title;
    
    return action;
}

+ (instancetype)actionWithImage:(UIImage *)image style:(RMActionStyle)style andHandler:(void (^)(RMActionController<UIView *> * _Nonnull controller))handler {
    RMAction *action = [[self class] actionWithStyle:style andHandler:handler];
    action.image = image;
    
    return action;
}

+ (instancetype)actionWithTitle:(NSString *)title image:(UIImage *)image style:(RMActionStyle)style andHandler:(void (^)(RMActionController<UIView *> * _Nonnull controller))handler {
    RMAction *action = [[self class] actionWithStyle:style andHandler:handler];
    action.title = title;
    action.image = image;
    
    return action;
}

+ (instancetype)actionWithStyle:(RMActionStyle)style andHandler:(void (^)(RMActionController<UIView *> *controller))handler {
    RMAction *action = [[[self class] alloc] init];
    action.style = style;
    
    __weak RMAction *weakAction = action;
    [action setHandler:^(RMActionController *controller) {
        if(handler) {
            handler(controller);
        }
        
        if(weakAction.dismissesActionController) {
            if(controller.modalPresentationStyle == UIModalPresentationPopover || controller.yConstraint != nil) {
                [controller dismissViewControllerAnimated:YES completion:nil];
            } else {
                [controller dismissViewControllerAnimated:NO completion:nil];
            }
        }
    }];
    
    return action;
}

#pragma mark - Init and Dealloc
- (instancetype)init {
    self = [super init];
    if(self) {
        self.dismissesActionController = YES;
    }
    return self;
}

#pragma mark - Cancel Helper
- (BOOL)containsCancelAction {
    return self.style == RMActionStyleCancel;
}

- (void)executeHandlerOfCancelActionWithController:(RMActionController *)controller {
    if(self.style == RMActionStyleCancel) {
        self.handler(controller);
    }
}

#pragma mark - Other Helper
- (UIImage *)imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0, 0, 1, 1);
    
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    [color setFill];
    UIRectFill(rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

#pragma mark - View
- (UIView *)view {
    if(!_view) {
        _view = [self loadView];
        _view.translatesAutoresizingMaskIntoConstraints = NO;
    }
    
    return _view;
}

- (UIView *)loadView {
    UIButtonType buttonType = UIButtonTypeCustom;
    if(self.controller.disableBlurEffectsForActions) {
        buttonType = UIButtonTypeSystem;
    }
    
    UIButton *actionButton = [UIButton buttonWithType:buttonType];
    [actionButton addTarget:self action:@selector(actionTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    if(self.style == RMActionStyleCancel) {
        actionButton.titleLabel.font = [UIFont boldSystemFontOfSize:[UIFont buttonFontSize]];
    } else {
        actionButton.titleLabel.font = [UIFont systemFontOfSize:[UIFont buttonFontSize]];
    }
    
    if(!self.controller.disableBlurEffectsForActions) {
        [actionButton setBackgroundImage:[self imageWithColor:[[UIColor whiteColor] colorWithAlphaComponent:0.3]] forState:UIControlStateHighlighted];
    } else {
        switch (self.controller.style) {
            case RMActionControllerStyleWhite:
            case RMActionControllerStyleSheetWhite:
                [actionButton setBackgroundImage:[self imageWithColor:[UIColor colorWithWhite:0.2 alpha:1]] forState:UIControlStateHighlighted];
                break;
            case RMActionControllerStyleBlack:
            case RMActionControllerStyleSheetBlack:
                [actionButton setBackgroundImage:[self imageWithColor:[UIColor colorWithWhite:0.8 alpha:1]] forState:UIControlStateHighlighted];
                break;
        }
    }
    
    if(self.title) {
        [actionButton setTitle:self.title forState:UIControlStateNormal];
    } else if(self.image) {
        [actionButton setImage:self.image forState:UIControlStateNormal];
    }
    
    [actionButton addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[actionButton(height)]" options:0 metrics:@{@"height": @([NSProcessInfo runningAtLeastiOS9] ? 55 : 44)} views:NSDictionaryOfVariableBindings(actionButton)]];
    
    if(self.style == RMActionStyleDestructive) {
        [actionButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    }
    
    return actionButton;
}

- (void)actionTapped:(id)sender {
    self.handler(self.controller);
}

@end
