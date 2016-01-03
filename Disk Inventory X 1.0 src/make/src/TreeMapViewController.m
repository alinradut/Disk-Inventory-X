//
//  FSItem.m
//  Disk Inventory X
//
//  Created by Tjark Derlien on Mon Sep 29 2003.
//  Copyright (c) 2003 Tjark Derlien. All rights reserved.
//

#import "TreeMapViewController.h"
#import <TreeMapView/TreeMapView.h>
#import "MainWindowController.h"
#import "FileSizeFormatter.h"
#import "FSItem-Utilities.h"

@interface TreeMapViewController(Private)

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context;
- (void) onDocumentSelectionChanged;
- (void) reloadData;

@end

@implementation TreeMapViewController

- (void) awakeFromNib
{
	FileSystemDoc *doc = [self document];
	
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	
    [notificationCenter addObserver: self
						   selector: @selector(zoomedItemChanged:)
							   name: ZoomedItemChangedNotification
							 object: doc];
	
    [notificationCenter addObserver: self
						   selector: @selector(viewOptionChanged:)
							   name: ViewOptionChangedNotification
							 object: doc];
	
    [notificationCenter addObserver: self
						   selector: @selector(itemsChanged:)
							   name: FSItemsChangedNotification
							 object: doc];
	
    [notificationCenter addObserver: self
						   selector: @selector(windowWillClose:)
							   name: NSWindowWillCloseNotification
							 object: [_treeMapView window]];
	
    [_fileNameTextField setStringValue: @""];
    [_fileSizeTextField setStringValue: @""];
	
	//set up KVO
	[doc addObserver: self forKeyPath: DocKeySelectedItem options: NSKeyValueObservingOptionNew context: nil];
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver: self
															  forKeyPath: [@"values." stringByAppendingString: ShareKindColors]
																 options: 0
																 context: ShareKindColors];
	
	//create "free space" and "other space" items
	//(don't use [self rootItem] as we want the root, not the zoomed item)
	FSItem *rootItem =  [[self document] rootItem];
	
	_otherSpaceItem = [[FSItem alloc] initAsOtherSpaceItemForParent: rootItem];
	_freeSpaceItem = [[FSItem alloc] initAsFreeSpaceItemForParent: rootItem];
	
	[self reloadData];
}

- (void) dealloc
{
	[_otherSpaceItem release];
	[_freeSpaceItem release];
    
    [super dealloc];
}

- (FileSystemDoc*) document
{
    if ( _document == nil && _treeMapView != nil )
        _document = [MainWindowController documentForView: _treeMapView];

    return _document;
}

- (FSItem*) rootItem
{
    return [[self document] zoomedItem];
}

#pragma mark --------TreeMapView data source-----------------

- (id) treeMapView: (TreeMapView*) view child: (unsigned) index ofItem: (id) item
{
    FSItem *fsItem = ( item == nil ? [self rootItem] : item );
	
	if ( fsItem == [self rootItem]
		 && index >= [fsItem childCount] )
	{
		if ( ( index - [fsItem childCount] ) == 0 )
			return [[self document] showOtherSpace] ? _otherSpaceItem : _freeSpaceItem;
		else
			return _freeSpaceItem;
	}
	else
		return [fsItem childAtIndex: index];
}

- (BOOL) treeMapView: (TreeMapView*) view isNode: (id) item
{
    FSItem *fsItem = ( item == nil ? [self rootItem] : item );

    return ![fsItem isSpecialItem] && [[self document] itemIsNode: fsItem];
}

- (unsigned) treeMapView: (TreeMapView*) view numberOfChildrenOfItem: (id) item
{
    FSItem *fsItem = ( item == nil ? [self rootItem] : item );

    unsigned childCount = [fsItem childCount];
	
	//items representing other space and free space
	if ( fsItem == [self rootItem] )
	{
		FileSystemDoc *doc = [self document];
		if ( [doc showFreeSpace] )
			childCount ++;
		if ( [doc showOtherSpace] )
			childCount ++;
	}
	
	return childCount;
}

