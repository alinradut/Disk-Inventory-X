//
//  MainWindowController.m
//  Disk Inventory X
//
//  Created by Tjark Derlien on Mon Sep 29 2003.
//  Copyright (c) 2003 Tjark Derlien. All rights reserved.
//

#import "MainWindowController.h"
#import "InfoPanelController.h"
#import "Timing.h"
#import <TreeMapView/TreeMapView.h>
#import "FSItem-Utilities.h"
#import "FileSizeTransformer.h"
#import <CocoaTechStrings/NTLocalizedString.h>
#import "NTDefaultDirectory-Utilities.h"

@interface MainWindowController(Private)
- (void) moveToTrashSheetDidDismiss: (NSWindow*) sheet returnCode: (int) returnCode contextInfo: (void*) contextInfo;
@end

@implementation MainWindowController

- (id) initWithWindowNibName:(NSString *)windowNibName
{
	self = [super initWithWindowNibName: windowNibName];
	
	if ( self != nil )
	{
		//register volume transformers needed by various controls
		[NSValueTransformer setValueTransformer:[FileSizeTransformer transformer] forName: @"fileSizeTransformer"];
	}
	
	return self;
}

+ (FileSystemDoc*) documentForView: (NSView*) view
{
    FileSystemDoc* doc = nil;

    NSWindow *window = [view window];
    
    id delegate = [window delegate];
    NSAssert( delegate != nil, @"expecting to retrieve the document from the window controller, which should be the window's delegate; but the window has no delegte" );
    NSAssert( [delegate respondsToSelector: @selector(document)], @"window's delegate has no method 'document' to retrieve document object" );

	doc = [delegate document];
	NSAssert( [doc isKindOfClass: [FileSystemDoc class]], @"document object is not of expected kind 'FileSystemDoc'" );

    return doc;
}

+ (void) poofEffectInView: (NSView*)view inRect: (NSRect) rect; //rect in view coords
{
	//center poof antimation in the rect
	NSPoint poofEffectPoint = NSMakePoint( NSMinX(rect) + NSWidth(rect)/2,
										   NSMinY(rect) + NSHeight(rect)/2);
	
	//coordinates for the poof effect must be in screen coordidates, so...
	//convert view to window coords
	poofEffectPoint = [view convertPoint: poofEffectPoint toView: nil];
	
	//convert window to screen coords
	poofEffectPoint = [[view window] convertBaseToScreen: poofEffectPoint];
	
	NSSize size = NSMakeSize(NSWidth(rect), NSHeight(rect));
	
	//make sure the rect is not too small nor too large
	if ( fminf(size.width, size.height) <= 25 || ( size.width + size.height ) <= 80 )
		size = NSZeroSize;	//default size
	
	size.width = fminf( size.width, 200 );
	size.height = fminf( size.height, 200 );
	
	NSShowAnimationEffect(NSAnimationEffectPoof, poofEffectPoint, size, nil, (SEL)0, nil);
}

- (void) awakeFromNib
{
	//split window horizontally?
	if ( [[NSUserDefaults standardUserDefaults] boolForKey: SplitWindowHorizontally] )
	{
		[_splitter setVertical: NO];		
	}
	
	[_splitter setPositionAutosaveName: @"MainWindowSplitter"];
	
    [_kindsDrawer toggle: self];
	//[_selectionListDrawer toggle: self];
}

- (NSDrawer*) kindStatisticsDrawer
{
	return _kindsDrawer;
}

- (NSDrawer*) selectionListDrawer
{
	return _selectionListDrawer;
}

- (IBAction)toggleFileKindsDrawer:(id)sender
{
    [_kindsDrawer toggle: self];
}

- (IBAction) toggleSelectionListDrawer:(id)sender
{
	[_selectionListDrawer toggle: self];
}

- (IBAction) zoomIn:(id)sender
{
    FSItem *selectedItem = [[self document] selectedItem];

    if ( selectedItem != nil && [selectedItem isFolder] )
    {
        [[self document] zoomIntoItem: selectedItem];

        [self synchronizeWindowTitleWithDocumentName];
    }
}

