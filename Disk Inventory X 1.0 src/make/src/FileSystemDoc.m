//
//  MyDocument.m
//  Disk Accountant
//
//  Created by Tjark Derlien on Wed Oct 08 2003.
//  Copyright (c) 2003 Tjark Derlien. All rights reserved.
//

#import "FileSystemDoc.h"
#import "MainWindowController.h"
#import "DrivesPanelController.h"
#import "FileSizeFormatter.h"
#import "Timing.h"
#import "InfoPanelController.h"
#import "NTDefaultDirectory-Utilities.h"
#import "FSItem-Utilities.h"
#import <NTFileDesc-AccessExtensions.h>
#import <OmniFoundation/NSArray-OFExtensions.h>

NSString *CollectFileKindStatisticsCanceledException = @"CollectFileKindStatisticsCanceledException";

//============ implementation FileKindStatistic ==========================================================

@implementation FileKindStatistic

- (id) initWithItem: (FSItem*) item
{
    self = [super init];
    
    _kindName = [item kindName];
	[_kindName retain];

	_size = [item sizeValue];
	
	_items = [[NSMutableSet alloc] initWithObjects: item, nil];

    return self;
}

- (void) dealloc
{
    [_kindName release];
	[_items release];
	
	[super dealloc];
}

- (void) addItem: (FSItem* )item
{
	NSParameterAssert( ![_items containsObject: item] );
	
	[_items addObject: item];
	
	_size += [item sizeValue];
}

- (void) removeItem: (FSItem* )item
{
	NSParameterAssert( [_items containsObject: item] );
	
	_size -= [item sizeValue];
	
	[_items removeObject: item];
}

- (NSString*) description
{
    return [[self kindName] stringByAppendingFormat: @" {%u files; %.1f kB}", [self fileCount], (float) [self size]/1024]; 
}

- (NSString*) kindName
{
    return _kindName;
}

//# of files of this kind
- (unsigned) fileCount
{
	return [_items count];
}

//sum of sizes of files of this kind
- (unsigned long long) size
{
	return _size;
}

- (void) recalculateSize
{
	NSEnumerator *itemEnum = [self itemEnumerator];
	FSItem *item = nil;
	_size = 0;
	while ( (item = [itemEnum nextObject]) != nil )
		_size += [item sizeValue];
}

- (NSSet*) items
{
	return _items;
}

- (NSEnumerator*) itemEnumerator
{
	return [_items objectEnumerator];
}

//compare the size descendingly
- (NSComparisonResult) compareSizeDescendingly: (FileKindStatistic*) other
{
	UInt64 mySize = [self size];
	UInt64 otherSize = [other size];
	
	//we want the sorting to be descending
	if ( mySize < otherSize )
		return NSOrderedDescending;
	if ( mySize > otherSize )
		return NSOrderedAscending;
	
	//if both object have the same size, order by their names
	return [[self kindName] compare: [other kindName] options: NSNumericSearch];
}

@end

//============ interface FileSystemDoc(Private) ==========================================================

@interface FileSystemDoc(Private)

- (void) addItemToFileKindStatistic: (FSItem*) item includingChilds: (BOOL) includingChilds;
- (void) removeItemFromFileKindStatistic: (FSItem*) item includingChilds: (BOOL) includingChilds;
- (void) recalculateFileKindStatisticSizes;
- (void) removePackagesFromFileKindStatistic: (FSItem*) item;
- (void) addPackagesToFileKindStatistic: (FSItem*) item; 	
- (void) removeEmptyKindStatistics;

- (void) reserveColorsForLargestKinds;

- (void) checkTrash: (FSItem*) trashItem
withPreviousContent: (NSArray*) oldContent
			forItem: (FSItem*) itemTrashed;

- (void) recalculateTotalSize;

- (NSMutableDictionary*) viewOptions;

- (void) postViewOptionChangedNotificationForOption: (NSString*) optionName;
- (void) postNotificationName: (NSString*) name oldItem: (FSItem*) old newItem:  (FSItem*) new;

@end

//=========== implementation FileSystemDoc ==========================================================

/* keys for Key Value Observing (KVO) */
NSString *DocKeySelectedItem = @"selectedItem";

/* FileSystemDoc Notifications */
NSString *GlobalSelectionChangedNotification = @"GlobalSelectionChanged";
NSString *ZoomedItemChangedNotification = @"ZoomedItemChanged";
NSString *FSItemsChangedNotification = @"FSItemsChanged";
NSString *ViewOptionChangedNotification = @"ViewOptionsChangedNotification";
NSString *ChangedViewOption = @"ChangedViewOption";
NSString *NewItem = @"NewItem";
NSString *OldItem = @"OldItem";

