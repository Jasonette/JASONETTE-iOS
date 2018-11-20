/* Copyright 2017 Urban Airship and Contributors */


#import "UANotificationCategory.h"
#import "UANotificationAction.h"

@interface UANotificationCategory ()
@property(nonatomic, copy) NSString *identifier;
@property(nonatomic, copy) NSArray<UANotificationAction *> *actions;

/**
 * The intents supported by notifications of this category.
 *
 * Note: This property is only applicable on iOS 10 and above.
 */
@property(nonatomic, copy, nullable) NSArray<NSString *> *intentIdentifiers;

/**
* A placeholder string to display when the user has disabled notification previews for the app.
*
* Note: This property is only applicable on iOS 11 and above.
*/
@property(copy, nonatomic) NSString *hiddenPreviewsBodyPlaceholder;

/**
 * Flag to indicate a placeholder string was specified.
 *
 * Note: This property is only applicable on iOS 11 and above.
 */
@property(assign, nonatomic) BOOL hiddenPreviewsBodyPlaceholderSpecified;

/**
 * Options for how to handle notifications of this type.
 */
@property(nonatomic, assign) UANotificationCategoryOptions options;

@end

@implementation UANotificationCategory

- (instancetype)initWithIdentifier:(NSString *)identifier
                           actions:(NSArray<UANotificationAction *> *)actions
                 intentIdentifiers:(NSArray<NSString *> *)intentIdentifiers
                           options:(UANotificationCategoryOptions)options {
    self = [super init];
    
    if (self) {
        self.identifier = identifier;
        self.actions = actions;
        self.intentIdentifiers = intentIdentifiers;
        self.hiddenPreviewsBodyPlaceholderSpecified = NO;
        self.options = options;
    }
    
    return self;
}

- (instancetype)initWithIdentifier:(NSString *)identifier
                           actions:(NSArray<UANotificationAction *> *)actions
                 intentIdentifiers:(NSArray<NSString *> *)intentIdentifiers
     hiddenPreviewsBodyPlaceholder:(NSString *)hiddenPreviewsBodyPlaceholder
                           options:(UANotificationCategoryOptions)options {
    self = [super init];

    if (self) {
        self.identifier = identifier;
        self.actions = actions;
        self.intentIdentifiers = intentIdentifiers;
        self.hiddenPreviewsBodyPlaceholder = hiddenPreviewsBodyPlaceholder;
        self.hiddenPreviewsBodyPlaceholderSpecified = YES;
        self.options = options;
    }

    return self;
}

+ (instancetype)categoryWithIdentifier:(NSString *)identifier
                               actions:(NSArray<UANotificationAction *> *)actions
                     intentIdentifiers:(NSArray<NSString *> *)intentIdentifiers
                               options:(UANotificationCategoryOptions)options {

    return [[self alloc] initWithIdentifier:identifier
                                    actions:actions
                          intentIdentifiers:intentIdentifiers
                                    options:options];
    
}

+ (instancetype)categoryWithIdentifier:(NSString *)identifier
                               actions:(NSArray<UANotificationAction *> *)actions
                     intentIdentifiers:(NSArray<NSString *> *)intentIdentifiers
         hiddenPreviewsBodyPlaceholder:(NSString *)hiddenPreviewsBodyPlaceholder
                               options:(UANotificationCategoryOptions)options {

    return [[self alloc] initWithIdentifier:identifier
                                    actions:actions
                          intentIdentifiers:intentIdentifiers
              hiddenPreviewsBodyPlaceholder:hiddenPreviewsBodyPlaceholder
                                    options:options];

}

#if !TARGET_OS_TV    // UIUserNotificationCategory, UIUserNotificationAction and UNNotificationCategory not available on tvOS
- (UIUserNotificationCategory *)asUIUserNotificationCategory {
    UIMutableUserNotificationCategory *category = [[UIMutableUserNotificationCategory alloc] init];
    category.identifier = self.identifier;

    NSArray *uaActions = self.actions;
    NSMutableArray *uiActions = [NSMutableArray array];
    for (UANotificationAction *uaAction in uaActions) {
        UIUserNotificationAction *converted = [uaAction asUIUserNotificationAction];
        if (converted) {
            [uiActions addObject:converted];
        }
    }

    [category setActions:uiActions forContext:UIUserNotificationActionContextDefault];
    [category setActions:uiActions forContext:UIUserNotificationActionContextMinimal];

    return category;
}

