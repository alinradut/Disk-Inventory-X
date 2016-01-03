//
//  FSItem.m
//  Disk Inventory X
//
//  Created by Tjark Derlien on Mon Sep 29 2003.
//  Copyright (c) 2003 Tjark Derlien. All rights reserved.
//

#import "FilesOutlineViewController.h"
#import "FSItem.h"
#import "FSItem-Utilities.h"
#import <CocoaTechFoundation/NSImage-NTExtensions.h>
#import "NSOutlineView-ContextMenuExtension.h"
#import "MainWindowController.h"
#import "Preferences.h"

@interface FilesOutlineViewController(Private)

- (void) onDocumentSelectionChanged;
- (void) reloadPackages: (FSItem*) parent;
- (void) reloadData;
- (void) setOutlineViewFont;
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context;

@end

@implementation FilesOutlineViewController

- (void) awakeFromNib
{
	FileSystemDoc *doc = [self document];
	
	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
	
    [center addObserver: self
			   selector: @selector(zoomedItemChanged:)
				   name: ZoomedItemChangedNotification
				 object: doc];
	
    [center addObserver: self
			   selector: @selector(viewOptionChanged:)
				   name: ViewOptionChangedNotification
				 object: doc];
	
    [center addObserver: self
			   selector: @selector(itemsChanged:)
				   name: FSItemsChangedNotification
				 object: doc];
	
    [center addObserver: self
			   selector: @selector(windowWillClose:)
				   name: NSWindowWillCloseNotification
				 object: [_outlineView window]];
	
	//set ImageAndTextCell as the data cell for the first (outline) column
    [[_outlineView outlineTableColumn] setDataCell: [ImageAndTextCell cell]];
	
	//set FileSizeFormatter for the size column
	FileSizeFormatter *sizeFormatter = [[[FileSizeFormatter alloc] init] autorelease];
	[[[_outlineView tableColumnWithIdentifier: @"size"] dataCell] setFormatter: sizeFormatter];
        
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver: self
															  forKeyPath: [@"values." stringByAppendingString: UseSmallFontInFilesView]
																 options: 0
																 context: UseSmallFontInFilesView];
	
	[doc addObserver: self forKeyPath: DocKeySelectedItem options: 0 context: nil];
	
	//set small font for all for all columns if needed
	[self setOutlineViewFont];
    
    [self reloadData];
}

- (void) dealloc
{
    [super dealloc];
}

- (FileSystemDoc*) document
{
    if ( _document == nil && _outlineView != nil )
        _document = [MainWindowController documentForView: _outlineView];

    return _document;
}

- (FSItem*) rootItem
{
    return [[self document] zoomedItem];
}

#pragma mark --------NSOutlineView datasource-----------------

- (id) outlineView: (NSOutlineView *) outlineView child: (int) index ofItem: (id) item
{
	FSItem *fsItem = (item == nil) ? [self rootItem] : item;

    return [fsItem childAtIndex: index];
}

- (BOOL) outlineView: (NSOutlineView *) outlineView isItemExpandable: (id) item
{
    return [[self document] itemIsNode: item];
}

- (int) outlineView: (NSOutlineView *) outlineView numberOfChildrenOfItem: (id) item
{
	FSItem *fsItem = (item == nil) ? [self rootItem] : item;
	
    return [fsItem childCount];
}

- (id) outlineView: (NSOutlineView *) outlineView
objectValueForTableColumn: (NSTableColumn *) tableColumn
            byItem: (id) item
{
    NSString *columnTag = [tableColumn identifier];
    FSItem *fsItem = item;
	
	return [fsItem valueForKey: columnTag];
}

- (BOOL) outlineView: (NSOutlineView *) outlineView
          writeItems: (NSArray*) items
        toPasteboard: (NSPasteboard*) pboard
{
    return NO;
}

#pragma mark --------NSOutlineView delegate-----------------

- (void) outlineView: (NSOutlineView *) outlineView
     willDisplayCell: (id) cell
      forTableColumn: (NSTableColumn *) tableColumn
                item: (id) item
{
    if ( [[tableColumn identifier] isEqualToString: @"displayName"] )
    {
		//row height for default font is 17 pixels, so subtract 1
        NSImage *icon = [item iconWithSize: ( [outlineView rowHeight] -1 )];
        [cell setImage: icon];
    }
}

- (NSMenu*) outlineView: (NSOutlineView *) outlineView menuForTableColumn: (NSTableColumn*) column item: (id) item
{	
	return _contextMenu;
}

#pragma mark --------NSOutlineView notifications-----------------

- (void) outlineViewSelectionDidChange: (NSNotification*) notification
{
    FSItem *item = [_outlineView selectedItem];

    FileSystemDoc *doc = [self document];

    //if we are notified about the selection change after we've set the selection by ourself
    //(e.g. in 'onDocumentSelectionChanged') we don't want to post any notification
    if ( item != [doc selectedItem] )
        [doc setSelectedItem: item];
}

