//
//  NSDate+JQTimeAgoAdditions.m
//
//  Copyright (c) 2014 Ian McCullough. All rights reserved.
//


#import "NSDate+TimeAgo.h"

@implementation NSDate (JQTimeAgoAdditions)

- (NSString*)timeAgo
{
    NSTimeInterval distanceMillis = -1000.0 * [self timeIntervalSinceNow];
    //        inWords: function(distanceMillis) {
    //            var $l = this.settings.strings;
    NSUserDefaults* defs = [NSUserDefaults standardUserDefaults];
    //            var prefix = $l.prefixAgo;
    NSString* prefix = [defs stringForKey: kJQTimeAgoStringsPrefixAgoKey];
    //            var suffix = $l.suffixAgo;
    NSString* suffix = [defs stringForKey: kJQTimeAgoStringsSuffixAgoKey];
    //            if (this.settings.allowFuture) {
    if ([defs boolForKey: kJQTimeAgoAllowFutureKey])
    {
        //                if (distanceMillis < 0) {
        if (distanceMillis < 0.0)
        {
            //                    prefix = $l.prefixFromNow;
            prefix = [defs stringForKey: kJQTimeAgoStringsPrefixFromNowKey];
            //                    suffix = $l.suffixFromNow;
            suffix = [defs stringForKey: kJQTimeAgoStringsSuffixFromNowKey];
            //                }
        }
        //                distanceMillis = Math.abs(distanceMillis);
        distanceMillis = fabs(distanceMillis);
        //            }
    }
    //
    //            var seconds = distanceMillis / 1000;
    const double seconds = distanceMillis / 1000.0;
    //            var minutes = seconds / 60;
    const double minutes = seconds / 60.0;
    //            var hours = minutes / 60;
    const double hours = minutes / 60.0;
    //            var days = hours / 24;
    const double days = hours / 24.0;
    //            var years = days / 365;
    const double years = days / 365.0;
    //
    //            function substitute(stringOrFunction, number) { ... }
    // Use stringWithFormat, etc.
    //
    //            var words = seconds < 45 && substitute($l.seconds, Math.round(seconds)) ||
    NSString* words = nil;
    if ([self isEqual: [NSDate distantPast]])
    {
        words = [defs stringForKey: kJQTimeAgoStringsNeverKey];
        suffix = nil;
    }
    else if (seconds < 45)
        words = [[defs stringForKey: kJQTimeAgoStringsSecondsKey] stringByReplacingOccurrencesOfString: @"%d" withString: [NSString stringWithFormat: @"%d", (int)round(seconds)]];
    //            seconds < 90 && substitute($l.minute, 1) ||
    else if (seconds < 90)
        words = [[defs stringForKey: kJQTimeAgoStringsMinuteKey] stringByReplacingOccurrencesOfString: @"%d" withString: [NSString stringWithFormat: @"%d", (int)1]];
    
    //            minutes < 45 && substitute($l.minutes, Math.round(minutes)) ||
    else if (minutes < 45)
        words = [[defs stringForKey: kJQTimeAgoStringsMinutesKey] stringByReplacingOccurrencesOfString: @"%d" withString: [NSString stringWithFormat: @"%d", (int)round(minutes)]];
    
    //            minutes < 90 && substitute($l.hour, 1) ||
    else if (minutes < 90)
        words = [[defs stringForKey: kJQTimeAgoStringsHourKey] stringByReplacingOccurrencesOfString: @"%d" withString: [NSString stringWithFormat: @"%d", (int)1]];
    
    //            hours < 24 && substitute($l.hours, Math.round(hours)) ||
    else if (hours < 24)
        words = [[defs stringForKey: kJQTimeAgoStringsHoursKey] stringByReplacingOccurrencesOfString: @"%d" withString: [NSString stringWithFormat: @"%d", (int)round(hours)]];
    
    //            hours < 48 && substitute($l.day, 1) ||
    else if (hours < 48)
        words = [[defs stringForKey: kJQTimeAgoStringsDayKey] stringByReplacingOccurrencesOfString: @"%d" withString: [NSString stringWithFormat: @"%d", (int)1]];
    //            days < 30 && substitute($l.days, Math.floor(days)) ||
    else if (days < 30)
        words = [[defs stringForKey: kJQTimeAgoStringsDaysKey] stringByReplacingOccurrencesOfString: @"%d" withString: [NSString stringWithFormat: @"%d", (int)floor(days)]];
    
    //            days < 60 && substitute($l.month, 1) ||
    else if (days < 60)
        words = [[defs stringForKey: kJQTimeAgoStringsMonthKey] stringByReplacingOccurrencesOfString: @"%d" withString: [NSString stringWithFormat: @"%d", (int)1]];
    
    //            days < 365 && substitute($l.months, Math.floor(days / 30)) ||
    else if (days < 365)
        words = [[defs stringForKey: kJQTimeAgoStringsMonthsKey] stringByReplacingOccurrencesOfString: @"%d" withString: [NSString stringWithFormat: @"%d", (int)floor(days/30.0)]];
    
    //            years < 2 && substitute($l.year, 1) ||
    else if (years < 2)
        words = [[defs stringForKey: kJQTimeAgoStringsYearKey] stringByReplacingOccurrencesOfString: @"%d" withString: [NSString stringWithFormat: @"%d", (int)1]];
    //            substitute($l.years, Math.floor(years));
    else
        words = [[defs stringForKey: kJQTimeAgoStringsYearsKey] stringByReplacingOccurrencesOfString: @"%d" withString: [NSString stringWithFormat: @"%d", (int)floor(years)]];
    //
    //            return $.trim([prefix, words, suffix].join(" "));
    NSString* retVal = [[NSString stringWithFormat: @"%@ %@ %@",
                         (prefix ? prefix : @""),
                         (words ? words : @""),
                         (suffix ? suffix : @"")] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return retVal;
    //        },
}

// Load settings
+ (void)load
{
    // Frameworks are guaranteed to be loaded by now so we can use NSDictionary, etc...
    // See here for details: http://www.mikeash.com/pyblog/friday-qa-2009-05-22-objective-c-class-loading-and-initialization.html
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        @autoreleasepool
        {
            NSDictionary* settings = [NSDictionary dictionaryWithObjectsAndKeys:
                                      [NSNumber numberWithBool: NO], kJQTimeAgoAllowFutureKey,
                                      NSLocalizedStringWithDefaultValue(kJQTimeAgoStringsPrefixAgoKey, nil, [NSBundle mainBundle], @" ", @"kJQTimeAgoStringsPrefixAgoKey"), kJQTimeAgoStringsPrefixAgoKey,
                                      NSLocalizedStringWithDefaultValue(kJQTimeAgoStringsPrefixFromNowKey, nil, [NSBundle mainBundle], @" ", @"kJQTimeAgoStringsPrefixFromNowKey"), kJQTimeAgoStringsPrefixFromNowKey,
                                      NSLocalizedStringWithDefaultValue(kJQTimeAgoStringsSuffixAgoKey, nil, [NSBundle mainBundle], @"ago", @"kJQTimeAgoStringsSuffixAgoKey"), kJQTimeAgoStringsSuffixAgoKey,
                                      NSLocalizedStringWithDefaultValue(kJQTimeAgoStringsSuffixFromNowKey, nil, [NSBundle mainBundle], @"from now", @"kJQTimeAgoStringsSuffixFromNowKey"), kJQTimeAgoStringsSuffixFromNowKey,
                                      NSLocalizedStringWithDefaultValue(kJQTimeAgoStringsSecondsKey, nil, [NSBundle mainBundle], @"less than a minute", @"kJQTimeAgoStringsSecondsKey"), kJQTimeAgoStringsSecondsKey,
                                      NSLocalizedStringWithDefaultValue(kJQTimeAgoStringsMinuteKey, nil, [NSBundle mainBundle], @"about a minute", @"kJQTimeAgoStringsMinuteKey"), kJQTimeAgoStringsMinuteKey,
                                      NSLocalizedStringWithDefaultValue(kJQTimeAgoStringsMinutesKey, nil, [NSBundle mainBundle], @"%d minutes", @"kJQTimeAgoStringsMinutesKey"), kJQTimeAgoStringsMinutesKey,
                                      NSLocalizedStringWithDefaultValue(kJQTimeAgoStringsHourKey, nil, [NSBundle mainBundle], @"about an hour", @"kJQTimeAgoStringsHourKey"), kJQTimeAgoStringsHourKey,
                                      NSLocalizedStringWithDefaultValue(kJQTimeAgoStringsHoursKey, nil, [NSBundle mainBundle], @"about %d hours", @"kJQTimeAgoStringsHoursKey"), kJQTimeAgoStringsHoursKey,
                                      NSLocalizedStringWithDefaultValue(kJQTimeAgoStringsDayKey, nil, [NSBundle mainBundle], @"about a day", @"kJQTimeAgoStringsDayKey"), kJQTimeAgoStringsDayKey,
                                      NSLocalizedStringWithDefaultValue(kJQTimeAgoStringsDaysKey, nil, [NSBundle mainBundle], @"%d days", @"kJQTimeAgoStringsDaysKey"), kJQTimeAgoStringsDaysKey,
                                      NSLocalizedStringWithDefaultValue(kJQTimeAgoStringsMonthKey, nil, [NSBundle mainBundle], @"about a month", @"kJQTimeAgoStringsMonthKey"), kJQTimeAgoStringsMonthKey,
                                      NSLocalizedStringWithDefaultValue(kJQTimeAgoStringsMonthsKey, nil, [NSBundle mainBundle], @"%d months", @"kJQTimeAgoStringsMonthsKey"), kJQTimeAgoStringsMonthsKey,
                                      NSLocalizedStringWithDefaultValue(kJQTimeAgoStringsYearKey, nil, [NSBundle mainBundle], @"about a year", @"kJQTimeAgoStringsYearKey"), kJQTimeAgoStringsYearKey,
                                      NSLocalizedStringWithDefaultValue(kJQTimeAgoStringsYearsKey, nil, [NSBundle mainBundle], @"%d years", @"kJQTimeAgoStringsYearsKey"), kJQTimeAgoStringsYearsKey,
                                      NSLocalizedStringWithDefaultValue(kJQTimeAgoStringsNeverKey, nil, [NSBundle mainBundle], @"never", @"kJQTimeAgoStringsNeverKey"), kJQTimeAgoStringsNeverKey,
                                      nil];
            
            
            [[NSUserDefaults standardUserDefaults] registerDefaults: settings];
        }
    });
}

