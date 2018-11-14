/* Copyright 2017 Urban Airship and Contributors */

#import "UAAccountEventTemplate.h"
#import "UAirship.h"
#import "UAAnalytics.h"
#import "UACustomEvent+Internal.h"

#define kUAAccountEventTemplate @"account"
#define kUARegisteredAccountEvent @"registered_account"
#define kUAAccountEventTemplateLifetimeValue @"ltv"
#define kUAAccountEventTemplateCategory @"category"

@interface UAAccountEventTemplate()
@property (nonatomic, copy) NSString *eventName;
@end

@implementation UAAccountEventTemplate

- (instancetype)initWithValue:(NSDecimalNumber *)eventValue {
    self = [super init];
    if (self) {
        self.eventName = kUARegisteredAccountEvent;
        self.eventValue = eventValue;
    }

    return self;
}

+ (instancetype)registeredTemplate {
    return [self registeredTemplateWithValue:nil];
}

+ (instancetype)registeredTemplateWithValueFromString:(NSString *)eventValue {
    NSDecimalNumber *decimalValue = eventValue ? [NSDecimalNumber decimalNumberWithString:eventValue] : nil;
    return [self registeredTemplateWithValue:decimalValue];
}

+ (instancetype)registeredTemplateWithValue:(NSDecimalNumber *)eventValue {
    return [[self alloc] initWithValue:eventValue];
}

- (void)setEventValue:(NSDecimalNumber *)eventValue {
    if (!eventValue) {
        _eventValue = nil;
    } else {
        if ([eventValue isKindOfClass:[NSDecimalNumber class]]) {
            _eventValue = eventValue;
        } else {
            _eventValue = [NSDecimalNumber decimalNumberWithDecimal:[eventValue decimalValue]];
        }
    }
}

- (UACustomEvent *)createEvent {
    UACustomEvent *event = [UACustomEvent eventWithName:self.eventName];

    if (self.eventValue) {
        [event setEventValue:self.eventValue];
        [event setBoolProperty:YES forKey:kUAAccountEventTemplateLifetimeValue];
    } else {
        [event setBoolProperty:NO forKey:kUAAccountEventTemplateLifetimeValue];
    }

    if (self.transactionID) {
        [event setTransactionID:self.transactionID];
    }

    if (self.category) {
        [event setStringProperty:self.category forKey:kUAAccountEventTemplateCategory];
    }

    event.templateType = kUAAccountEventTemplate;

    return event;
}

@end