#pragma mark --------document notifications-----------------

- (void) zoomedItemChanged: (NSNotification*) notification
{
    [self reloadData];
}

- (void) viewOptionChanged: (NSNotification*) notification
{
	NSString *theOption = [[notification userInfo] objectForKey:ChangedViewOption];
	
	if ( [theOption isEqualToString: ShowPackageContents] )
	{
		//save current selection
		id selectedItem = [_outlineView selectedItem];
		[_outlineView deselectAll: self];
		
		[self reloadPackages: nil];
		
		//try to restore selection
		int row = [_outlineView rowForItem: selectedItem];
		if ( row >= 0 )
			[_outlineView selectRow: row byExtendingSelection: NO];
		
		//the view doesn't redraw properly, so invalidate it
		[_outlineView setNeedsDisplay: YES];
	}
	else if ( [theOption isEqualToString: ShowPhysicalFileSize] )
		[self reloadData];
}

- (void) itemsChanged: (NSNotification*) notification
{
    [self reloadData];
}

#pragma mark --------window notifications-----------------

- (void) windowWillClose: (NSNotification*) notification
{
	[[self document] removeObserver: self forKeyPath: DocKeySelectedItem];
	
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver: self forKeyPath: [@"values." stringByAppendingString: UseSmallFontInFilesView]];
	
	[[NSNotificationCenter defaultCenter] removeObserver: self];
}

@end

@implementation FilesOutlineViewController(Private)

- (void)observeValueForKeyPath:(NSString*)keyPath
					  ofObject:(id)object
						change:(NSDictionary*)change
					   context:(void*)context
{
	if ( context == UseSmallFontInFilesView )
	{
		[self setOutlineViewFont];
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
	
	if ( item == (FSItem*) [_outlineView selectedItem] )
		return;
	
    if ( item == nil )
        [_outlineView deselectAll: nil];
    else
    {
        int row = [_outlineView rowForItem: item];
        
        //if the item can't be found in the view, then the user hasn't expanded the parents yet
        if ( row < 0 )
        {
            //get path from the root item to the item to be selected
            NSArray *path = [item fsItemPath];
            
            //expand all nodes in the outlineview till the item
            unsigned i = 0;
            for ( i = 1; i < [path count]; i++ )
            {
                row = [_outlineView rowForItem: item];
                if ( row <= 0 )
                {
                    //the item is not exandable, so stop here
                    //(e.g. item is a pckage, but package contents aren't shown)
                    if ( ![[self document] itemIsNode: [path objectAtIndex: i]] )
                        break;
					
                    [_outlineView expandItem: [path objectAtIndex: i]];
                }
            }
            
            //now the item may be found in the outline view, if the expandation wasn't stopped
            row = [_outlineView rowForItem: [[self document] selectedItem]];
        }
        
        if ( row < 0 )
            [_outlineView deselectAll: nil];
        else
        {
            [_outlineView selectRow: row byExtendingSelection: NO];
            [_outlineView scrollRowToVisible: row];
        }
    }
}

- (void) setOutlineViewFont
{
	float fontSize = 0;
	if ( [[NSUserDefaults standardUserDefaults] boolForKey: UseSmallFontInFilesView] )
		fontSize = [NSFont smallSystemFontSize];
	else
		fontSize = [NSFont systemFontSize];
	
	NSFont *font = [NSFont systemFontOfSize: fontSize];
	
	NSEnumerator *columnEnum = [[_outlineView tableColumns] objectEnumerator];
	NSTableColumn *column;
	while ( (column = [columnEnum nextObject]) != nil )
	{
		NSCell *cell = [column dataCell];
		if ( [cell type] == NSTextCellType )
			[cell setFont: font];
	}
	
	[_outlineView setRowHeight: fontSize +4];
}

- (void) reloadData
{
    [_outlineView reloadData];
	[self onDocumentSelectionChanged];
}

- (void) reloadPackages: (FSItem*) parent
{
	FileSystemDoc *doc = [self document];
	
    if ( parent == nil )
	{
        parent = [self rootItem];
	}

    unsigned i;
    for ( i = 0; i < [parent childCount]; i++ )
    {
        FSItem *child = [parent childAtIndex: i];

        //if the item is shown in the outline view, reload all package items
        if ( [child isFolder] && [_outlineView rowForItem: child] >= 0 )
        {
			//collapse item if it is no longer expandable
			if ( ![doc itemIsNode: child] && [_outlineView isItemExpanded: child] )
				[_outlineView collapseItem: child collapseChildren: TRUE];
			
            if ( [child isPackage] )
                [_outlineView reloadItem: child];

			//recurse through childs
			if ( [[self document] itemIsNode: child] )
				[self reloadPackages: child];
        }
    }
}

@end