@implementation FileSystemDoc

- (id)init
{
    self = [super init];
    if ( self != nil )
    {
        // Add your subclass-specific initialization here.
        // If an error occurs here, send a [self release] message and return nil.
		
        _zoomStack = [[NSMutableArray alloc] init];
		
		_viewOptions = [[NSMutableDictionary alloc] initWithDefaults];
		
		NSUserDefaultsController *sharedDefsController = [NSUserDefaultsController sharedUserDefaultsController];
		[sharedDefsController addObserver: self
							   forKeyPath: [@"values." stringByAppendingString: ShareKindColors]
								  options: 0
								  context: ShareKindColors];		
    }
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];        
	
	NSUserDefaultsController *sharedDefsController = [NSUserDefaultsController sharedUserDefaultsController];
	[sharedDefsController removeObserver: self forKeyPath: [@"values." stringByAppendingString: ShareKindColors]];
	
	[_viewOptions release];
    [_fileKindStatistics release];
    [_zoomStack release];
	
    [_rootItem release];
	
	[_directoryStack release];

	[_kindColors release];
	
    [super dealloc];
}

- (void) makeWindowControllers
{
    // Override method to instantiate controllers for multiple document windows.
    MainWindowController *controller = [[MainWindowController alloc] initWithWindowNibName: [self windowNibName]];
    [self addWindowController:controller];
    [controller release];
}


- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"TreeMap";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
}

- (BOOL) readFromFile: (NSString *) folder ofType: (NSString *) docType
{
    //now the real work: loading the folder contents
    NS_DURING
		_progressController = [[LoadingPanelController alloc] init];
		[_progressController startAnimation];	
		
		uint64_t startTime = getTime();
		
        _rootItem = [[FSItem alloc] initWithPath: folder];
		[_rootItem setDelegate: self];
		
        //[_rootItem loadChilds];
        [_rootItem loadChildren];
        
 		uint64_t doneLoadingTime = getTime();
		LOG (@"loading time:  %.2f seconds", subtractTime(doneLoadingTime, startTime));
		
       LOG(@"************** Loading complete *******************" );
        LOG(@"%u items created", g_fileCount + g_folderCount );
        LOG(@"%u files", g_fileCount );
        LOG(@"%u folders", g_folderCount );
        
		//ok, now we've got an FSItem for every file and directory in the given folder
		//[_progressController setMessageText: NSLocalizedString( @"Classifying Files", @"")];
				
		//collect sizes and file count of all file kinds 
		[self refreshFileKindStatistics];
		
		uint64_t doneFileKindStatsTime = getTime();
		LOG (@"file kind statistics time:  %.2f seconds", subtractTime(doneFileKindStatsTime, doneLoadingTime));
		
		//the modal session must be ended in the same NS_DURING section (if no exception occured)
		[_progressController release];
		_progressController = nil;
		
    NS_HANDLER
        LOG( @"exception '%@' occured during directory traversal: %@", [localException name], [localException reason] );
		
		//according to the docu, we don't need to end a modal session explicitly in the case of an exception
		[_progressController closeNoModalEnd];
		[_progressController release];
		_progressController = nil;
		
		[_rootItem release];
		_rootItem = nil;

		if ( [[localException name] isEqualToString: FSItemLoadingCanceledException]
			 || [[localException name] isEqualToString: CollectFileKindStatisticsCanceledException] )
		{
			//loading canceled by user
		}
		else
		{
			//error
			NSRunInformationalAlertPanel( NSLocalizedString( @"The folder's content could not be loaded.", @""), [localException reason], nil, nil, nil);
		}
		
        NS_VALUERETURN( NO, BOOL );
    NS_ENDHANDLER

    [_directoryStack release];
    _directoryStack = nil;
	
   return YES;
}

- (IBAction) cancelScanningFolder:(id)sender
{
	[[NSApplication sharedApplication] stopModal];
}

- (BOOL) showPhysicalFileSize;
{
    return [[self viewOptions] showPhysicalFileSize];
}

- (void) setShowPhysicalFileSize: (BOOL) show
{
	[[self viewOptions] setShowPhysicalFileSize: show];
	
	[self recalculateTotalSize];
	[self recalculateFileKindStatisticSizes];
	
	[self postViewOptionChangedNotificationForOption: ShowPhysicalFileSize];
}

