/* Copyright 2017 Urban Airship and Contributors */

#import "UAMediaEventTemplate.h"
#import "UAirship.h"
#import "UAAnalytics.h"
#import "UACustomEvent+Internal.h"

#define kUAMediaEventTemplate @"media"
#define kUABrowsedContentEvent @"browsed_content"
#define kUAConsumedContentEvent @"consumed_content"
#define kUAStarredContentEvent @"starred_content"
#define kUASharedContentEvent @"shared_content"
#define kUAMediaEventTemplateLifetimeValue @"ltv"
#define kUAMediaEventTemplateIdentifier @"id"
#define kUAMediaEventTemplateCategory @"category"
#define kUAMediaEventTemplateDescription @"description"
#define kUAMediaEventTemplateType @"type"
#define kUAMediaEventTemplateFeature @"feature"
#define kUAMediaEventTemplateAuthor @"author"
#define kUAMediaEventTemplatePublishedDate @"published_date"
#define kUAMediaEventTemplateSource @"source"
#define kUAMediaEventTemplateMedium @"medium"

@interface UAMediaEventTemplate()
@property (nonatomic, copy) NSString *eventName;
@property (nonatomic, copy) NSString *source;
@property (nonatomic, copy) NSString *medium;
@property (nonatomic, strong) NSDecimalNumber *eventValue;
@property (nonatomic, assign) BOOL featureSet;
@end

@implementation UAMediaEventTemplate

- (instancetype)initWithName:(NSString *)name
                   withValue:(NSDecimalNumber *)eventValue
                  withSource:(NSString *)source
                  withMedium:(NSString *)medium {
    self = [super init];
    if (self) {
        self.eventName = name;
        self.eventValue = eventValue;
        self.source = source;
        self.medium = medium;
    }

    return self;
}

+ (instancetype)browsedTemplate {
    return [[self alloc] initWithName:kUABrowsedContentEvent
                            withValue:nil
                           withSource:nil
                           withMedium:nil];
}

+ (instancetype)starredTemplate {
    return [[self alloc] initWithName:kUAStarredContentEvent
                            withValue:nil
                           withSource:nil
                           withMedium:nil];
}

+ (instancetype)sharedTemplateWithSource:(NSString *)source
                                  withMedium:(NSString *)medium {
    return [[self alloc] initWithName:kUASharedContentEvent
                            withValue:nil
                           withSource:source
                           withMedium:medium];
}

+ (instancetype)sharedTemplate {
    return [self sharedTemplateWithSource:nil withMedium:nil];
}

+ (instancetype)consumedTemplate {
    return [self consumedTemplateWithValue:nil];
}

+ (instancetype)consumedTemplateWithValueFromString:(NSString *)eventValue {
    NSDecimalNumber *decimalValue = eventValue ? [NSDecimalNumber decimalNumberWithString:eventValue] : nil;
    return [self consumedTemplateWithValue:decimalValue];
}

+ (instancetype)consumedTemplateWithValue:(NSDecimalNumber *)eventValue {
    return [[self alloc] initWithName:kUAConsumedContentEvent
                            withValue:eventValue
                           withSource:nil
                           withMedium:nil];
}

- (void)setIsFeature:(BOOL)isFeature {
    self.featureSet = YES;
    _isFeature = isFeature;
}

- (UACustomEvent *)createEvent {
    UACustomEvent *event = [UACustomEvent eventWithName:self.eventName];

    if (self.eventValue) {
        [event setEventValue:self.eventValue];
        [event setBoolProperty:YES forKey:kUAMediaEventTemplateLifetimeValue];
    } else {
        [event setBoolProperty:NO forKey:kUAMediaEventTemplateLifetimeValue];
    }

    if (self.identifier) {
        [event setStringProperty:self.identifier forKey:kUAMediaEventTemplateIdentifier];
    }

    if (self.category) {
        [event setStringProperty:self.category forKey:kUAMediaEventTemplateCategory];
    }

    if (self.eventDescription) {
        [event setStringProperty:self.eventDescription forKey:kUAMediaEventTemplateDescription];
    }

    if (self.type) {
        [event setStringProperty:self.type forKey:kUAMediaEventTemplateType];
    }

    if (self.featureSet) {
        [event setBoolProperty:self.isFeature forKey:kUAMediaEventTemplateFeature];
    }

    if (self.author) {
        [event setStringProperty:self.author forKey:kUAMediaEventTemplateAuthor];
    }

    if (self.publishedDate) {
        [event setStringProperty:self.publishedDate forKey:kUAMediaEventTemplatePublishedDate];
    }

    if (self.source) {
        [event setStringProperty:self.source forKey:kUAMediaEventTemplateSource];
    }

    if (self.medium) {
        [event setStringProperty:self.medium forKey:kUAMediaEventTemplateMedium];
    }

    event.templateType = kUAMediaEventTemplate;
    return event;
}

@end