- (UNNotificationCategory *)asUNNotificationCategory {
    NSMutableArray *actions = [NSMutableArray array];

    for (UANotificationAction *action in self.actions) {
        UNNotificationAction *converted = [action asUNNotificationAction];
        if (converted) {
            [actions addObject:converted];
        }
    }
    

    if (self.hiddenPreviewsBodyPlaceholderSpecified) {
        if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){11, 0, 0}]) {
            // This block executes the following method call because the call itself won't build on Xcode 8.3.3.
            // We can replace the block with the much-easier-to-read direct call when we remove support for Xcode 8.3.3.
            // return [UNNotificationCategory categoryWithIdentifier:self.identifier
            //                                               actions:actions
            //                                     intentIdentifiers:self.intentIdentifiers
            //                         hiddenPreviewsBodyPlaceholder:self.hiddenPreviewsBodyPlaceholder
            //                                               options:(UNNotificationCategoryOptions)self.options];
            SEL iOS11MethodSelector = NSSelectorFromString(@"categoryWithIdentifier:actions:intentIdentifiers:hiddenPreviewsBodyPlaceholder:options:");
            NSMethodSignature *ios11MethodSignature = [UNNotificationCategory methodSignatureForSelector:iOS11MethodSelector];
            if (ios11MethodSignature) {
                NSInvocation *invokeIOS11Method = [NSInvocation invocationWithMethodSignature:ios11MethodSignature];
                invokeIOS11Method.target = [UNNotificationCategory class];
                invokeIOS11Method.selector = iOS11MethodSelector;
                [invokeIOS11Method setArgument:&_identifier atIndex:2];
                [invokeIOS11Method setArgument:&actions atIndex:3];
                [invokeIOS11Method setArgument:&_intentIdentifiers atIndex:4];
                [invokeIOS11Method setArgument:&_hiddenPreviewsBodyPlaceholder atIndex:5];
                [invokeIOS11Method setArgument:&_options atIndex:6];

                [invokeIOS11Method invoke];
                
                __unsafe_unretained UNNotificationCategory *createdCategory;
                [invokeIOS11Method getReturnValue:&createdCategory];
                return createdCategory;
            }
        }
    }
    if ([UNNotificationCategory respondsToSelector:@selector(categoryWithIdentifier:actions:intentIdentifiers:options:)]) {
        return [UNNotificationCategory categoryWithIdentifier:self.identifier
                                                      actions:actions
                                            intentIdentifiers:self.intentIdentifiers
                                                      options:(UNNotificationCategoryOptions)self.options];
    }
    
	return nil;
}

- (BOOL)isEqualToUIUserNotificationCategory:(UIUserNotificationCategory *)category {
    NSArray *defaultUAActions = self.actions;

    NSArray *defaultUIActions = [category actionsForContext:UIUserNotificationActionContextDefault];

    if (defaultUAActions.count != defaultUIActions.count) {
        return NO;
    }

    for (NSUInteger i = 0; i < defaultUAActions.count; i++) {
        UANotificationAction *uaAction = defaultUAActions[i];
        UIUserNotificationAction *uiAction = defaultUIActions[i];
        if (![uaAction isEqualToUIUserNotificationAction:(UIUserNotificationAction *)uiAction]) {
            return NO;
        }
    }

    // identifiers are nullable, so they match as long as they are either equal or both nil
    return [self.identifier isEqualToString:category.identifier] || (!self.identifier && !category.identifier);
}

- (BOOL)isEqualToUNNotificationCategory:(UNNotificationCategory *)category {
    if (self.actions.count != category.actions.count) {
        return NO;
    }

    for (NSUInteger i = 0; i < self.actions.count; i++) {
        UANotificationAction *uaAction = self.actions[i];
        UNNotificationAction *unAction = category.actions[i];
        if (![uaAction isEqualToUNNotificationAction:unAction]) {
            return NO;
        }
    }

    if (![self.intentIdentifiers isEqualToArray:category.intentIdentifiers]) {
        return NO;
    }

    if (!((NSUInteger)self.options == (NSUInteger)category.options)) {
        return NO;
    }
    
    if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){11, 0, 0}]) {
        if (![self.hiddenPreviewsBodyPlaceholder isEqualToString:[category valueForKey:@"hiddenPreviewsBodyPlaceholder"]]) {
            return NO;
        }
    }

    return [self.identifier isEqualToString:category.identifier];
}
#endif

@end