- (BOOL) showPackageContents
{
    return [[self viewOptions] showPackageContents];
}

- (void) setShowPackageContents: (BOOL) show
{
    show = (show == 0) ? NO : YES;
    if ( show == [[self viewOptions] showPackageContents] )
		return;
	
	//remove all packages from kind statistic as they are now regarded differently (file<->folder)
	[self removePackagesFromFileKindStatistic: nil]; 
	
	[[self viewOptions] setShowPackageContents: show];
	
	//re-add packages to statistic
	[self addPackagesToFileKindStatistic: nil]; 	
	
	FSItem* selectedItem = [self selectedItem];
	
	//invalidate current selection, as the selection might be an item in a package
	//(if "show package content" is turned off, files in packages aren't visible any more)
	if ( ![self showPackageContents] && selectedItem != nil )
		[self setSelectedItem: nil];
	
	[self postViewOptionChangedNotificationForOption: ShowPackageContents];
	
	//if "show package contents" is turned off, check if selection is within a package
	//(as the selection got invalid)
	if ( ![self showPackageContents] && selectedItem != nil)
	{
		//select it's farest parent which is a package
		FSItem *packageItem = nil;
		FSItem *parentItem = [selectedItem parent];
		while ( parentItem != nil && parentItem != [self zoomedItem] )
		{
			if ( [parentItem isPackage] )
				packageItem = parentItem;
			parentItem = [parentItem parent];
		}
		
		selectedItem = packageItem;
	}
	
	//restore selection
	if ( ![self showPackageContents] && selectedItem != nil )
		[self setSelectedItem: selectedItem];
}

- (BOOL) showFreeSpace
{
    return [[self viewOptions] showFreeSpace];
}

- (void) setShowFreeSpace: (BOOL) show
{
	[[self viewOptions] setShowFreeSpace: show];
	
	[self postViewOptionChangedNotificationForOption: ShowFreeSpace];
}

- (BOOL) showOtherSpace
{
    return [[self viewOptions] showOtherSpace];
}

- (void) setShowOtherSpace: (BOOL) show
{
	[[self viewOptions] setShowOtherSpace: show];
	
	[self postViewOptionChangedNotificationForOption: ShowOtherSpace];
}

- (BOOL) ignoreCreatorCode
{
	return [[self viewOptions] ignoreCreatorCode];
}

- (void) setIgnoreCreatorCode: (BOOL) ignoreIt
{
	[[self viewOptions] setIgnoreCreatorCode: ignoreIt];
	
	[[self rootItem] setKindStringIgnoringCreatorCode: ignoreIt includeChilds: YES];
	
	[self refreshFileKindStatistics];
	
	[self postViewOptionChangedNotificationForOption: IgnoreCreatorCode];
}

//helper method; returns YES/NO for packages in dependency of the showPackageContents-Flag
- (BOOL) itemIsNode: (FSItem*) item
{
    //the zoomed item is always a node, even if it is a package and "show package contents" is turned off
    //(you can always zoom into packages)
    if ( item == [self zoomedItem] )
        return YES;
    
    if ( [self showPackageContents] )
        return [item isFolder];
    else
        return [item isFolder] && ![item isPackage];
}

- (FSItem*) rootItem;
{
    return _rootItem;
}

