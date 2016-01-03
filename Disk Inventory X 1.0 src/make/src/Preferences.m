/*
 *  Preferences.m
 *  Disk Inventory X
 *
 *  Created by Tjark Derlien on 24.11.04.
 *  Copyright 2004 Tjark Derlien. All rights reserved.
 *
 */

#include "Preferences.h"
#import <OmniFoundation/NSDictionary-OFExtensions.h>
#import <OmniFoundation/NSMutableDictionary-OFExtensions.h>

//keys for preference values
NSString *ShowPackageContents			= @"ShowPackageContents";
NSString *ShowFreeSpace					= @"ShowFreeSpace";
NSString *ShowOtherSpace				= @"ShowOtherSpace";
NSString *IgnoreCreatorCode				= @"IgnoreCreatorCode";
NSString *ShowPhysicalFileSize			= @"ShowPhysicalFileSize"; //logical size otherwise (like the Finder)
NSString *UseSmallFontInKindStatistic	= @"UseSmallFontInKindStatisticView";
NSString *UseSmallFontInFilesView		= @"UseSmallFontInFilesView";
NSString *UseSmallFontInSelectionList	= @"UseSmallFontInSelectionList";
NSString *SplitWindowHorizontally		= @"SplitWindowHorizontally";
NSString *AnimatedZooming				= @"AnimatedZooming";
NSString *EnableLogging					= @"EnableLogging";
NSString *DontShowDonationMessage		= @"DontShowDonationMessage";
NSString *ShareKindColors				= @"ShareKindColors";

@interface NSMutableDictionary(DocumentPreferences_Private)
- (void) copyValuesFromSharedDefaults;
@end


@implementation NSMutableDictionary(PreferencesValues)

- (id) initWithDefaults
{
	self = [self init];
	
	[self copyValuesFromSharedDefaults];
	
	return self;
}

- (BOOL) showPackageContents
{
	return [self boolForKey: ShowPackageContents];
}

- (void) setShowPackageContents: (BOOL) value;
{
	[self setBoolValue: value forKey: ShowPackageContents];
}

- (BOOL) showFreeSpace;
{
	return [self boolForKey: ShowFreeSpace];
}

- (void) setShowFreeSpace: (BOOL) value;
{
	[self setBoolValue: value forKey: ShowFreeSpace];
}

- (BOOL) showOtherSpace;
{
	return [self boolForKey: ShowOtherSpace];
}

- (void) setShowOtherSpace: (BOOL) value;
{
	[self setBoolValue: value forKey: ShowOtherSpace];
}

- (BOOL) ignoreCreatorCode;
{
	return [self boolForKey: IgnoreCreatorCode];
}

- (void) setIgnoreCreatorCode: (BOOL) value
{
	[self setBoolValue: value forKey: IgnoreCreatorCode];
}

- (BOOL) showPhysicalFileSize
{
	return [self boolForKey: ShowPhysicalFileSize];
}

- (void) setShowPhysicalFileSize: (BOOL) value
{
	[self setBoolValue: value forKey: ShowPhysicalFileSize];
}

@end

@implementation NSMutableDictionary(DocumentPreferences_Private)

- (void) copyValuesFromSharedDefaults
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
#define COPYVALUEBOOL( name ) [self setBoolValue: [defaults boolForKey: name] forKey: name]
	
	COPYVALUEBOOL( ShowPackageContents );
	COPYVALUEBOOL( ShowFreeSpace );
	COPYVALUEBOOL( ShowOtherSpace );
	COPYVALUEBOOL( IgnoreCreatorCode );
	COPYVALUEBOOL( ShowPhysicalFileSize );
	
#undef COPYVALUEBOOL
}

@end