- (IBAction) zoomOut:(id)sender
{
    FileSystemDoc *doc = [self document];
    
    FSItem *currentZoomedItem = [doc zoomedItem];

    if ( currentZoomedItem != [doc rootItem] )
    {
        [doc zoomOutOneStep];

        [doc setSelectedItem: currentZoomedItem];

        [self synchronizeWindowTitleWithDocumentName];
    }
}

- (IBAction) zoomOutTo:(id)sender
{
    FileSystemDoc *doc = [self document];
	FSItem *item = [sender representedObject];
	
	OBPRECONDITION( [doc rootItem] == [item root] );
	OBPRECONDITION( [[doc zoomStack] indexOfObjectIdenticalTo: item] != NSNotFound );
	
    FSItem *currentZoomedItem = [doc zoomedItem];
		
	[doc zoomOutToItem: item];
	
	[doc setSelectedItem: currentZoomedItem];
	
	[self synchronizeWindowTitleWithDocumentName];
}

- (IBAction) showInFinder:(id)sender
{
    FSItem *selectedItem = [[self document] selectedItem];

    if ( selectedItem != nil && [[selectedItem fileDesc] exists] )
        [[NSWorkspace sharedWorkspace] selectFile: [selectedItem path] inFileViewerRootedAtPath: nil];
}

- (IBAction) refresh:(id)sender
{
	FileSystemDoc *doc = [self document];
    FSItem *selectedItem = [doc selectedItem];
	
	if ( selectedItem == nil )
		return;
	
	[doc refreshItem: selectedItem];
	
	//the zoomed item might have changed
	[self synchronizeWindowTitleWithDocumentName];
}	

- (IBAction) refreshAll:(id)sender
{
	[[self document] refreshItem: nil];
	
	//the zoomed item might have changed
	[self synchronizeWindowTitleWithDocumentName];
}	

- (IBAction) moveToTrash:(id)sender
{
	FileSystemDoc *doc = [self document];
    FSItem *selectedItem = [doc selectedItem];
	
	if ( selectedItem == nil || selectedItem == [doc zoomedItem] || [selectedItem isSpecialItem] )
		return;
	
	//if file/folder lies on a network volume, it will be deleted!
	//So warn the user and ask to proceed.
	//(only local items can be moved to trash)
	if ( [[selectedItem fileDesc] isNetwork] )
	{
		NSString *msg = [NSString stringWithFormat: [NTLocalizedString localize: @"The item \"%@\" could not be moved to the trash."],
													[selectedItem displayName]];

		NSBeginAlertSheet( msg,
						  [NTLocalizedString localize: @"No"],
						  [NTLocalizedString localize: @"Yes"],
						  nil,
						  [self window],
						  self,
						  nil,
						  @selector(moveToTrashSheetDidDismiss: returnCode: contextInfo:),
						  selectedItem,
						  [NTLocalizedString localize: @"Would you like to delete it immediately?"]);
	}
	else
	{
		[self moveToTrashSheetDidDismiss: nil
							  returnCode: NSAlertAlternateReturn
							 contextInfo: selectedItem];
	}
}

- (IBAction) showPackageContents:(id)sender
{
    FileSystemDoc *doc = [self document];
	
    [doc setShowPackageContents: ![doc showPackageContents]];
}

- (IBAction) showFreeSpace:(id)sender
{
    FileSystemDoc *doc = [self document];
	
    [doc setShowFreeSpace: ![doc showFreeSpace]];
}

- (IBAction) showOtherSpace:(id)sender
{
    FileSystemDoc *doc = [self document];
	
    [doc setShowOtherSpace: ![doc showOtherSpace]];
}

- (IBAction) selectParentItem:(id)sender
{
    FileSystemDoc *doc = [self document];
    
    FSItem *selectedItem = [doc selectedItem];

	//don't set selection to parent if selected item is zoomed item or one of it's direct childs
    if ( selectedItem != [doc zoomedItem] && [selectedItem parent] != [doc zoomedItem] )
    {
        [doc setSelectedItem: [selectedItem parent]];
    }
}

- (IBAction) changeSplitting:(id)sender
{
	[_splitter setVertical: ![_splitter isVertical]];
	
	[[[self window] contentView] setNeedsDisplay: TRUE];
}

- (IBAction) showInformationPanel:(id)sender
{
	InfoPanelController *infoController = [InfoPanelController sharedController];
	
	if ( [infoController panelIsVisible] )
		[infoController hidePanel];
	else
	{
		FSItem *item = [[self document] selectedItem];
		[infoController showPanelWithFSItem: item];
	}
}