- (BOOL) moveItemToTrash: (FSItem*) item
{
	NSParameterAssert( item != nil && item != [self zoomedItem] && ![item isSpecialItem] );
	
	//remember trash content so we can find the trashed item afterwards
	NSArray *prevTrashContents = nil;
	FSItem *trashItem = nil;
	
	//if file/folder lies on a network volume, it will be deleted!
	//(only local items can be moved to trash)
	if ( ![[item fileDesc] isNetwork] )
	{
		NTFileDesc *trashDesc = [[NTDefaultDirectory sharedInstance] safeTrashForDesc: [item fileDesc]];
		trashItem = [trashDesc isValid] ? [[self rootItem] findItemByAbsolutePath: [trashDesc path] allowAncestors: NO] : nil;
		
		if ( trashItem != nil )
			prevTrashContents = [trashDesc directoryContents: NO/*visibleOnly*/ resolveIfAlias: NO];
	}
	
	//move file/folder to trash
	NSArray *filesToTrash = [NSArray arrayWithObject: [item name]];
	int tag = 0;
	if ( ![[NSWorkspace sharedWorkspace] performFileOperation: NSWorkspaceRecycleOperation
													  source: [item folderName]
												 destination: @""
													   files: filesToTrash
														 tag: &tag] )
	{
		return NO;
	}
	
	//if the selected item should be removed, invalidate our selection
	if ( [self selectedItem] == item )
		[self setSelectedItem: nil];
	
	//now remove the item from the parent's list
	FSItem *parent = [item parent];
	NSAssert( parent != nil, @"root item shouldn't be deletable" );
	
	//retain and autorelease "item", so it will be accessible till all is done
	[[item retain] autorelease];
	
	[parent removeChild: item updateParent: YES];
	
	//keep kind statistic in sync
	[self willChangeValueForKey: @"kindStatistics"];
	[self removeItemFromFileKindStatistic: item includingChilds: YES];
	
	//the users's trash may have been created with the trash operation (if item is not on the same volume as the user's home)
	//in this case, we won't see the trashed item, as we are not showing the trash folder currently 
	if ( trashItem != nil && prevTrashContents != nil )
		[self checkTrash: trashItem withPreviousContent: prevTrashContents forItem: item];

	//"checkTrash" may have editied the kind statistic, so notify observers but now
	[self didChangeValueForKey: @"kindStatistics"];
	
	//notify observers of the change
	[[NSNotificationCenter defaultCenter] postNotificationName: FSItemsChangedNotification object: self];
	
	//try to set "parent" as new selection
	if ( parent != [self zoomedItem] )
		[self setSelectedItem: parent];
	
	return YES;
}

- (void) refreshItem: (FSItem*) item
{
	//refresh zoomed item?
	if ( item == nil )
		item = [self zoomedItem];
	
	//remember selection
	NSString *selectedItemPath = nil;
	if ( [self selectedItem] != nil ) 
	{
		selectedItemPath = [[self selectedItem] path];
		[self setSelectedItem: nil];
	}
	
	//refresh item or one of it's ancestors (whichever is still valid)
	BOOL zoomedItemIsInvalid = NO;
	while ( item != nil && ![item exists] )
	{
		if ( item == [self zoomedItem] )
			zoomedItemIsInvalid = YES;
		
		item = [item parent];
	}
	
	if ( item == nil )
	{
		//the folder/volume which we are showing doesn't exist anymore!
		[NTSimpleAlert infoSheet: [[[self windowControllers] objectAtIndex: 0] window]
						 message: [NSString stringWithFormat: @"\"%@\" does not exist any more.", [[self rootItem] displayPath]]
					  subMessage: NSLocalizedString( @"The folder will remain visible in Disk Inventory X, but the files cannot be accessed (e.g. shown in the Finder).",@"") ];
		return;
	}
	
	FSItem *refreshedItem = nil;
	
	NS_DURING
		//we only show a progress indicator if the item to refresh has "many" childs
		//(of course this could have changed since the loading, but what criteria should
		//we use instead?)
		NSAssert( _progressController == nil, @"progress panel wasn't destroyed after last use" );
		unsigned progressPanelLimit = [[item fileDesc] isNetwork] ? 200 : 500;
		if ( [item deepFileCountIncludingPackages: YES] > progressPanelLimit )
		{
			//NSWindow *window = [[[self windowControllers] objectAtIndex: 0] window];
			_progressController = [[LoadingPanelController alloc] init];
			[_progressController startAnimation];
		}
		
		refreshedItem = [[[FSItem alloc] initWithPath: [item path]] autorelease];
		[refreshedItem setDelegate: self];
		if ( [refreshedItem isFolder] )
			 [refreshedItem loadChildren];
		
		[_progressController release];
		_progressController = nil;
	NS_HANDLER
		[_progressController closeNoModalEnd];
		[_progressController release];
		_progressController = nil;
		
		if ( [[localException name] isEqualToString: FSItemLoadingCanceledException]
			 || [[localException name] isEqualToString: CollectFileKindStatisticsCanceledException] )
		{
			//refreshing canceled by user
		}
		else
		{
			//error
			[NTSimpleAlert infoSheet: [[[self windowControllers] objectAtIndex: 0] window]
							 message: NSLocalizedString( @"The folder's content could not be loaded.", @"")
						  subMessage: [localException reason] ];
		}
		NS_VOIDRETURN;
	NS_ENDHANDLER
	
	//keep item valid till we are done
	[[item retain] autorelease];
	
	if ( _rootItem == item )
	{
		[_rootItem release];
		_rootItem = [refreshedItem retain];
		//rebuild file kind statistics
		[self refreshFileKindStatistics];
	}
	else
	{
		//update file kind statistics
		if ( !zoomedItemIsInvalid )
			[self willChangeValueForKey: @"kindStatistics"];
		
		[self removeItemFromFileKindStatistic: item includingChilds: YES];
		
		FSItem *parent = [item parent];
		[parent replaceChild: item withItem: refreshedItem updateParent: YES];
		
		[self addItemToFileKindStatistic: refreshedItem includingChilds: YES];
		
		if ( !zoomedItemIsInvalid )
			[self didChangeValueForKey: @"kindStatistics"];
	}
	
	//if current zoomed item got invalid, zoom out as far as necessary
	if ( zoomedItemIsInvalid )
	{
		FSItem *newZoomItem = item;
		//zoom to an ancestor of "item" which is in the zoom stack
		while ( [_zoomStack indexOfObjectIdenticalTo: newZoomItem] == NSNotFound && newZoomItem != nil )
			newZoomItem = [newZoomItem parent];

		//will posts a notification about the change
		[self zoomOutToItem: newZoomItem];
	}
	else
	{
		if ( [_zoomStack lastObject] == item )
			[_zoomStack replaceObjectAtIndex: ([_zoomStack count]-1) withObject: refreshedItem];
		
		//notify observers of the change
		[[NSNotificationCenter defaultCenter] postNotificationName: FSItemsChangedNotification object: self];
	}

	//set selection
	if ( selectedItemPath != nil )
	{
		//find previously select item or one of it's ancestors (whichever still exists)
		FSItem *zoomedItem = [self zoomedItem];
		
		FSItem *newSelection = [zoomedItem findItemByAbsolutePath: selectedItemPath allowAncestors: YES];
				
		if ( newSelection != nil && newSelection != zoomedItem )
			[self setSelectedItem: newSelection];
	}
}