- (unsigned long long) treeMapView: (TreeMapView*) view weightByItem: (id) item
{
    FSItem *fsItem = ( item == nil ? [self rootItem] : item );

	unsigned long long size = [fsItem sizeValue];
	
	//add sizes of items representing other space and free space
	if ( fsItem == [self rootItem] )
	{
		FileSystemDoc *doc = [self document];
		if ( [doc showFreeSpace] )
			size += [_freeSpaceItem sizeValue];
		if ( [doc showOtherSpace] )
			size += [_otherSpaceItem sizeValue];
	}
	
    return size;
}

#pragma mark --------TreeMapView delegates-----------------

- (NSString*) treeMapView: (TreeMapView*) view getToolTipByItem: (id) item
{
    FSItem *fsItem = ( item == nil ? [self rootItem] : item );

    return [fsItem displayName];
}

- (void) treeMapView: (TreeMapView*) view willDisplayItem: (id) item withRenderer: (TMVItem*) renderer
{
    FSItem *fsItem = ( item == nil ? [self rootItem] : item );
	
	NSColor *color = nil;
	
	switch ( [fsItem type] )
	{
		case FileFolderItem:
			color = [[[self document] fileTypeColors] colorForItem: fsItem];
			break;
		case FreeSpaceItem:
			color = [NSColor colorWithCalibratedWhite: 1 alpha: 1];
			//color = [NSColor colorWithCalibratedRed: 0 green: 0 blue: 0 alpha: 1];
			color = [TMVCushionRenderer normalizeColor: color];
			break;
		case OtherSpaceItem:
			color = [NSColor colorWithCalibratedRed: 0.2 green: 0.2 blue: 0.2 alpha: 1];
			color = [TMVCushionRenderer normalizeColor: color];
			break;
	}
	
	[renderer setCushionColor: color];
}

- (void) treeMapView: (TreeMapView*) view willShowMenuForEvent: (NSEvent*) event
{
    if ( [event type] == NSRightMouseDown )
    {
        //right mouse click -> context menu
        //select the item hit by the click,
        //so the user gets feedback for which item the menu is shown 
        NSPoint point = [event locationInWindow];

        TMVCellId cell = [_treeMapView cellIdByPoint: point inViewCoords: NO];
        NSAssert1( cell != nil, @"No item at %@", NSStringFromPoint(point) );
		
		FSItem *fsItem = [_treeMapView itemByCellId: cell];

		if ( ![fsItem isSpecialItem] )
		{
			FileSystemDoc *document = [self document];
			[document setSelectedItem: fsItem];
		}
		
		[self onDocumentSelectionChanged];
    }
}

#pragma mark --------TreeMapView notifications-----------------

- (void)treeMapViewItemTouched: (NSNotification*) notification
{
    FSItem *fsItem = [[notification userInfo] objectForKey: TMVTouchedItem];

    if ( fsItem == nil )
    {
        [_fileNameTextField setStringValue: @""];
        [_fileSizeTextField setStringValue: @""];
    }
    else
    {
        NSString *displayName = [fsItem displayName];
		FileSizeFormatter *sizeFormatter = [[[FileSizeFormatter alloc] init] autorelease];
		NSString *size = [sizeFormatter stringForObjectValue: [fsItem size]];
		
		if ( ![fsItem isSpecialItem] )
		{
			displayName = [displayName stringByAppendingFormat: @" (%@)", [fsItem displayFolderName]];        			
			
			[_fileSizeTextField setStringValue: [NSString stringWithFormat: @"%@, %@", [fsItem kindName], size]];
		}
		else
		{
			[_fileSizeTextField setStringValue: @""];
			[_fileSizeTextField setStringValue: size];
		}
			
        [_fileNameTextField setStringValue: displayName];
    }
}

