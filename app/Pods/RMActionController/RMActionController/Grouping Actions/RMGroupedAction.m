//
//  RMGroupedAction.m
//  RMActionController-Demo
//
//  Created by Roland Moers on 19.11.16.
//  Copyright © 2016 Roland Moers. All rights reserved.
//

#import "RMGroupedAction.h"

#import "RMAction+Private.h"
#import "UIView+RMActionController.h"

@interface RMGroupedAction ()

@property (nonatomic, strong, readwrite) NSArray *actions;

@end

@implementation RMGroupedAction

#pragma mark - Class
+ (nullable instancetype)actionWithTitle:(nonnull NSString *)title style:(RMActionStyle)style andHandler:(nullable void (^)(RMActionController<UIView *> * __nonnull))handler {
    [NSException raise:@"RMIllegalCallException" format:@"Tried to initialize a grouped action with +[%@ %@]. Please use +[%@ %@] instead.", NSStringFromClass(self), NSStringFromSelector(_cmd), NSStringFromClass(self), NSStringFromSelector(@selector(actionWithStyle:andActions:))];
    return nil;
}

+ (nullable instancetype)actionWithImage:(nonnull UIImage *)image style:(RMActionStyle)style andHandler:(nullable void (^)(RMActionController<UIView *> * __nonnull))handler {
    [NSException raise:@"RMIllegalCallException" format:@"Tried to initialize a grouped action with +[%@ %@]. Please use +[%@ %@] instead.", NSStringFromClass(self), NSStringFromSelector(_cmd), NSStringFromClass(self), NSStringFromSelector(@selector(actionWithStyle:andActions:))];
    return nil;
}

+ (instancetype)actionWithTitle:(NSString *)title image:(UIImage *)image style:(RMActionStyle)style andHandler:(void (^)(RMActionController<UIView *> * _Nonnull))handler {
    [NSException raise:@"RMIllegalCallException" format:@"Tried to initialize a grouped action with +[%@ %@]. Please use +[%@ %@] instead.", NSStringFromClass(self), NSStringFromSelector(_cmd), NSStringFromClass(self), NSStringFromSelector(@selector(actionWithStyle:andActions:))];
    return nil;
}

+ (nullable instancetype)actionWithStyle:(RMActionStyle)style andActions:(nonnull NSArray<RMAction<UIView *> *> *)actions {
    NSAssert([actions count] > 0, @"Tried to initialize RMGroupedAction with less than one action.");
    NSAssert([actions count] > 1, @"Tried to initialize RMGroupedAction with one action. Use RMAction in this case.");
    
    [actions enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSAssert([obj isKindOfClass:[RMAction class]], @"Tried to initialize RMGroupedAction with objects of types other than RMAction.");
    }];
    
    RMGroupedAction *groupedAction = [[[self class] alloc] init];
    groupedAction.style = style;
    groupedAction.actions = actions;
    
    [groupedAction setHandler:^(RMActionController *controller) {
        [NSException raise:@"RMInconsistencyException" format:@"The handler of a grouped action has been called."];
    }];
    
    return groupedAction;
}

#pragma mark - Cancel Helper
- (BOOL)containsCancelAction {
    for(RMAction *anAction in self.actions) {
        if([anAction containsCancelAction]) {
            return YES;
        }
    }
    
    return NO;
}

- (void)executeHandlerOfCancelActionWithController:(RMActionController *)controller {
    for(RMAction *anAction in self.actions) {
        if([anAction containsCancelAction]) {
            [anAction executeHandlerOfCancelActionWithController:controller];
            return;
        }
    }
}

#pragma mark - Properties
- (RMActionController *)controller {
    return [[self.actions firstObject] controller];
    
}

- (void)setController:(RMActionController *)controller {
    for(RMAction *anAction in self.actions) {
        anAction.controller = controller;
    }
}

#pragma mark - View
- (UIView *)loadView {
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    view.backgroundColor = [UIColor clearColor];
    
    NSDictionary *metrics = @{@"seperatorHeight": @(1.f / [[UIScreen mainScreen] scale])};
    
    __block UIView *currentLeft = nil;
    [self.actions enumerateObjectsUsingBlock:^(RMAction *action, NSUInteger index, BOOL *stop) {
        [action.view setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
        [view addSubview:action.view];
        
        if(index == 0) {
            NSDictionary *bindings = @{@"actionView": action.view};
            
            [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(0)-[actionView]-(0)-|" options:0 metrics:nil views:bindings]];
            [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(0)-[actionView]" options:0 metrics:nil views:bindings]];
        } else {
            UIView *seperatorView = [UIView seperatorView];
            [view addSubview:seperatorView];
            
            NSDictionary *bindings = @{@"actionView": action.view, @"seperator": seperatorView, @"currentLeft": currentLeft};
            
            [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(0)-[actionView]-(0)-|" options:0 metrics:nil views:bindings]];
            [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(0)-[seperator]-(0)-|" options:0 metrics:nil views:bindings]];
            [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[currentLeft(==actionView)]-(0)-[seperator(seperatorHeight)]-(0)-[actionView(==currentLeft)]" options:0 metrics:metrics views:bindings]];
        }
        
        currentLeft = action.view;
    }];
    
    NSDictionary *bindings = @{@"currentLeft": currentLeft};
    
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[currentLeft]-(0)-|" options:0 metrics:nil views:bindings]];
    
    return view;
}

@end