- (FSItem*) zoomedItem
{
    return [_zoomStack count] == 0 ? [self rootItem] : [_zoomStack lastObject];
}

- (void) zoomIntoItem: (FSItem*) item
{
    if ( [_zoomStack count] > 0 && item == [_zoomStack lastObject] )
        return;
	
	FSItem *oldZoomedItem = [self zoomedItem];
    
    //reset selection as the currently selected item might not be a child of the item to zoom in
    [self setSelectedItem: nil];

    [_zoomStack addObject: item];
    
    //the file kind statistic should only cover the currently visible part of the file system tree
    //(this depends on the zoomed item and whether package contents is shown or not)
    [self refreshFileKindStatistics];

    [self postNotificationName: ZoomedItemChangedNotification oldItem: oldZoomedItem newItem: [self zoomedItem]];
}

- (void) zoomOutOneStep
{
    if ( [_zoomStack count] > 0 )
    {
		FSItem *oldZoomedItem = [[[self zoomedItem] retain] autorelease];
		
        [_zoomStack removeLastObject];
        
        //the file kind statistic should only cover the currently visible part of the file system tree
        //(this depends on the zoomed item and whether package contents is shown or not)
        [self refreshFileKindStatistics];
		
		//there is no "other" space if a complete volume is shown 
		if ( [[self viewOptions] showOtherSpace] && [[[self zoomedItem] fileDesc] isVolume] )
			[[self viewOptions] setShowOtherSpace: NO]; //don't use our set-method as we don't want any notifications posted

		[self postNotificationName: ZoomedItemChangedNotification oldItem: oldZoomedItem newItem: [self zoomedItem]];
    }
}

- (void) zoomOutToItem: (FSItem*) item
{
    NSAssert( [_zoomStack count] > 0, @"can't zoom out if zoom stack is empty" );
    
    NSParameterAssert( item == nil
                       || item == [self rootItem]
                       || [_zoomStack indexOfObjectIdenticalTo: item] != NSNotFound );
    
	FSItem *oldZoomedItem = [[[self zoomedItem] retain] autorelease];
	
    if ( item == nil || item == [self rootItem] )
    {
        [_zoomStack removeAllObjects];
    }
    else if ( [_zoomStack count] == 1 )
    {
        NSAssert( item == [_zoomStack lastObject], @"zoom error");
        [_zoomStack removeAllObjects];
    }
    else
    {
        unsigned itemIndex = [_zoomStack indexOfObjectIdenticalTo: item];
        if ( itemIndex != NSNotFound )
        {
            unsigned itemsToRemove = [_zoomStack count] - itemIndex - 1;
            for ( ; itemsToRemove > 0; itemsToRemove-- )
                [_zoomStack removeLastObject];
        }
        
    }
    
    //the file kind statistic should only cover the currently visible part of the file system tree
    //(this depends on the zoomed item and whether package contents is shown or not)
    [self refreshFileKindStatistics];

	//there is no "other" space if a complete volume is shown 
	if ( [[self viewOptions] showOtherSpace] && [[[self zoomedItem] fileDesc] isVolume] )
		[[self viewOptions] setShowOtherSpace: NO]; //don't use our set-method as we don't want any notifications posted

	[self postNotificationName: ZoomedItemChangedNotification oldItem: oldZoomedItem newItem: [self zoomedItem]];
}

