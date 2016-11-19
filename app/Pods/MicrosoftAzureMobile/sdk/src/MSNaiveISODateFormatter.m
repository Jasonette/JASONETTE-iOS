// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import "MSNaiveISODateFormatter.h"


#pragma mark * DateTime Format

static NSString *const formatDate = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
static NSString *const formatDateNoFractionalSeconds = @"yyyy-MM-dd'T'HH:mm:ss'Z'";


#pragma mark * MSDateFormatter Implementation


@implementation MSNaiveISODateFormatter


static MSNaiveISODateFormatter *staticDateFormatterSingleton;
static MSNaiveISODateFormatter *staticDateNoFractionalSecondsFormatterSingleton;


#pragma mark * Public Static Singleton Constructor


+(MSNaiveISODateFormatter *) naiveISODateFormatter
{
    if (staticDateFormatterSingleton == nil) {
        staticDateFormatterSingleton = [[MSNaiveISODateFormatter alloc] initWithFormat:formatDate];
    }
    
    return  staticDateFormatterSingleton;
}

+(MSNaiveISODateFormatter *)naiveISODateNoFractionalSecondsFormatter
{
    if (staticDateNoFractionalSecondsFormatterSingleton == nil) {
        staticDateNoFractionalSecondsFormatterSingleton = [[MSNaiveISODateFormatter alloc] initWithFormat:formatDateNoFractionalSeconds];
    }
    
    return  staticDateNoFractionalSecondsFormatterSingleton;
}

#pragma mark * Public Initializer Methods


-(id) initWithFormat:(NSString *)format
{
    self = [super init];
    if (self) {

        // To ensure we ignore user locale and preferences we use the
        // following locale
        NSLocale *locale = [[NSLocale alloc]
                            initWithLocaleIdentifier:@"en_US_POSIX"];
        [self setLocale:locale];
        
        // Set the date format
        [self setDateFormat:format];
        
        // Set the time zone to GMT
        [self setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
    }
    return self;
}

@end
