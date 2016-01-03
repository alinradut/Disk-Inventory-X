//
//  PrefsPageBase.m
//  Disk Inventory X
//
//  Created by Tjark Derlien on 29.11.04.
//  Copyright 2004 Tjark Derlien. All rights reserved.
//

#import "PrefsPageBase.h"
#import <OmniFoundation/OFNull.h>

@implementation PrefsPageBase

- (void)restoreDefaultsNoPrompt;
{
	//the preferences shown in each page must be declared in info.plist proberly!
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	
    unsigned int preferenceIndex = [preferences count];
    while (preferenceIndex--)
	{
        NSString *aKey = [[preferences objectAtIndex: preferenceIndex] key];
		
		//removeObjectForKey isn't Key-Value-Observing (KVO) compliant,
		//so make sure all observers get notified
		[prefs willChangeValueForKey: aKey];
		[prefs removeObjectForKey: aKey];
		[prefs didChangeValueForKey: aKey];
	}
}

- (BOOL)haveAnyDefaultsChanged;
{
	//the preferences shown in each page and their default values must be declared in info.plist proberly!
 	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	NSDictionary *defaultValues = [prefs volatileDomainForName: NSRegistrationDomain];
	
    unsigned int preferenceIndex = [preferences count];
    while (preferenceIndex--)
	{
        NSString *key = [[preferences objectAtIndex: preferenceIndex] key];
		
		id defValue = [defaultValues objectForKey: key];
		id prefValue = [prefs objectForKey: key];
		
		if ( OFNOTEQUAL( prefValue, defValue ) )
			return YES;
	}
	
	return NO;
}

@end
