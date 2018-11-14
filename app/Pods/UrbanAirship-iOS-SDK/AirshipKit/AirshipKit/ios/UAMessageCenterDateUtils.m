/* Copyright 2017 Urban Airship and Contributors */

#import "UAMessageCenterDateUtils.h"

@implementation UAMessageCenterDateUtils

static NSDateFormatter *dateFormatter;
static NSDateFormatter *sameDayFormatter;

/**
 * Formats the provided date into a string relative to the current date.
 * e.g. Today, 1:23 PM vs. mm/dd/yy
 *
 * @param date The date to format relative to the current date.
 * @return A formatted date string. 
 */
+ (NSString *)formattedDateRelativeToNow:(NSDate *)date {

    if ([self isDate:date inSameCalendarDayAsDate:[NSDate date]]) {
        if (!sameDayFormatter) {
            sameDayFormatter = [[NSDateFormatter alloc] init];
            sameDayFormatter.timeStyle = NSDateFormatterShortStyle;
            sameDayFormatter.dateStyle = NSDateFormatterShortStyle;
            sameDayFormatter.doesRelativeDateFormatting = YES;
        }

        return [sameDayFormatter stringFromDate:date];
    } else {
        if (!dateFormatter) {
            dateFormatter = [[NSDateFormatter alloc] init];
            dateFormatter.timeStyle = NSDateFormatterNoStyle;
            dateFormatter.dateStyle = NSDateFormatterShortStyle;
            dateFormatter.doesRelativeDateFormatting = YES;
        }

        return [dateFormatter stringFromDate:date];
    }
}

/**
 * A helper method to determine if two dates fall on the same calendar.
 *
 * @param date A date to compare.
 * @param otherDate The other date to compare.
 * @return YES if the dates fall on the same calendar day, else NO.
 */
+ (BOOL)isDate:(NSDate *)date inSameCalendarDayAsDate:(NSDate *)otherDate {
    NSCalendar *calendar = [NSCalendar currentCalendar];

    NSUInteger components = ( NSCalendarUnitYear |
                             NSCalendarUnitMonth |
                             NSCalendarUnitDay);

    NSDateComponents *dateComponents = [calendar components:components fromDate:date];
    NSDateComponents *otherDateComponents = [calendar components:components fromDate:otherDate];

    return (dateComponents.day == otherDateComponents.day &&
            dateComponents.month == otherDateComponents.month &&
            dateComponents.year == otherDateComponents.year);
}

@end