- (NSArray*) zoomStack
{
	return _zoomStack;
}

- (FSItem*) selectedItem
{
    return _selectedItem;
}

- (void) setSelectedItem: (FSItem*) item
{
    if ( _selectedItem == item )
        return;

	FSItem *oldSelectedItem = _selectedItem;
    
	_selectedItem = item;
		
    //post notification
	[self postNotificationName: GlobalSelectionChangedNotification oldItem: oldSelectedItem newItem: _selectedItem];
	
	//keep info panel in sync
	if ( [[InfoPanelController sharedController] panelIsVisible] )
		[[InfoPanelController sharedController] showPanelWithFSItem: _selectedItem];
}

- (NSString *)fileName
{
    //we should override this method so the window controller will display
    //the icon of the currently zoomed item (or of the root item) in the window's title bar
    return [[self zoomedItem] path];
}

- (NSString *)displayName
{
    NSString *displayName = [[self zoomedItem] displayName];
	
	FileSizeFormatter *sizeFormatter = [[[FileSizeFormatter alloc] init] autorelease];

    displayName = [displayName stringByAppendingFormat: @" (%@)", [sizeFormatter stringForObjectValue: [[self zoomedItem] size]]];

    return displayName;
}

- (NSDictionary*) kindStatistics
{
    NSAssert( _fileKindStatistics != nil, @"kind statistics aren't collected yet" );

    return _fileKindStatistics;
}

- (FileKindStatistic*) kindStatisticForItem: (FSItem*) item
{
    return [self kindStatisticForKind: [item kindName]];
}

- (FileKindStatistic*) kindStatisticForKind: (NSString*) kindName
{
    return [[self kindStatistics] objectForKey: kindName];
}

- (FileTypeColors*) fileTypeColors
{
	if ( _kindColors == nil )
	{
		if ( [[NSUserDefaults standardUserDefaults] boolForKey: ShareKindColors] )
			_kindColors = [[FileTypeColors instance] retain];
		else
			_kindColors = [[FileTypeColors alloc] init];
	}

	return _kindColors;
}

- (void) refreshFileKindStatistics
{
	[self willChangeValueForKey: @"kindStatistics"];
	
	//collect sizes and file count of all file kinds 
	[self addItemToFileKindStatistic: nil includingChilds: YES];
	
	//reserve the predefined colors for the kinds with the biggest size sums of the appropriate files
	[self reserveColorsForLargestKinds];
	
	[self didChangeValueForKey: @"kindStatistics"];
}


#pragma mark ----------------------FSItem delegates-----------------------------------

- (BOOL) fsItemEnteringFolder: (FSItem*) item
{
	//if we don't show the progress panel, we don't need to do anything
	if ( _progressController == nil )
		return YES; //YES == continue loading
	
	if ( _directoryStack == nil )
		_directoryStack = [[NSMutableArray alloc] initWithCapacity: 20];
	
	NSParameterAssert( [_directoryStack lastObject] == [item parent] );
	[_directoryStack addObject: item];

	//we display only folders 3 levels deep and we don't go into packages
	if ( [_directoryStack count] <= 3 )
	{
		FSItem* parentItem = [item parent];
		while ( parentItem != nil && ![parentItem isPackage] )
			parentItem = [parentItem parent];
		
		if ( parentItem == nil )
			[_progressController setMessageText: [item displayPath]];
	}

	[_progressController runEventLoop];
	
	return ![_progressController cancelPressed];
}

- (BOOL) fsItemExittingFolder: (FSItem*) item
{
	//if we don't show the progress panel, we don't need to do anything
	if ( _progressController == nil )
		return YES; //YES == continue loading
	
	NSParameterAssert( [_directoryStack lastObject] == item );
	[_directoryStack removeLastObject];
	
	return YES;
}

- (BOOL) fsItemShouldIgnoreCreatorCode: (FSItem*) item
{
	return [self ignoreCreatorCode];
}

- (BOOL) fsItemShouldLookIntoPackages: (FSItem*) item
{
	return [self showPackageContents];
}

