//
//  DDAppDelegate.h
//  DefaultsDiff
//
//  Copyright (c) 2014 Ian McCullough. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef NS_ENUM(NSInteger, DDOutputFormat) {
    DDOutputFormat_MIN = 0,
    DDBeforeAndAfterDicts = 0,
    DDDefaultsWrites = 1,
    DDAfterDictOnly = 2,
    DDOutputFormat_COUNT,
};

@interface DDAppDelegate : NSObject <NSApplicationDelegate>

@property (strong) NSStatusItem* statusItem;
@property (weak) IBOutlet NSMenu* menu;

@property DDOutputFormat outputFormat;
@property (copy) NSDictionary* markedState;
@property (copy) NSDate* lastMarkTime;

- (IBAction)doMark: (id)sender;
- (IBAction)doDiff: (id)sender;
- (IBAction)doDiffAndMark: (id)sender;
- (IBAction)changeOutputFormat:(id)sender;

@end
