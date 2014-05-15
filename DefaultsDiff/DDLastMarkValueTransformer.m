//
//  DDLastMarkValueTransformer.m
//  DefaultsDiff
//
//  Copyright (c) 2014 Ian McCullough. All rights reserved.
//

#import "DDLastMarkValueTransformer.h"
#import "NSDate+TimeAgo.h"

@implementation DDLastMarkValueTransformer

+ (Class)transformedValueClass
{
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue:(id)value
{
    NSString* formatString = NSLocalizedStringWithDefaultValue(@"LastMarkString", nil, [NSBundle mainBundle], @"Last Mark: %@", "Format string for Last Mark menu item.");
    NSDate* date = [value isKindOfClass: [NSDate class]] ? (NSDate*)value : [NSDate distantPast];
    NSString* agoString = date.timeAgo;
    agoString =  [[[agoString substringToIndex: 1] uppercaseString] stringByAppendingString: [agoString substringFromIndex: 1]];
    return [formatString stringByReplacingOccurrencesOfString: @"%@" withString: agoString];
}

@end
