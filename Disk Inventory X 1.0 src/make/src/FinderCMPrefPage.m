//
//  FinderCMPrefPage.m
//  Disk Inventory X
//
//  Created by Tjark Derlien on 07.04.05.
//  Copyright 2005 Tjark Derlien. All rights reserved.
//

#import "FinderCMPrefPage.h"
#import "DIXFinderCMInstaller.h"
#import <OmniFoundation/NSString-OFExtensions.h>
#import <CocoaTechFoundation/NTUsersAndGroups.h>
#import "NTFileDesc-Utilities.h"

@implementation FinderCMPrefPage

- (void) awakeFromNib
{
	[super awakeFromNib];
	
	NSButtonCell *userDomainRadioButton = [[_domainMatrix cells] objectAtIndex: 1];
	
	NSString *userDomainTitleFormat = [userDomainRadioButton title];
	NSString *userDomainTitle = [NSString stringWithFormat: userDomainTitleFormat, [[NTUsersAndGroups sharedInstance] userName]];
	
	[userDomainRadioButton setTitle: userDomainTitle];
}

/*becomeCurrentPreferenceClient
{
}
*/
- (void) updateUI
{
	DIXFinderCMInstaller *installer = [DIXFinderCMInstaller installer];
	
	NTFileDesc *installedExtension = [installer installedExtensionDesc];
	NTFileDesc *builtInExtension = [installer builtInExtensionDesc];
	NSAssert( builtInExtension != nil, @"exetutable doesn't contain the finder menu extension");
	
	if ( installedExtension != nil )
	{
		[_domainMatrix setHidden: YES];
		[_revealInFinderButton setHidden: NO];
		[_extensionPathTextField setHidden: NO];
		[_extensionPathTextField setStringValue: [installedExtension displayPath]];
		[_removeButton setEnabled: YES];
		
		NSString *statusInfoText = nil;
		NSString *installButtonText = nil;
		
		switch( [builtInExtension compareExtensionVersion: installedExtension] )
		{
			case NSOrderedAscending: //newer version
				statusInfoText = @"A newer version (%@) is installed.";
				installButtonText = @"Reinstall";
				break;
			case NSOrderedSame:		//current version
				statusInfoText = @"The current version (%@) is installed.";
				installButtonText = @"Reinstall";
				break;
			case NSOrderedDescending: //older version
				statusInfoText = @"An older version (%@) is installed. It is recommended to update.";
				installButtonText = @"Update";
				break;
		}
		
		NSString *installedVersion = [installedExtension extensionVersion];		
		
		statusInfoText = NSLocalizedString( statusInfoText, @"" );
		statusInfoText = [NSString stringWithFormat: statusInfoText, installedVersion];
		[_statusInfoTextField setStringValue: statusInfoText];
		
		[_installButton setTitle:  NSLocalizedString( installButtonText, @"" )];
	}
	else
	{
		[_domainMatrix setHidden: NO];
		[_revealInFinderButton setHidden: YES];
		[_extensionPathTextField setHidden: YES];
		[_extensionPathTextField setStringValue: @""];
		[_removeButton setEnabled: NO];
		
		[_statusInfoTextField setStringValue: NSLocalizedString( @"The Finder plugin is not installed. Click 'Install' to install it on your computer.", @"" )];
		[_installButton setTitle: NSLocalizedString( @"Install", @"" )];
	}
}


- (IBAction) install: (id) sender
{
	int domain = kUserDomain;
	
	NSButtonCell *localDomainRadioButton = [[_domainMatrix cells] objectAtIndex: 0];
	if ( [localDomainRadioButton state] == NSOnState )
		domain = kLocalDomain;
	
	DIXFinderCMInstaller *installer = [DIXFinderCMInstaller installer];
	//if the installation fails a message will be shown
	if ( [installer installToDomain: domain] )
		[_noteTextField setHidden: NO];
	
	[self updateUI];
}

- (IBAction) remove: (id) sender
{
	DIXFinderCMInstaller *installer = [DIXFinderCMInstaller installer];
	if ( [installer remove] )
		[_noteTextField setHidden: NO];
	
	[self updateUI];
}

- (IBAction) revealInFinder: (id) sender
{
	DIXFinderCMInstaller *installer = [DIXFinderCMInstaller installer];	
	NTFileDesc *installedExtension = [installer installedExtensionDesc];
	if ( installedExtension != nil )
        [[NSWorkspace sharedWorkspace] selectFile: [installedExtension path] inFileViewerRootedAtPath: nil];
}


@end
