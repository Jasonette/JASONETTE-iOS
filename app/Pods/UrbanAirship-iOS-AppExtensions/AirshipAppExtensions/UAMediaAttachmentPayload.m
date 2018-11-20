/*
 Copyright 2009-2016 Urban Airship Inc. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:

 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.

 2. Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.

 THIS SOFTWARE IS PROVIDED BY THE URBAN AIRSHIP INC ``AS IS'' AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 EVENT SHALL URBAN AIRSHIP INC OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#define kUANotificationAttachmentServiceURLKey @"url"
#define kUANotificationAttachmentServiceOptionsKey @"options"
#define kUANotificationAttachmentServiceCropKey @"crop"
#define kUANotificationAttachmentServiceTimeKey @"time"
#define kUANotificationAttachmentServiceHiddenKey @"hidden"
#define kUANotificationAttachmentServiceContentKey @"content"
#define kUANotificationAttachmentServiceBodyKey @"body"
#define kUANotificationAttachmentServiceTitleKey @"title"
#define kUANotificationAttachmentServiceSubtitleKey @"subtitle"

#import <UserNotifications/UserNotifications.h>
#import "UAMediaAttachmentPayload.h"

@interface UAMediaAttachmentContent ()

+ (UAMediaAttachmentContent *)contentWithDictionary:(NSDictionary *)dictionary;

@property(nonatomic, copy) NSString *body;
@property(nonatomic, copy) NSString *title;
@property(nonatomic, copy) NSString *subtitle;

@end

@interface UAMediaAttachmentPayload ()

@property(nonatomic, strong) NSMutableArray *urls;
@property(nonatomic, copy) NSDictionary *options;
@property(nonatomic, strong) UAMediaAttachmentContent *content;

@end

@implementation UAMediaAttachmentContent

- (instancetype)initWithDictionary:(id)dictionary {
    self = [super init];

    if (self) {
        self.body = dictionary[kUANotificationAttachmentServiceBodyKey];
        self.title = dictionary[kUANotificationAttachmentServiceTitleKey];
        self.subtitle = dictionary[kUANotificationAttachmentServiceSubtitleKey];
    }

    return self;
}

+ (instancetype)contentWithDictionary:(id)object {
    return [[self alloc] initWithDictionary:object];
}

@end

@implementation UAMediaAttachmentPayload

- (instancetype)initWithJSONObject:(id)object {
    self = [super init];

    if (self) {
        if ([self validatePayload:object]) {
            NSDictionary *payload = object;

            self.urls = [NSMutableArray array];
            id payloadURL = payload[kUANotificationAttachmentServiceURLKey];
            if ([payloadURL isKindOfClass:[NSArray class]]) {
                for (NSString *urlString in payload[kUANotificationAttachmentServiceURLKey]) {
                    [self.urls addObject:[NSURL URLWithString:urlString]];
                }
            } else {
                if ([payloadURL isKindOfClass:[NSString class]]) {
                    [self.urls addObject:[NSURL URLWithString:payloadURL]];
                }
            }

            self.options = [self optionsWithPayload:payload];
            self.content = [self contentWithPayload:payload];
        } else {
            return nil;
        }
    }

    return self;
}

+ (instancetype)payloadWithJSONObject:(id)object {
    return [[self alloc] initWithJSONObject:object];
}

- (UAMediaAttachmentContent *)contentWithPayload:(NSDictionary *)payload {
    NSDictionary *content = payload[kUANotificationAttachmentServiceContentKey];
    return [UAMediaAttachmentContent contentWithDictionary:content];
}

- (NSDictionary *)optionsWithPayload:(NSDictionary *)payload {
    NSDictionary *payloadOptions = payload[kUANotificationAttachmentServiceOptionsKey];
    NSMutableDictionary *attachmentOptions = [NSMutableDictionary dictionary];

    if (payloadOptions) {
        NSDictionary *crop = payloadOptions[kUANotificationAttachmentServiceCropKey];
        NSNumber *time = payloadOptions[kUANotificationAttachmentServiceTimeKey];
        NSNumber *hidden = payloadOptions[kUANotificationAttachmentServiceHiddenKey];

        if (crop) {
            // normalize crop dictionary to use capitalized keys, as expected
            NSMutableDictionary *normalizedCrop = [NSMutableDictionary dictionary];
            for (NSString *key in crop) {
                [normalizedCrop setValue:crop[key] forKey:key.capitalizedString];
            }

            [attachmentOptions setValue:normalizedCrop forKey:UNNotificationAttachmentOptionsThumbnailClippingRectKey];
        }

        if (time) {
            [attachmentOptions setValue:time forKey:UNNotificationAttachmentOptionsThumbnailTimeKey];
        }

        if (hidden) {
            [attachmentOptions setValue:hidden forKey:UNNotificationAttachmentOptionsThumbnailHiddenKey];
        }
    }

    return attachmentOptions;
}

- (BOOL)validateURL:(id)url {
    return [url isKindOfClass:[NSArray class]] || [url isKindOfClass:[NSString class]];
}

- (BOOL)validateCrop:(id)crop {
    if (![crop isKindOfClass:[NSDictionary class]]) {
        return NO;
    }

    NSArray *keys = @[@"x", @"y", @"width", @"height"];
    for (NSString *key in keys) {
        id value = [crop valueForKey:key];
        if (![value isKindOfClass:[NSNumber class]]) {
            return NO;
        }
        float normalizedValue = [value floatValue];
        if (normalizedValue < 0.0 || normalizedValue > 1.0) {
            return NO;
        }
    }

    return YES;

}

- (BOOL)validateTime:(id)time {
    return [time isKindOfClass:[NSNumber class]];
}

- (BOOL)validateHidden:(id)hidden {
    return [hidden isKindOfClass:[NSNumber class]];
}

- (BOOL)validateOptions:(id)options {
    if (![options isKindOfClass:[NSDictionary class]]) {
        return NO;
    }

    id crop = options[kUANotificationAttachmentServiceCropKey];
    id time = options[kUANotificationAttachmentServiceTimeKey];
    id hidden = options[kUANotificationAttachmentServiceHiddenKey];

    if (crop) {
        if (![self validateCrop:crop]) {
            NSLog(@"Unable to parse crop: %@", crop);
            return NO;
        }
    }

    if (time) {
        if (![self validateTime:time]) {
            NSLog(@"Unable to parse time: %@", time);
            return NO;
        }
    }

    if (hidden) {
        if (![self validateHidden:hidden]) {
            NSLog(@"Unable to parse hidden: %@", hidden);
            return NO;
        }
    }

    return YES;
}

- (BOOL)validateContent:(id)content {
    if (![content isKindOfClass:[NSDictionary class]]) {
        return NO;
    }

    id body = content[kUANotificationAttachmentServiceBodyKey];
    id title = content[kUANotificationAttachmentServiceTitleKey];
    id subtitle = content[kUANotificationAttachmentServiceSubtitleKey];

    if (body) {
        if (![body isKindOfClass:[NSString class]]) {
            NSLog(@"Unable to parse body: %@", body);
            return NO;
        }
    }

    if (title) {
        if (![title isKindOfClass:[NSString class]]) {
            NSLog(@"Unable to parse title: %@", title);
            return NO;
        }
    }

    if (subtitle) {
        if (![subtitle isKindOfClass:[NSString class]]) {
            NSLog(@"Unable to parse subtitle: %@", subtitle);
            return NO;
        }
    }

    return YES;
}

- (BOOL)validatePayload:(id)payload {
    if (![payload isKindOfClass:[NSDictionary class]]) {
        return NO;
    }

    id url = payload[kUANotificationAttachmentServiceURLKey];
    id options = payload[kUANotificationAttachmentServiceOptionsKey];
    id content = payload[kUANotificationAttachmentServiceContentKey];

    // The URL is required
    if (![self validateURL:url]) {
        NSLog(@"Unable to parse url: %@", url);
        return NO;
    }

    // Options and content are optional
    if (options) {
        if (![self validateOptions:options]) {
            NSLog(@"Unable to parse options");
            return NO;
        }
    }

    if (content) {
        if (![self validateContent:content]) {
            NSLog(@"Unable to parse content");
            return NO;
        }
    }

    return YES;
}

@end
