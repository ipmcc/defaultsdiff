//
//  DDAppDelegate.m
//  DefaultsDiff
//
//  Copyright (c) 2014 Ian McCullough. All rights reserved.
//

#import "DDAppDelegate.h"

@interface DDAppDelegate () <NSMenuDelegate>

@property (copy) NSDictionary* p_markedState;

@end

NSString* NSStringFromOutputFormat(DDOutputFormat format);
BOOL DDOutputFormatIsValid(DDOutputFormat outputFormat);

NSString* const DDOutputFormatDefaultsKey = @"outputFormat";

@implementation DDAppDelegate

#pragma mark NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSAssert(self.menu, @"No menu.");
    
    [[NSUserDefaults standardUserDefaults] registerDefaults: @{ DDOutputFormatDefaultsKey : @(DDDefaultsWrites) }];
    self.lastMarkTime = [NSDate distantPast];
    NSStatusItem* si = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    self.statusItem = si;
    si.highlightMode = YES;
    si.title = @"DD";
    si.menu = self.menu;
}

#pragma mark IBActions

- (IBAction)doMark: (id)sender
{
    [self updateMarkedState: nil];
}

- (IBAction)doDiff: (id)sender
{
    NSDictionary* current = self.currentState;
    NSDictionary* marked = self.markedState;
    NSDictionary* diff = [self diffDictBefore: marked andAfter: current];
    [self putDiffOnPasteboard: diff];
}

- (IBAction)doDiffAndMark: (id)sender
{
    NSDictionary* current = self.currentState;
    NSDictionary* marked = self.markedState;
    NSDictionary* diff = [self diffDictBefore: marked andAfter: current];
    [self putDiffOnPasteboard: diff];
    [self updateMarkedState: current];
}

- (IBAction)changeOutputFormat:(id)sender
{
    if (DDOutputFormatIsValid([sender tag]))
    {
        self.outputFormat = (DDOutputFormat)[sender tag];
    }
}

#pragma mark NSMenuDelegate

- (void)menuNeedsUpdate:(NSMenu *)menu
{
    
    if (menu.itemArray.count != DDOutputFormat_COUNT)
    {
        [menu removeAllItems];
        for (DDOutputFormat i = DDOutputFormat_MIN; i < DDOutputFormat_COUNT; i++)
        {
            NSMenuItem* x = [[NSMenuItem alloc] initWithTitle: NSStringFromOutputFormat(i) action: @selector(changeOutputFormat:) keyEquivalent: @""];
            x.tag = i;
            x.enabled = YES;
            [menu addItem: x];
        }
    }
    
    [menu.itemArray enumerateObjectsUsingBlock:^(NSMenuItem* obj, NSUInteger idx, BOOL *stop) {
        obj.state = obj.tag == self.outputFormat ? NSOnState : NSOffState;
        obj.enabled = YES;
    }];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    return YES;
}

#pragma mark Implementation

@dynamic markedState;

- (NSDictionary *)markedState
{
    return self.p_markedState;
}

- (void)setMarkedState:(NSDictionary *)markedState
{
    self.p_markedState = markedState;
    self.lastMarkTime = [NSDate date];
}

@dynamic outputFormat;

- (DDOutputFormat)outputFormat
{
    return (DDOutputFormat)[[NSUserDefaults standardUserDefaults] integerForKey: DDOutputFormatDefaultsKey];
}