- (void) treeMapViewSelectionDidChange: (NSNotification*) notification
{
    FSItem *item = [_treeMapView selectedItem];

    FileSystemDoc *doc = [self document];

    //if we are notified about the selection change after we've set the selection by ourself
    //(e.g. in 'onDocumentSelectionChanged') we don't want to post any notification
    if ( [doc selectedItem] != item
		 && ![item isSpecialItem] )
    {
        [doc setSelectedItem: item];
    }
}

#pragma mark --------document notifications-----------------

- (void) itemsChanged: (NSNotification*) notification
{
	//create new "free space" and "other space" items
	//(don't use [self rootItem] as we want the root, not the zoomed item)
	FSItem *rootItem =  [[self document] rootItem];
	
	[_otherSpaceItem release];
	_otherSpaceItem = [[FSItem alloc] initAsOtherSpaceItemForParent: rootItem];
	[_freeSpaceItem release];
	_freeSpaceItem = [[FSItem alloc] initAsFreeSpaceItemForParent: rootItem];
	
    [self reloadData];
}

- (void) zoomedItemChanged: (NSNotification*) notification
{
	//just do a reload if animated zooming is turned off
	if ( ![[NSUserDefaults standardUserDefaults] boolForKey: AnimatedZooming] )
	{
		[self reloadData];
	}
	else
	{
		FSItem *oldZoomedItem = [[notification userInfo] objectForKey: OldItem];
		FSItem *newZoomedItem = [[notification userInfo] objectForKey: NewItem];
		NSAssert( newZoomedItem == [self rootItem], @"invalid new zoomed item" );
		
		//did we zoom in or out?
		BOOL didZoomIn = [newZoomedItem isDescendantOf: oldZoomedItem];
		
		if ( didZoomIn )
		{
			NSArray *itemPath = [newZoomedItem fsItemPathFromAncestor: oldZoomedItem];
			[_treeMapView reloadAndPerformZoomIntoItem: itemPath];
		}
		else
		{
			NSArray *itemPath = [oldZoomedItem fsItemPathFromAncestor: newZoomedItem];
			[_treeMapView reloadAndPerformZoomOutofItem: itemPath];
		}
	}
}

- (void) viewOptionChanged: (NSNotification*) notification
{
	NSString *theOption = [[notification userInfo] objectForKey:ChangedViewOption];
	
	if ( [theOption isEqualToString: ShowPackageContents]
		 || [theOption isEqualToString: ShowPhysicalFileSize]
		 || [theOption isEqualToString: IgnoreCreatorCode]
		 || [theOption isEqualToString: ShowOtherSpace]
		 || [theOption isEqualToString: ShowFreeSpace] )
	{
		[self reloadData];
		
		//restore selection
		[self onDocumentSelectionChanged];
	}
}

#pragma mark --------window notifications-----------------

- (void) windowWillClose: (NSNotification*) notification
{
	[[self document] removeObserver: self forKeyPath: DocKeySelectedItem];
	
    [[NSNotificationCenter defaultCenter] removeObserver: self];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver: self forKeyPath: [@"values." stringByAppendingString: ShareKindColors]];
}

@end

@implementation TreeMapViewController(Private)

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
	if ( context == ShareKindColors )
	{
		[_treeMapView invalidateCanvasCache];
		[_treeMapView setNeedsDisplay: YES];
	}
	else if ( object == [self document] )
	{
		if ( [keyPath isEqualToString: DocKeySelectedItem] )
			[self onDocumentSelectionChanged];
	}
}

- (void) onDocumentSelectionChanged
{
	FSItem *item = [[self document] selectedItem];
	
	if ( item == (FSItem*) [_treeMapView selectedItem] )
		return;

	if ( item == nil )
		[_treeMapView selectItemByCellId: nil];
	else
		[_treeMapView selectItemByPathToItem: [item fsItemPathFromAncestor: [self rootItem]]];
}

- (void) reloadData;
{
	[_treeMapView reloadData];
	[self onDocumentSelectionChanged];
}

@end
