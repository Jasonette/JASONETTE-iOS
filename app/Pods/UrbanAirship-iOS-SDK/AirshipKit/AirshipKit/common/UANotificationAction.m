/* Copyright 2017 Urban Airship and Contributors */

#import "UANotificationAction.h"

@interface UANotificationAction ()

@property(nonatomic, copy) NSString *identifier;
@property(nonatomic, copy) NSString *title;
@property(nonatomic, assign) UANotificationActionOptions options;

@end

@implementation UANotificationAction

- (instancetype)initWithIdentifier:(NSString *)identifier
                             title:(NSString *)title
                           options:(UANotificationActionOptions)options {
    self = [super init];

    if (self) {
        self.identifier = identifier;
        self.title = title;
        self.options = options;
    }
    return self;
}

+ (instancetype)actionWithIdentifier:(NSString *)identifier
                               title:(NSString *)title
                             options:(UANotificationActionOptions)options {
    return [[self alloc] initWithIdentifier:identifier title:title options:options];
}

#if !TARGET_OS_TV    // UIUserNotificationAction and UNNotificationAction not available on tvOS
- (UIUserNotificationAction *)asUIUserNotificationAction {
    UIMutableUserNotificationAction *uiAction = [[UIMutableUserNotificationAction alloc] init];
    uiAction.identifier = self.identifier;
    uiAction.title = self.title;

    if (self.options & UANotificationActionOptionAuthenticationRequired) {
        uiAction.authenticationRequired = YES;
    }

    uiAction.authenticationRequired = self.options & UANotificationActionOptionAuthenticationRequired ? YES : NO;
    uiAction.activationMode = self.options & UANotificationActionOptionForeground ? UIUserNotificationActivationModeForeground : UIUserNotificationActivationModeBackground;
    uiAction.destructive = self.options & UANotificationActionOptionDestructive ? YES : NO;

    return uiAction;
}

- (UNNotificationAction *)asUNNotificationAction {
    return [UNNotificationAction actionWithIdentifier:self.identifier
                                                title:self.title
                                              options:(UNNotificationActionOptions)self.options];
}

- (BOOL)isEqualToUIUserNotificationAction:(UIUserNotificationAction *)notificationAction {
    BOOL equalIdentifier = [self.identifier isEqualToString:notificationAction.identifier];
    BOOL equalTitle = [self.title isEqualToString:notificationAction.title];
    BOOL equalAuth = (self.options & UANotificationActionOptionAuthenticationRequired) > 0 == notificationAction.authenticationRequired;
    BOOL equalActivationMode = (self.options & UANotificationActionOptionForeground) > 0 == (notificationAction.activationMode == UIUserNotificationActivationModeForeground);
    BOOL equalDestructive = (self.options & UANotificationActionOptionDestructive) > 0 == notificationAction.destructive;

    return equalIdentifier && equalTitle && equalAuth && equalActivationMode && equalDestructive;
}

- (BOOL)isEqualToUNNotificationAction:(UNNotificationAction *)notificationAction {
    BOOL equalIdentifier = [self.identifier isEqualToString:notificationAction.identifier];
    BOOL equalTitle = [self.title isEqualToString:notificationAction.title];
    BOOL equalOptions = (NSUInteger)self.options == (NSUInteger)notificationAction.options;

    return equalIdentifier && equalTitle && equalOptions;
}
#endif

@end