- (IBAction) showPhysicalSizes:(id) sender
{
	FileSystemDoc *doc = [self document];
	
	[doc setShowPhysicalFileSize: ![doc showPhysicalFileSize]];
	
	[self synchronizeWindowTitleWithDocumentName];
}

- (IBAction) ignoreCreatorCode:(id) sender
{
	FileSystemDoc *doc = [self document];
	
	[doc setIgnoreCreatorCode: ![doc ignoreCreatorCode]];
}

- (IBAction) performRenderBenchmark:(id)sender
{
	uint64_t startTime = getTime();
	
	unsigned count = 20;
	
	[_treeMapView benchmarkRenderingWithImageSize: NSMakeSize( 1024, 768 ) count: count];
	
	uint64_t doneTime = getTime();
	
	NSString *msg = [NSString stringWithFormat: @"rendering %u times took %.2f seconds", count, subtractTime(doneTime, startTime)];
	NSBeginInformationalAlertSheet( msg, nil, nil, nil, [_splitter window], nil, nil, nil, nil, @"" );
}

- (IBAction) performLayoutBenchmark:(id)sender
{
	uint64_t startTime = getTime();
	
	unsigned count = 100;
	
	[_treeMapView benchmarkLayoutCalculationWithImageSize: NSMakeSize( 1024, 768 ) count: count];
	
	uint64_t doneTime = getTime();
	
	NSString *msg = [NSString stringWithFormat: @"layout calculation %u times took %.2f seconds", count, subtractTime(doneTime, startTime)];
	NSBeginInformationalAlertSheet( msg, nil, nil, nil, [_splitter window], nil, nil, nil, nil, @"" );
}

- (BOOL) validateMenuItem: (id <NSMenuItem>) menuItem
{
    FileSystemDoc *doc = [self document];
    FSItem *selectedItem = [doc selectedItem];
	SEL menuAction = [menuItem action];

#define SET_TITLE( condition, string1, string2 ) \
	[menuItem setTitle: NSLocalizedString( (condition) ? string1 : string2, @"")]
		
#define SET_TITLE_AND_IMAGE( condition, string1, string2 )	\
	SET_TITLE( (condition), string1, string2 );				\
	if ( [menuItem isKindOfClass: [NSToolbarItemValidationAdapter class]] )\
		 [menuItem setState: (condition) ? NSOffState : NSOnState];
	
    if ( menuAction == @selector(zoomIn:) )
    {
        return selectedItem != nil && [selectedItem isFolder];
    }
    else if ( menuAction == @selector(zoomOut:) )
    {
        return [doc rootItem] != [doc zoomedItem];
    }
    else if ( menuAction == @selector(showInFinder:)
			  || menuAction == @selector(refresh:))
    {
        return selectedItem != nil;
    }
    else if ( menuAction == @selector(moveToTrash:) )
    {
		//the trash folder and items residing in it can't be moved to trash
		BOOL selectItemResidesInTrash = NO;
		if ( selectedItem != nil )
		{
			NTFileDesc *trashDesc = [[NTDefaultDirectory sharedInstance] safeTrashForDesc: [selectedItem fileDesc]];
			if ( [trashDesc isValid] )
			{
				FSItem* trashItem = [[doc rootItem] findItemByAbsolutePath: [trashDesc path] allowAncestors: NO];
				selectItemResidesInTrash = trashItem == selectedItem || [selectedItem isDescendantOf: trashItem];
			}
		}
        return !selectItemResidesInTrash && selectedItem != nil && selectedItem != [doc zoomedItem] && ![selectedItem isSpecialItem];
    }
    else if ( menuAction == @selector(showPackageContents:) )
    {
        SET_TITLE_AND_IMAGE( [doc showPackageContents], @"Hide Package Contents", @"Show Package Contents" );
    }
    else if ( menuAction == @selector(showFreeSpace:) )
    {
        SET_TITLE_AND_IMAGE( [doc showFreeSpace], @"Hide Free Space", @"Show Free Space" );
    }
    else if ( menuAction == @selector(showOtherSpace:) )
    {
        SET_TITLE_AND_IMAGE( [doc showOtherSpace], @"Hide Other Space", @"Show Other Space" );
		if ( [[[doc zoomedItem] fileDesc] isVolume] )
			return NO;
    }
    else if ( menuAction == @selector(showPhysicalSizes:) )
    {
        SET_TITLE_AND_IMAGE( [doc showPhysicalFileSize], @"Show Logical File Size", @"Show Physical File Size" );
    }
    else if ( menuAction == @selector(ignoreCreatorCode:) )
    {
        SET_TITLE_AND_IMAGE( [doc ignoreCreatorCode], @"Respect Creator Code", @"Ignore Creator Code" );
    }
    else if ( menuAction == @selector(toggleFileKindsDrawer:) )
    {
        SET_TITLE_AND_IMAGE( [_kindsDrawer state] == NSDrawerClosedState,
							 @"Show File Kind Statistics", @"Hide File Kind Statistics" );
    }
    else if ( menuAction == @selector(toggleSelectionListDrawer:) )
    {
        SET_TITLE( [_selectionListDrawer state] == NSDrawerClosedState,
							 @"Show Selection List", @"Hide Selection List" );
    }
    else if ( menuAction == @selector(selectParentItem:) )
    {
        return selectedItem != nil && selectedItem != [doc zoomedItem];
    }   
    else if ( menuAction == @selector(showInformationPanel:) )
    {
        SET_TITLE_AND_IMAGE( [[InfoPanelController sharedController] panelIsVisible],
							 @"Hide Information", @"Show Information" );
    }   
    else if ( menuAction == @selector(changeSplitting:) )
    {
        SET_TITLE( [_splitter isVertical], @"Split Horizontally", @"Split Vertically" );
    }   
    
#undef SET_TITLE
#undef SET_TITLE_AND_IMAGE
	
    return YES;
}