- (BOOL) fsItemShouldUsePhysicalFileSize: (FSItem*) item
{
	return [self showPhysicalFileSize];
}

#pragma mark --------KVO-----------------

- (void)observeValueForKeyPath:(NSString*)keyPath
					  ofObject:(id)object
						change:(NSDictionary*)change
					   context:(void*)context
{
	LOG( @"FileSystemDoc.observeValueForKeyPath: keyPath: %@, change dict:%@", keyPath, change );
	
	//this global preference option is cached in an instance variable for performance reasons
	if ( context == ShareKindColors )
	{
		//if "share colors" was enabled previously, reset the shared colors so we get "fresh" colors the next time it is turned on again
		[_kindColors reset];
		[_kindColors release];
		_kindColors = nil;
		
		[self reserveColorsForLargestKinds];
	}
}

@end

//================ implementation FileSystemDoc(Private) ======================================================

@implementation FileSystemDoc(Private)

- (NSMutableDictionary*) viewOptions
{
	return _viewOptions;
}

- (void) postViewOptionChangedNotificationForOption: (NSString*) optionName
{
	NSDictionary *userInfo = [NSDictionary dictionaryWithObject: optionName forKey: ChangedViewOption];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: ViewOptionChangedNotification
														object: self
													  userInfo: userInfo];
}

- (void) postNotificationName: (NSString*) name oldItem: (FSItem*) old newItem: (FSItem*) new
{
	NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys: old, OldItem, new, NewItem, nil];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: name object: self userInfo: info];
}

- (void) recalculateTotalSize
{
	[[self rootItem] recalculateSize: [self showPhysicalFileSize] updateParent: NO];
}

- (void) addItemToFileKindStatistic: (FSItem*) item includingChilds: (BOOL) includingChilds
{
    //if we are called with nil as item, we rebuild the statistic
    if ( item == nil )
    {
        [_fileKindStatistics release];
		_fileKindStatistics = [[NSMutableDictionary alloc] init];
        
        item = [self zoomedItem];
    }
	
    if ( ![self itemIsNode: item] )
    {
        //item is a file (or regarded as such if item is a package and "show package contents" is turned off),
		//so add it's informations to the appropriate statistic object
        FileKindStatistic* kindStatistic = [self kindStatisticForItem: item];
        if ( kindStatistic == nil )
        {
            //we don't have a statistic object for the item's kind yet, so create one
            kindStatistic = [[FileKindStatistic alloc] initWithItem: item];
            [_fileKindStatistics setObject: kindStatistic forKey: [item kindName]];
            [kindStatistic release];
        }
        else
            [kindStatistic addItem: item];
	}
	else if ( includingChilds )
	{
		//if the item is a folder, recurse through it's childs
        unsigned i = [item childCount];
        while ( i-- )
            [self addItemToFileKindStatistic: [item childAtIndex: i] includingChilds: YES];
    }
}

- (void) removeItemFromFileKindStatistic: (FSItem*) item includingChilds: (BOOL) includingChilds
{
	NSParameterAssert( item != nil );
	
    if ( ![self itemIsNode: item] )
    {
        //item is a file (or regarded as such if item is a package and "show package contents" is turned off),
		//so remove it's information from the appropriate statistic object
        FileKindStatistic* kindStatistic = [self kindStatisticForItem: item];
        if ( kindStatistic != nil )
            [kindStatistic removeItem: item];
	}
	else if ( includingChilds )
	{
		//if the item is a folder, recurse through it's childs
        unsigned i = [item childCount];
        while ( i-- )
            [self removeItemFromFileKindStatistic: [item childAtIndex: i] includingChilds: YES];		
    }
}

- (void) recalculateFileKindStatisticSizes
{
	[self willChangeValueForKey: @"kindStatistics"];
	
	NSEnumerator *statisticEnum = [[self kindStatistics] objectEnumerator];
	FileKindStatistic *statistic = nil;
	while ( (statistic = [statisticEnum nextObject]) != nil )
		[statistic recalculateSize];
	
	[self didChangeValueForKey: @"kindStatistics"];
}

- (void) removePackagesFromFileKindStatistic: (FSItem*) item
{
	BOOL bDoKVO = NO;
	if ( item == nil )
	{
		bDoKVO = YES;
		[self willChangeValueForKey: @"kindStatistics"];
		item = [self zoomedItem];
	}
	
	if ( [self itemIsNode: item] )
	{
		//if the item is a folder, recurse through it's childs
		unsigned i = [item childCount];
		while ( i-- )
			[self removePackagesFromFileKindStatistic: [item childAtIndex: i]];
	}
	else
	{
		if ( [item isPackage] )
			[self removeItemFromFileKindStatistic: item includingChilds: YES];
	}
	
	if ( bDoKVO )
	{
		[self removeEmptyKindStatistics];
		[self didChangeValueForKey: @"kindStatistics"];
	}
}