@end

NSString* const kJQTimeAgoAllowFutureKey = @"kJQTimeAgoAllowFutureKey";
NSString* const kJQTimeAgoStringsPrefixAgoKey = @"kJQTimeAgoStringsPrefixAgoKey";
NSString* const kJQTimeAgoStringsPrefixFromNowKey = @"kJQTimeAgoStringsPrefixFromNowKey";
NSString* const kJQTimeAgoStringsSuffixAgoKey = @"kJQTimeAgoStringsSuffixAgoKey";
NSString* const kJQTimeAgoStringsSuffixFromNowKey = @"kJQTimeAgoStringsSuffixFromNowKey";
NSString* const kJQTimeAgoStringsSecondsKey = @"kJQTimeAgoStringsSecondsKey";
NSString* const kJQTimeAgoStringsMinuteKey = @"kJQTimeAgoStringsMinuteKey";
NSString* const kJQTimeAgoStringsMinutesKey = @"kJQTimeAgoStringsMinutesKey";
NSString* const kJQTimeAgoStringsHourKey = @"kJQTimeAgoStringsHourKey";
NSString* const kJQTimeAgoStringsHoursKey = @"kJQTimeAgoStringsHoursKey";
NSString* const kJQTimeAgoStringsDayKey = @"kJQTimeAgoStringsDayKey";
NSString* const kJQTimeAgoStringsDaysKey = @"kJQTimeAgoStringsDaysKey";
NSString* const kJQTimeAgoStringsMonthKey = @"kJQTimeAgoStringsMonthKey";
NSString* const kJQTimeAgoStringsMonthsKey = @"kJQTimeAgoStringsMonthsKey";
NSString* const kJQTimeAgoStringsYearKey = @"kJQTimeAgoStringsYearKey";
NSString* const kJQTimeAgoStringsYearsKey = @"kJQTimeAgoStringsYearsKey";
NSString* const kJQTimeAgoStringsNeverKey = @"kJQTimeAgoStringsNeverKey";
NSString* const kJQTimeAgoStringsNumbersKey = @"kJQTimeAgoStringsNumbersKey";