#pragma mark -----------------Toolbar support---------------------

- (NSString *)toolbarConfigurationName;
{
    return @"MainWindowToolbar";
}

#pragma mark -----------------NSWindow delegates-----------------------

- (void)windowDidBecomeMain:(NSNotification *)aNotification
{
	if ( [[InfoPanelController sharedController] panelIsVisible] )
	{
		FSItem *item = [[self document] selectedItem];
		[[InfoPanelController sharedController] showPanelWithFSItem: item];
	}
}

- (void)windowDidResignMain:(NSNotification *)notification;
{
}

- (void)windowWillClose:(NSNotification *)aNotification
{
	if ( [[aNotification object] isMainWindow]
		&& [[InfoPanelController sharedController] panelIsVisible] )
	{
		[[InfoPanelController sharedController] showPanelWithFSItem: nil];
	}
}

@end

@implementation MainWindowController(Private)

- (void) moveToTrashSheetDidDismiss: (NSWindow *) sheet
						 returnCode: (int) returnCode
						contextInfo: (void*) contextInfo
{
	if ( returnCode != NSAlertAlternateReturn )
		return;
	
	FileSystemDoc *doc = [self document];
	FSItem *selectedItem = (FSItem*) contextInfo;
	
	NSParameterAssert(	selectedItem != nil
						&& selectedItem != [doc zoomedItem] 
						&& ![selectedItem isSpecialItem] );
	
	//before we move the file/folder to trash, we need to calculate the position of the poof effect
	NSRect cellRect;
	NSView *view = nil;
	if ( [[self window] firstResponder] == _filesOutlineView )
	{
		view = _filesOutlineView;
		cellRect = [_filesOutlineView frameOfCellAtColumn: 0 row: [_filesOutlineView selectedRow]];
	}
	else
	{
		view = _treeMapView;
		cellRect = [_treeMapView itemRectByPathToItem: [selectedItem fsItemPathFromAncestor: [doc zoomedItem]]];
	}
	
	//now we can do it
	if ( [doc moveItemToTrash: selectedItem] )
	{
		[[self class] poofEffectInView: view inRect: cellRect];
		
        [self synchronizeWindowTitleWithDocumentName];
	}
	else
	{
		//failed
		[NTSimpleAlert infoSheet: [self window]
						 message: [NSString stringWithFormat: NSLocalizedString(@"\"%@\" cannot be moved to the trash.",@""), [selectedItem displayName] ]
					  subMessage: NSLocalizedString( @"Maybe you do not have sufficient access privileges.", @"" ) ];
	}
}

@end