- (void) addPackagesToFileKindStatistic: (FSItem*) item
{
	BOOL bDoKVO = NO;
	if ( item == nil )
	{
		bDoKVO = YES;
		[self willChangeValueForKey: @"kindStatistics"];
		item = [self zoomedItem];
	}
	
	if ( [self itemIsNode: item] )
	{
		//if the item is a folder, recurse through it's childs
		unsigned i = [item childCount];
		while ( i-- )
			[self addPackagesToFileKindStatistic: [item childAtIndex: i]];
	}
	else
	{
		if ( [item isPackage] )
			[self addItemToFileKindStatistic: item includingChilds: YES];
	}
	
	if ( bDoKVO )
		[self didChangeValueForKey: @"kindStatistics"];
}

- (void) removeEmptyKindStatistics
{
	NSEnumerator *keyEnumerator = [[[self kindStatistics] allKeys] objectEnumerator];
	NSString *kindName;
	while ( (kindName = [keyEnumerator nextObject]) != nil )
	{
		FileKindStatistic *stat = [_fileKindStatistics objectForKey: kindName];
		if ( [stat fileCount] == 0 )
			[_fileKindStatistics removeObjectForKey: kindName];
	}
}

- (void) reserveColorsForLargestKinds
{
	//get a mutable copy of the keys
    NSMutableArray *kinds = [[[self kindStatistics] allValues] mutableCopy];

    //order Statistics descendantly by size
    [kinds sortUsingSelector: @selector(compareSizeDescendingly:)];

    NSEnumerator *kindNameEnum = [kinds objectEnumerator];
    FileKindStatistic *kindStat;
    while ( ( kindStat = [kindNameEnum nextObject] ) != nil )
    {
        [[self fileTypeColors] colorForKind: [kindStat kindName]];
    }
	
	[kinds release]; //mutableCopy returns a retained object (not autoreleased)
}

//After an item is moved to the trash, check if the visible part of the file system tree (all childs of the root)
//contains the trash folder.
//If this is the case, we need to add the trashed item to the FSItem representing the trash.
//(the FSRef of the trashed item is unfortunately no longer valid and the Finder might have renamed it,
//so we don't have any chance to get hold of the trashed item wit)
- (void) checkTrash: (FSItem*) trashItem
withPreviousContent: (NSArray*) oldContent
			forItem: (FSItem*) itemTrashed
{
	//get current content of trash 
	NSArray *newContent = [[trashItem fileDesc] directoryContents: NO/*visibleOnly*/ resolveIfAlias: NO];
	
	//let's see which items are new in the trash	
	//remove all items from "newContentIndex" which are also in "oldContent" and the new ones will remain
	NSMutableDictionary *newContentIndex = [[newContent indexBySelector: @selector(name)] mutableCopy];
	[newContentIndex autorelease]; //mutableCopy returns a retained object (not autoreleased)
	
	NSEnumerator *oldContentEnum = [oldContent objectEnumerator];
	NTFileDesc *desc;
	while ( (desc = [oldContentEnum nextObject]) != nil )
		[newContentIndex removeObjectForKey: [desc name]];
	
	//now look which of the new items might be "itemTrashed" (the Finder might have renamed it)
	//first, direct name match
	desc = [newContentIndex objectForKey: [itemTrashed name]];
	//second try: look for an item starting with the name of the trashed one
	if ( desc == nil )
	{
		NSEnumerator *newContentEnum = [newContentIndex objectEnumerator];
		while ( (desc = [newContentEnum nextObject]) != nil && [[desc name] hasPrefix: [itemTrashed name]] );
	}
	
	//if the trashed item isn't found, we simply do nothing (okay, we could do a reload of "trashItem")
	if ( desc != nil )
	{
		//keep the size of "itemTrashed"...
		[desc setSize: [itemTrashed sizeValue]];
		//...but give "itemTrashed" the valid NTFileDesc object
		[itemTrashed setFileDesc: desc];

		[trashItem insertChild: itemTrashed updateParent: YES];
		
		//keep kind statistic in sync
		[self addItemToFileKindStatistic: itemTrashed includingChilds: YES];
	}
		
}	

@end

