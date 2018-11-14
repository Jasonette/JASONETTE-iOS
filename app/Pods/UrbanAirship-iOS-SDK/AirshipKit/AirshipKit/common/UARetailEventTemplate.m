/* Copyright 2017 Urban Airship and Contributors */

#import "UARetailEventTemplate.h"
#import "UAirship.h"
#import "UAAnalytics.h"
#import "UACustomEvent+Internal.h"

#define kUARetailEventTemplate @"retail"
#define kUABrowsedProductEvent @"browsed"
#define kUAAddedToCartEvent @"added_to_cart"
#define kUAStarredProductEvent @"starred_product"
#define kUASharedProductEvent @"shared_product"
#define kUAPurchasedEvent @"purchased"
#define kUARetailEventTemplateLifetimeValue @"ltv"
#define kUARetailEventTemplateIdentifier @"id"
#define kUARetailEventTemplateCategory @"category"
#define kUARetailEventTemplateDescription @"description"
#define kUARetailEventTemplateBrand @"brand"
#define kUARetailEventTemplateNewItem @"new_item"
#define kUARetailEventTemplateSource @"source"
#define kUARetailEventTemplateMedium @"medium"

@interface UARetailEventTemplate()
@property (nonatomic, copy) NSString *eventName;
@property (nonatomic, copy) NSString *source;
@property (nonatomic, copy) NSString *medium;
@property (nonatomic, assign) BOOL newItemSet;
@end

@implementation UARetailEventTemplate

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
    return [self browsedTemplateWithValue:nil];
}

+ (instancetype)browsedTemplateWithValueFromString:(NSString *)eventValue {
    NSDecimalNumber *decimalValue = eventValue ? [NSDecimalNumber decimalNumberWithString:eventValue] : nil;
    return [self browsedTemplateWithValue:decimalValue];
}

+ (instancetype)browsedTemplateWithValue:(NSDecimalNumber *)eventValue {
    return [[self alloc] initWithName:kUABrowsedProductEvent
                            withValue:eventValue
                           withSource:nil
                           withMedium:nil];
}

+ (instancetype)addedToCartTemplate {
    return [self addedToCartTemplateWithValue:nil];
}

+ (instancetype)addedToCartTemplateWithValueFromString:(NSString *)eventValue {
    NSDecimalNumber *decimalValue = eventValue ? [NSDecimalNumber decimalNumberWithString:eventValue] : nil;
    return [self addedToCartTemplateWithValue:decimalValue];
}

+ (instancetype)addedToCartTemplateWithValue:(NSDecimalNumber *)eventValue {
    return [[self alloc] initWithName:kUAAddedToCartEvent
                            withValue:eventValue
                           withSource:nil
                           withMedium:nil];
}

+ (instancetype)starredProductTemplate {
    return [self starredProductTemplateWithValue:nil];
}

+ (instancetype)starredProductTemplateWithValueFromString:(NSString *)eventValue {
    NSDecimalNumber *decimalValue = eventValue ? [NSDecimalNumber decimalNumberWithString:eventValue] : nil;
    return [self starredProductTemplateWithValue:decimalValue];
}

+ (instancetype)starredProductTemplateWithValue:(NSDecimalNumber *)eventValue {
    return [[self alloc] initWithName:kUAStarredProductEvent
                            withValue:eventValue
                           withSource:nil
                           withMedium:nil];
}

+ (instancetype)purchasedTemplate {
    return [self purchasedTemplateWithValue:nil];
}

+ (instancetype)purchasedTemplateWithValueFromString:(NSString *)eventValue {
    NSDecimalNumber *decimalValue = eventValue ? [NSDecimalNumber decimalNumberWithString:eventValue] : nil;
    return [self purchasedTemplateWithValue:decimalValue];
}

+ (instancetype)purchasedTemplateWithValue:(NSDecimalNumber *)eventValue {
    return [[self alloc] initWithName:kUAPurchasedEvent
                            withValue:eventValue
                           withSource:nil
                           withMedium:nil];
}

+ (instancetype)sharedProductTemplate {
    return [self sharedProductTemplateWithValue:nil];
}

+ (instancetype)sharedProductTemplateWithValueFromString:(NSString *)eventValue {
    NSDecimalNumber *decimalValue = eventValue ? [NSDecimalNumber decimalNumberWithString:eventValue] : nil;
    return [self sharedProductTemplateWithValue:decimalValue];
}

+ (instancetype)sharedProductTemplateWithValue:(NSDecimalNumber *)eventValue {
    return [[self alloc] initWithName:kUASharedProductEvent
                            withValue:eventValue
                           withSource:nil
                           withMedium:nil];
}

+ (instancetype)sharedProductTemplateWithSource:(NSString *)source
                                  withMedium:(NSString *)medium {
    return [[self alloc] initWithName:kUASharedProductEvent
                            withValue:nil
                           withSource:source
                           withMedium:medium];
}

+ (instancetype)sharedProductTemplateWithValueFromString:(NSString *)eventValue
                                           withSource:(NSString *)source
                                           withMedium:(NSString *)medium {
    NSDecimalNumber *decimalValue = eventValue ? [NSDecimalNumber decimalNumberWithString:eventValue] : nil;
    return [[self alloc] initWithName:kUASharedProductEvent
                            withValue:decimalValue
                           withSource:source
                           withMedium:medium];
}

+ (instancetype)sharedProductTemplateWithValue:(NSDecimalNumber *)eventValue
                                 withSource:(NSString *)source
                                 withMedium:(NSString *)medium {
    return [[self alloc] initWithName:kUASharedProductEvent
                            withValue:eventValue
                           withSource:source
                           withMedium:medium];
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

- (void)setIsNewItem:(BOOL)isNewItem {
    self.newItemSet = YES;
    _isNewItem = isNewItem;
}

- (UACustomEvent *)createEvent {
    UACustomEvent *event = [UACustomEvent eventWithName:self.eventName];

    if (self.eventValue) {
        [event setEventValue:self.eventValue];
    }

    if (self.eventValue && [self.eventName isEqualToString:kUAPurchasedEvent]) {
        [event setBoolProperty:YES forKey:kUARetailEventTemplateLifetimeValue];
    } else {
        [event setBoolProperty:NO forKey:kUARetailEventTemplateLifetimeValue];
    }

    if (self.transactionID) {
        [event setTransactionID:self.transactionID];
    }

    if (self.identifier) {
        [event setStringProperty:self.identifier forKey:kUARetailEventTemplateIdentifier];
    }

    if (self.category) {
        [event setStringProperty:self.category forKey:kUARetailEventTemplateCategory];
    }

    if (self.eventDescription) {
        [event setStringProperty:self.eventDescription forKey:kUARetailEventTemplateDescription];
    }

    if (self.brand) {
        [event setStringProperty:self.brand forKey:kUARetailEventTemplateBrand];
    }

    if (self.newItemSet) {
        [event setBoolProperty:self.isNewItem forKey:kUARetailEventTemplateNewItem];
    }
    if (self.source) {
        [event setStringProperty:self.source forKey:kUARetailEventTemplateSource];
    }

    if (self.medium) {
        [event setStringProperty:self.medium forKey:kUARetailEventTemplateMedium];
    }

    event.templateType = kUARetailEventTemplate;

    return event;
}

@end