- (void)setOutputFormat:(DDOutputFormat)outputFormat
{
    [[NSUserDefaults standardUserDefaults] setInteger: (NSInteger)outputFormat forKey: DDOutputFormatDefaultsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)putDiffOnPasteboard: (NSDictionary*)diff
{
    id pbItem = nil;
    switch (self.outputFormat)
    {
        case DDBeforeAndAfterDicts:
        {
            if ([diff[@"Before"] count] && [diff[@"After"] count])
            {
                pbItem = [diff description];
            }
            break;
        }
        case DDDefaultsWrites:
        {
            NSString* dws = [self defaultsWritesFromDiff: diff];
            pbItem = dws.length ? dws : nil;
            break;
        }
        case DDAfterDictOnly:
        {
            NSDictionary* after = ((NSDictionary*)diff)[@"After"];
            NSString* dws = [after description];
            pbItem = dws.length ? dws : nil;
            break;
        }
        case DDOutputFormat_COUNT:
            NSAssert(NO, @"Broken");
            return;
    }

    if (!pbItem)
    {
        NSBeep();
        return;
    }
    
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    (void)[pasteboard clearContents];
    if (![pasteboard writeObjects: @[pbItem]])
    {
        NSBeep();
        NSLog(@"Could not write objects to pasteboard: %@", pbItem);
    }
}

- (NSString*)elementValue: (id)value
{
    NSString* valueString = @"";
    
    if ([value isKindOfClass: [NSNumber class]])
    {
        CFTypeRef cfn = (CFTypeRef)CFBridgingRetain(value);
        CFNumberType cfnt = CFNumberGetType((CFNumberRef)value);
        if (CFGetTypeID(cfn) == CFBooleanGetTypeID())
        {
            valueString = [value boolValue] ? @"YES" : @"NO";
        }
        else if (cfnt == kCFNumberFloat32Type ||
                 cfnt == kCFNumberFloat64Type ||
                 cfnt == kCFNumberFloatType ||
                 cfnt == kCFNumberDoubleType ||
                 cfnt == kCFNumberCGFloatType)
        {
            valueString = [value description];
        }
        else
        {
            valueString = [value description];
        }
    }
    else if ([value isKindOfClass: [NSData class]])
    {
        valueString = [value description];
    }
    else if ([value isKindOfClass: [NSString class]])
    {
        valueString = [[@[ value ] description] stringByTrimmingCharactersInSet: [NSCharacterSet characterSetWithCharactersInString: @" []"]];
    }
    
    return valueString;

}

- (NSString*)defaultsWritesFromDiff: (NSDictionary*)diff
{
    NSDictionary* after = diff[@"After"];

    NSMutableArray* dws = [NSMutableArray array];
    
    
    for (NSString* app in after.allKeys)
    {
        const BOOL isGlobal = [app isEqual: (NSString*)kCFPreferencesAnyApplication];
        NSString* domain = isGlobal ? NSGlobalDomain : app;

        NSDictionary* appDict = after[app]; NSAssert([appDict isKindOfClass: [NSDictionary class]], @"Ummm.");
        for (NSString* key in appDict.allKeys)
        {
            NSMutableString* dw = [NSMutableString stringWithFormat: @"defaults write %@ %@ ", domain, key];
            
            NSString* typeString = @"";
            NSString* valueString = @"";
            
            // Type the data
            id value = appDict[key];
            
            if ([[NSNull null] isEqual: value])
            {
                // it was removed.
                [dws addObject: [NSString stringWithFormat: @"defaults delete %@ %@", domain, key]];
                continue;
            }
            else if ([value isKindOfClass: [NSNumber class]])
            {
                CFTypeRef cfn = (__bridge CFTypeRef)value;
                CFNumberType cfnt = CFNumberGetType((CFNumberRef)value);
                if (CFGetTypeID(cfn) == CFBooleanGetTypeID())
                {
                    typeString = @"-boolean";
                    valueString = [self elementValue: value];
                }
                else if (cfnt == kCFNumberFloat32Type ||
                         cfnt == kCFNumberFloat64Type ||
                         cfnt == kCFNumberFloatType ||
                         cfnt == kCFNumberDoubleType ||
                         cfnt == kCFNumberCGFloatType)
                {
                    typeString = @"-float";
                    valueString = [self elementValue: value];
                }
                else
                {
                    typeString = @"-integer";
                    valueString = [self elementValue: value];
                }
            }
            else if ([value isKindOfClass: [NSArray class]])
            {
                typeString = @"-array";
                NSMutableArray* elementStrings = [NSMutableArray array];
                [(NSArray*)value enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    [elementStrings addObject: [self elementValue: obj]];
                }];
                
                valueString = [elementStrings componentsJoinedByString: @" "];
            }
            else if ([value isKindOfClass: [NSDictionary class]])
            {
                typeString = @"-dict";
                NSMutableArray* elementStrings = [NSMutableArray array];
                [(NSDictionary*)value enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                    [elementStrings addObject: [self elementValue: key]];
                    [elementStrings addObject: [self elementValue: obj]];
                }];
                
                valueString = [elementStrings componentsJoinedByString: @" "];
            }
            else
            {
                NSAssert(NO, @"Not implemented!");
            }
            
            [dw appendFormat: @"%@ %@", typeString, valueString];
            
            [dws addObject: dw];
        }
    }

    return [dws componentsJoinedByString: @"\n"];
}

- (NSDictionary*)diffDictBefore: (NSDictionary*)before andAfter: (NSDictionary*)after
{
    NSMutableDictionary* differentBefore = [NSMutableDictionary dictionary];
    NSMutableDictionary* differentAfter  = [NSMutableDictionary dictionary];
    
    NSMutableSet* allKeys = [NSMutableSet setWithArray: before.allKeys]; [allKeys unionSet: [NSSet setWithArray: after.allKeys]];
    
    for (id<NSCopying> key in allKeys)
    {
        id a = before[key] ?: [NSNull null];
        id b = after[key] ?: [NSNull null];
        
        if ([a isEqual: b])
            continue;
        
        if ([a isKindOfClass: [NSDictionary class]])
        {
            NSDictionary* sub = [self diffDictBefore: a andAfter: b];
            differentBefore[key] = sub[@"Before"];
            differentAfter[key] = sub[@"After"];
        }
        else
        {
            differentBefore[key] = a;
            differentAfter[key] = b;
        }
    }
    
    return  @{ @"Before" : [differentBefore copy], @"After" : [differentAfter copy] };
}

- (NSDictionary*)currentState
{
    CFStringRef host = kCFPreferencesAnyHost;
 
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated"
    NSArray *doms = (NSArray *)CFBridgingRelease(CFPreferencesCopyApplicationList(kCFPreferencesCurrentUser, host));
#pragma GCC diagnostic pop

    NSMutableDictionary *tmp = [NSMutableDictionary new];

    for (NSString *dom in doms)
    {
        NSDictionary* dict = (NSDictionary *)CFBridgingRelease(CFPreferencesCopyMultiple(NULL, (__bridge CFStringRef)dom, kCFPreferencesCurrentUser, host));
        if (dict)
        {
            [tmp setObject: dict forKey: dom];
        }
    }
    
    return tmp;
}

- (void)updateMarkedState: (NSDictionary*)dictionary
{
    self.markedState = dictionary ?: self.currentState;
}

@end

NSString* NSStringFromOutputFormat(DDOutputFormat format)
{
    switch (format) {
        case DDBeforeAndAfterDicts:
            return @"Before/After Dictionary";
            break;
        case DDDefaultsWrites:
            return @"Defaults Writes";
            break;
        case DDAfterDictOnly:
            return @"After State Only";
            break;
        case DDOutputFormat_COUNT:
            return nil;
    }
    return nil;
}

BOOL DDOutputFormatIsValid(DDOutputFormat outputFormat)
{
    return outputFormat >= DDOutputFormat_MIN && outputFormat < DDOutputFormat_COUNT;
}


