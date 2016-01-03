//
//  MyDocumentController.m
//  Disk Accountant
//
//  Created by Tjark Derlien on Wed Oct 08 2003.
//  Copyright (c) 2003 Tjark Derlien. All rights reserved.
//

#import "MyDocumentController.h"
#import "DrivesPanelController.h"
#import "Preferences.h"
#import "PrefsPanelController.h"
#import "FileSystemDoc.h"
#import "DIXFinderCMInstaller.h"

//global variable which enables/disables logging
BOOL g_EnableLogging;

//============ implementation MyDocumentController ==========================================================

@implementation MyDocumentController

- (int) runModalOpenPanel: (NSOpenPanel*) openPanel forTypes: (NSArray*) extensions
{
    //we want the user to choose a directory (including packages)
    [openPanel setCanChooseDirectories: YES];
    [openPanel setCanChooseFiles: NO];
    [openPanel setTreatsFilePackagesAsDirectories: YES];
	
//	if ( ![[DrivesPanelController sharedController] panelIsVisible] )
	{
		//volumes panel isn't (yet) loaded, so show the open panel the normal way (as a modal window)
		return [openPanel runModalForTypes: nil];
	}
/*	else
	{
		//the volumes panel is loaded, so display the open panel as a nice sheet
		
		[openPanel beginSheetForDirectory: nil
									 file: nil
						   modalForWindow: [[DrivesPanelController sharedController] panel]
							modalDelegate: self
						   didEndSelector: @selector(openPanelDidEnd:returnCode:contextInfo:)
							  contextInfo: nil];
		
		//we will be called back after the sheet is closed, so return "Cancel" for now
		return NSCancelButton;
	}
	*/
}

- (void) openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if ( returnCode == NSOKButton )
	{
		//open selected folders
		NSEnumerator *fileEnum = [[sheet filenames] objectEnumerator];
		NSString *fileName;
		while ( (fileName = [fileEnum nextObject]) != nil )
		{
			//defer it till the next loop cycle to let the sheet closes itself first
			[[NSRunLoop currentRunLoop] performSelector:@selector(openDocumentWithContentsOfFile:)
												 target: self
											   argument: fileName
												  order: 1
												  modes: [NSArray arrayWithObject: NSDefaultRunLoopMode]];
		}
	}
}

- (void) openDocumentWithContentsOfFile: (NSString*) fileName
{
	[self openDocumentWithContentsOfFile: fileName display: [self shouldCreateUI]];
}

- (BOOL) applicationShouldOpenUntitledFile: (NSApplication*) sender
{
    //we don't want any untitled document as we need an existing folder
    return NO;
}

- (id)makeDocumentWithContentsOfFile:(NSString *)fileName ofType:(NSString *)docType
{
	//check whether "fileName" is a folder
	NSDictionary *attribs = [[NSFileManager defaultManager] fileAttributesAtPath: fileName traverseLink: NO];
    if ( attribs != nil )
	{
		NSString *type = [attribs fileType];
		if ( type != nil && [type isEqualToString: NSFileTypeDirectory] )
			return [super makeDocumentWithContentsOfFile:fileName ofType: @"Folder"];
	}
	
	return nil;
}

//"Open..." menu handler
- (IBAction)openDocument:(id)sender
{
	//we implement this method by ourself, so we can avoid that stupid message "document couldn't be opened"
	//in the case the user canceled the opening
	NSArray *fileNames = [self fileNamesFromRunningOpenPanel];
	
	if ( fileNames == nil )
		return; //cancel pressed in open panel
	
	NSEnumerator *enumerator = [fileNames objectEnumerator];
	NSString *fileName;
	while ( fileName = [enumerator nextObject] )
	{
		[self openDocumentWithContentsOfFile: fileName display: YES];
	}
}

