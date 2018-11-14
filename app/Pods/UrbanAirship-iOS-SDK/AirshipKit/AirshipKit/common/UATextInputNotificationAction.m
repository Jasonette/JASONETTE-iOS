/* Copyright 2017 Urban Airship and Contributors */

#import "UATextInputNotificationAction.h"
#import "UANotificationAction.h"

@interface UATextInputNotificationAction ()

@property(nonatomic, copy) NSString *textInputButtonTitle;
@property(nonatomic, copy) NSString *textInputPlaceholder;

@end

@implementation UATextInputNotificationAction

- (instancetype)initWithIdentifier:(NSString *)identifier
                             title:(NSString *)title
              textInputButtonTitle:(NSString *)textInputButtonTitle
              textInputPlaceholder:(NSString *)textInputPlaceholder
                           options:(UANotificationActionOptions)options {
    self = [super initWithIdentifier:identifier title:title options:options];

    if (self) {
        self.textInputButtonTitle = textInputButtonTitle;
        self.textInputPlaceholder = textInputPlaceholder;
        self.forceBackgroundActivationModeInIOS9 = YES;
    }
    return self;
}

+ (instancetype)actionWithIdentifier:(NSString *)identifier
                               title:(NSString *)title
                textInputButtonTitle:(NSString *)textInputButtonTitle
                textInputPlaceholder:(NSString *)textInputPlaceholder
                             options:(UANotificationActionOptions)options {
    return [[self alloc] initWithIdentifier:identifier title:title textInputButtonTitle:textInputButtonTitle textInputPlaceholder:textInputPlaceholder options:options];
}

#if !TARGET_OS_TV    // UIUserNotificationAction and UNTextInputNotificationAction not available on tvOS
- (UIUserNotificationAction *)asUIUserNotificationAction {
    UIMutableUserNotificationAction *uiAction = [[super asUIUserNotificationAction] mutableCopy];
    
    // Text input is only supported in UIUserNotificationActions on iOS 9+
    if (![[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){9, 0, 0}]) {
        return nil;
    }

    // handle iOS 9 foreground activation problem (Note: iOS 10 doesn't use this method)
    if (self.forceBackgroundActivationModeInIOS9) {
        uiAction.activationMode = UIUserNotificationActivationModeBackground;
    }

    uiAction.behavior = UIUserNotificationActionBehaviorTextInput;
    uiAction.parameters = @{UIUserNotificationTextInputActionButtonTitleKey:self.textInputButtonTitle};

    return uiAction;
}

- (UNTextInputNotificationAction *)asUNNotificationAction {
    return [UNTextInputNotificationAction actionWithIdentifier:self.identifier
                                                title:self.title
                                              options:(UNNotificationActionOptions)self.options
                                          textInputButtonTitle:self.textInputButtonTitle
                                          textInputPlaceholder:self.textInputPlaceholder];
}

- (BOOL)isEqualToUIUserNotificationAction:(UIUserNotificationAction *)notificationAction {
    BOOL equalButtonTitle = [self.textInputButtonTitle isEqualToString:notificationAction.parameters[UIUserNotificationTextInputActionButtonTitleKey]];
    
    return equalButtonTitle && [super isEqualToUIUserNotificationAction:notificationAction];
}

- (BOOL)isEqualToUNNotificationAction:(UNNotificationAction *)notificationAction {
    if (![notificationAction isKindOfClass:[UNTextInputNotificationAction class]]) {
        return NO;
    }
    BOOL equalButtonTitle = [self.textInputButtonTitle isEqualToString:((UNTextInputNotificationAction *)notificationAction).textInputButtonTitle];
    BOOL equalButtonPlaceholder  = [self.textInputPlaceholder isEqualToString:((UNTextInputNotificationAction *)notificationAction).textInputPlaceholder];

    if (!(equalButtonTitle && equalButtonPlaceholder)) {
        return NO;
    }
    
    return [super isEqualToUNNotificationAction:notificationAction];
}
#endif

@end
