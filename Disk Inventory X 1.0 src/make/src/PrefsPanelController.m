//
//  PrefsPanelController.m
//  Disk Inventory X
//
//  Created by Tjark Derlien on 28.11.04.
//  Copyright 2004 Tjark Derlien. All rights reserved.
//

#import "PrefsPanelController.h"
#import <OmniAppKit/OAPreferenceClientRecord.h>
#import <OmniAppKit/OAPreferenceClient.h>

@interface OAPreferenceController(MakeVisible)
- (void)_restoreDefaultsSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
+ (void)registerItemName:(NSString *)itemName bundle:(NSBundle *)bundle description:(NSDictionary *)description;
@end

@implementation PrefsPanelController

+ (PrefsPanelController*) sharedPreferenceController
{
	static PrefsPanelController *sharedPreferenceController = nil;
	
	if (sharedPreferenceController == nil)
		sharedPreferenceController = [[self alloc] init];

	return sharedPreferenceController;
}

+ (void)registerItemName:(NSString *)itemName bundle:(NSBundle *)bundle description:(NSDictionary *)description;
{
	[super registerItemName: itemName bundle: bundle description: description];
}


- (void)_restoreDefaultsSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
{
    if (returnCode != NSAlertDefaultReturn)
        return;
	
    if (contextInfo != NULL)
	{
        // warn & wipe the entire defaults domain
		[super _restoreDefaultsSheetDidEnd: sheet returnCode: returnCode contextInfo: contextInfo];
    }
	else
	{
        // warn & wipe all prefs shown in all pages
        NSEnumerator *clientEnumerator;
        OAPreferenceClientRecord *aClientRecord;
		
		NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        
		//the preferences shown in each page must be declared proberly in info.plist!
        clientEnumerator = [[self allClientRecords] objectEnumerator];
        while ((aClientRecord = [clientEnumerator nextObject])) {
            NSArray *preferenceKeys;
            NSEnumerator *keyEnumerator;
            NSString *aKey;
			
            preferenceKeys = [[NSArray array] arrayByAddingObjectsFromArray:[[aClientRecord defaultsDictionary] allKeys]];
            preferenceKeys = [preferenceKeys arrayByAddingObjectsFromArray:[aClientRecord defaultsArray]];
            keyEnumerator = [preferenceKeys objectEnumerator];
            while ((aKey = [keyEnumerator nextObject])) 
			{
				[prefs willChangeValueForKey: aKey];
                [prefs removeObjectForKey: aKey];
				[prefs didChangeValueForKey: aKey];
			}
        }
    }
    [nonretained_currentClient valuesHaveChanged];
}

@end