//Application's delegate; called if file from recent list is selected
- (BOOL) application: (NSApplication*) theApp openFile: (NSString*) fileName
{
	//if "fileName" doesn't exist or isn't a folder, return NO so that it is removed from the recent list
	NSDictionary *attribs = [[NSFileManager defaultManager] fileAttributesAtPath: fileName traverseLink: NO];
    if ( attribs == nil || ![[attribs fileType] isEqualToString: NSFileTypeDirectory] )
		return NO;

	[self openDocumentWithContentsOfFile: fileName];
	
	//return TRUE to avoid nasty message if user canceled loading
	return TRUE;
}

- (NSString *)typeFromFileExtension:(NSString *)fileExtensionOrHFSFileType
{
	OSType type = NSHFSTypeCodeFromFileType(fileExtensionOrHFSFileType);
	if ( type == 0 )
		return @"Folder";
	else	
		return [super typeFromFileExtension: fileExtensionOrHFSFileType];
}

- (IBAction) showPreferencesPanel: (id) sender
{
	[[PrefsPanelController sharedPreferenceController] showPreferencesPanel: self];
	//[[OAPreferenceController sharedPreferenceController] showPreferencesPanel: self];
}

- (IBAction) gotoHomepage: (id) sender
{
	[[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: @"http://www.derlien.com"]];
}

- (IBAction) closeDonationPanel: (id) sender;
{
	[_donationPanel close]; //will release itself
	_donationPanel = nil;
}


#pragma mark --------app notifications-----------------

- (void) applicationWillFinishLaunching: (NSNotification*) notification
{
    //verify that our custom DocumentController is in use 
    NSAssert( [[NSDocumentController sharedDocumentController] isKindOfClass: [MyDocumentController class]], @"the shared DocumentController is not our custom class!" );
	
	g_EnableLogging = [[NSUserDefaults standardUserDefaults] boolForKey: EnableLogging];
	
	//show the drives panel before "applicationDidFinishLaunching" so the panel is visible before the first document is loaded
	//(e.g. through drag&drop)
	[[DrivesPanelController sharedController] showPanel];
}

- (void) applicationDidFinishLaunching:(NSNotification *)notification
{
	//show donate message
	if ( ![[NSUserDefaults standardUserDefaults] boolForKey: DontShowDonationMessage] )
	{
		[NSBundle loadNibNamed: @"DonationPanel" owner:self];
		[_donationPanel setWorksWhenModal: YES];
	}
	
//	DIXFinderCMInstaller *installer = [DIXFinderCMInstaller installer];
//	if ( ![installer isInstalled] )
//		[installer installToDomain: kUserDomain];
}

#pragma mark -----------------NSMenu delegates-----------------------

- (void) menuNeedsUpdate: (NSMenu*) zoomStackMenu
{
	OBPRECONDITION( _zoomStackMenu == zoomStackMenu );
	
	FileSystemDoc *doc = [self currentDocument];
	NSArray *zoomStack = [doc zoomStack];
	
	//thanks to ObjC, [zoomStack count] will evaluate to 0 if there is no current doc
	unsigned i;
	for ( i = 0; i < [zoomStack count]; i++ )
	{
		FSItem *fsItem = nil;
		if ( i == 0 )
			fsItem = [doc rootItem];
		else
			fsItem = [zoomStack objectAtIndex: i-1];
		
		if ( i >= [zoomStackMenu numberOfItems] )
			[zoomStackMenu addItem: [[[NSMenuItem alloc] init] autorelease]];
		
		NSMenuItem *menuItem = [zoomStackMenu itemAtIndex: i];
		
		[menuItem setTitle: [fsItem displayName]];
		[menuItem setRepresentedObject: fsItem];
		[menuItem setTarget: nil];
		[menuItem setAction: @selector(zoomOutTo:)];
	}
	
	while ( [zoomStackMenu numberOfItems] > [zoomStack count] )
		[zoomStackMenu removeItemAtIndex: [zoomStackMenu numberOfItems] -1];
}

@end

