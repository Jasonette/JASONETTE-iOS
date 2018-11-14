/* Copyright 2017 Urban Airship and Contributors */

#import "UAChannelCapture.h"
#import "NSString+UALocalizationAdditions.h"
#import "UAirship.h"
#import "UAPush+Internal.h"
#import "UAConfig.h"
#import "UA_Base64.h"
#import "UAPreferenceDataStore+Internal.h"
#import "UAUtils.h"

NSString *const UAChannelCaptureEnabledKey = @"UAChannelCaptureEnabled";

@interface UAChannelCapture()

// REVISIT: convert to UIAlertController
@property (nonatomic, strong) UIAlertView *alertView;
@property (nonatomic, strong) UAPush *push;
@property (nonatomic, strong) UAConfig *config;
@property (nonatomic, strong) UAPreferenceDataStore *dataStore;

@end


@implementation UAChannelCapture

NSString *const UAChannelBaseURL = @"https://go.urbanairship.com/";
NSString *const UAChannelPlaceHolder = @"CHANNEL";

- (instancetype)initWithConfig:(UAConfig *)config
                          push:(UAPush *)push
                     dataStore:(UAPreferenceDataStore *)dataStore {
    self = [super init];
    if (self) {
        self.config = config;
        self.push = push;
        self.dataStore = dataStore;
        
        if (config.channelCaptureEnabled) {
            // App inactive/active for incoming calls, notification center, and taskbar
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(didBecomeActive)
                                                         name:UIApplicationDidBecomeActiveNotification
                                                       object:nil];
        }
    }

    return self;
}

+ (instancetype)channelCaptureWithConfig:(UAConfig *)config
                                    push:(UAPush *)push
                               dataStore:(UAPreferenceDataStore *)dataStore {
    return [[UAChannelCapture alloc] initWithConfig:config push:push dataStore:dataStore];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)enable:(NSTimeInterval)duration {
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:duration];
    [self.dataStore setObject:date forKey:UAChannelCaptureEnabledKey];
}

- (void)disable {
    [self.dataStore removeObjectForKey:UAChannelCaptureEnabledKey];
}

- (void)didBecomeActive {
    [self checkClipboard];
}

/**
 * Checks the clipboard for the token and displays an alert if the token is available.
 */
- (void)checkClipboard {
    if (!self.push.channelID) {
        return;
    }

    if ([self.push backgroundPushNotificationsAllowed]) {
        NSDate *enabledUntilDate = [self.dataStore objectForKey:UAChannelCaptureEnabledKey];
        if (!enabledUntilDate || [enabledUntilDate compare:[NSDate date]] == NSOrderedAscending) {
            return;
        }
    }

    if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){10, 0, 0}] && ![UIPasteboard generalPasteboard].hasStrings) {
        return;
    }
    
    NSString *pasteBoardString = [UIPasteboard generalPasteboard].string;
    if (!pasteBoardString.length) {
        return;
    }
    
    // Do the heavy lifting off the main queue
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        NSData *base64Data = UA_dataFromBase64String(pasteBoardString);
        if (!base64Data) {
            return;
        }

        NSString *decodedPasteBoardString = [[NSString alloc] initWithData:base64Data encoding:NSUTF8StringEncoding];
        if (!decodedPasteBoardString.length) {
            return;
        }

        NSString *token = [self generateToken];
        if (![decodedPasteBoardString hasPrefix:token]) {
            return;
        }

        // Generate the URL
        NSURL *url;
        if (decodedPasteBoardString.length > token.length) {
            // Generate the URL
            NSString *urlString = [decodedPasteBoardString stringByReplacingOccurrencesOfString:token
                                                                                     withString:UAChannelBaseURL];

            urlString = [urlString stringByReplacingOccurrencesOfString:UAChannelPlaceHolder
                                                             withString:self.push.channelID];

            urlString = [urlString stringByTrimmingCharactersInSet:
                         [NSCharacterSet whitespaceAndNewlineCharacterSet]];

            url = [NSURL URLWithString:urlString];
        }

        // Move back to the main queue to clear the clipboard and display the alert
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIPasteboard generalPasteboard].string = @"";
            [self showAlertWithUrl:url];
        });
    });

}

- (void)showAlertWithUrl:(NSURL *)url {


    UIAlertController *controller = [UIAlertController alertControllerWithTitle:[@"ua_channel_id" localizedStringWithTable:@"UrbanAirship" defaultValue:@"Channel ID"]
                                                                        message:self.push.channelID
                                                                 preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:[@"ua_cancel" localizedStringWithTable:@"UrbanAirship" defaultValue:@"Cancel"]
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];

    [controller addAction:cancelAction];

    NSString *channelID = self.push.channelID;
    UIAlertAction *copyAction  = [UIAlertAction actionWithTitle:[@"ua_notification_button_copy" localizedStringWithTable:@"UrbanAirship" defaultValue:@"Copy"]
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction *action) {
                                                            [UIPasteboard generalPasteboard].string = channelID ?: @"";
                                                            UA_LINFO(@"Copied channel %@ to the pasteboard", channelID);
                                                        }];
    [controller addAction:copyAction];


    if (url) {

        UIAlertAction *urlAction  = [UIAlertAction actionWithTitle:[@"ua_notification_button_copy" localizedStringWithTable:@"UrbanAirship" defaultValue:@"Copy"]
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction *action) {
                                                               [[UIApplication sharedApplication] openURL:url];
                                                               UA_LINFO(@"Opened url: %@", url.absoluteString);
                                                           }];
        [controller addAction:urlAction];
    }

    controller.popoverPresentationController.sourceView = [UAUtils mainWindow].rootViewController.view;
    [[UAUtils mainWindow].rootViewController presentViewController:controller animated:YES completion:nil];
}

/**
 * Generates the expected clipboard token.
 *
 * @return The generated clipboard token.
 */
- (NSString *)generateToken {
    const char *keyCStr = [self.config.appKey cStringUsingEncoding:NSASCIIStringEncoding];
    size_t keyCstrLen = strlen(keyCStr);

    const char *secretCStr = [self.config.appSecret cStringUsingEncoding:NSASCIIStringEncoding];
    size_t secretCstrLen = strlen(secretCStr);

    NSMutableString *combined = [NSMutableString string];
    for (size_t i = 0; i < keyCstrLen; i++) {
        [combined appendFormat:@"%02x", (int)(keyCStr[i] ^ secretCStr[i % secretCstrLen])];
    }

    return combined;
}

@end
