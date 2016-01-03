//
//  SelectionListTableController.m
//  Disk Inventory X
//
//  Created by Tjark Derlien on 25.03.05.
//  Copyright 2005 Tjark Derlien. All rights reserved.
//

#import "SelectionListTableController.h"
#import "ImageAndTextCell.h"

@interface SelectionListTableController(Privat)

- (void) setTableViewFont;
- (void) onDocumentSelectionChanged;
- (void) onSelectionListSelectionChanged;
- (void) onDrawerOpened: (NSNotification*) notification;
- (void) onDrawerClosed: (NSNotification*) notification;

@end

@implementation SelectionListTableController

- (FileSystemDoc*) document
{
	return [_windowController document];
}

- (void) awakeFromNib
{
	FileSystemDoc *doc = [self document];

	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	NSDrawer *drawer = [_windowController selectionListDrawer];
	
	[notificationCenter addObserver: self
						   selector: @selector(onDrawerClosed:)
							   name: NSDrawerDidCloseNotification
							 object: drawer];
	[notificationCenter addObserver: self
						   selector: @selector(onDrawerOpened:)
							   name: NSDrawerWillOpenNotification
							 object: drawer];
	
    [notificationCenter addObserver: self
						   selector: @selector(windowWillClose:)
							   name: NSWindowWillCloseNotification
							 object: [_windowController window]];
	
	if ( [drawer state] == NSDrawerClosedState )
		[_selectionListArrayController suspendArrangedObjectsUpdates];
	
	//set up KVO
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver: self
															  forKeyPath: [@"values." stringByAppendingString: UseSmallFontInSelectionList]
																 options: 0
																 context: UseSmallFontInSelectionList];

	[doc addObserver: self forKeyPath: DocKeySelectedItem options: 0 context: nil];
	[_selectionListArrayController addObserver: self forKeyPath: @"selection" options: 0 context: nil];

	//set ImageAndTextCell as the data cell for the "Name" column
    [[_tableView tableColumnWithIdentifier: @"displayName"] setDataCell: [ImageAndTextCell cell]];

	//set initial sorting (descendant size)
	NSTableColumn *sizeColumn = [_tableView tableColumnWithIdentifier: @"size"];
	NSArray *initialSortDescriptors = [NSArray arrayWithObject: [[sizeColumn sortDescriptorPrototype] reversedSortDescriptor]];
	[_selectionListArrayController setSortDescriptors: initialSortDescriptors];

	//set small font for all for all columns if needed
	[self setTableViewFont];
}

#pragma mark --------NSTableView delegate-----------------

- (void) tableView: (NSTableView *) tableView
   willDisplayCell: (id) cell
	forTableColumn: (NSTableColumn *) tableColumn
			   row: (int) row
{
    if ( [[tableColumn identifier] isEqualToString: @"displayName"] )
    {
		NSArray *items = [_selectionListArrayController arrangedObjects];
		FSItem* item = [items objectAtIndex: row]; 
			
		//row height for default font is 17 pixels, so subtract 1
        NSImage *icon = [item iconWithSize: ( [tableView rowHeight] -1 )];
        [cell setImage: icon];
    }
}

- (NSMenu*) tableView: (NSTableView *) tableView menuForTableColumn: (NSTableColumn*) column row: (int) row
{
	return [tableView menu];
}

#pragma mark --------window notifications-----------------

- (void) windowWillClose: (NSNotification*) notification
{
	[[self document] removeObserver: self forKeyPath: DocKeySelectedItem];
	
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver: self forKeyPath: [@"values." stringByAppendingString: UseSmallFontInSelectionList]];
	
	[_selectionListArrayController removeObserver: self forKeyPath: @"selection"];

	[[NSNotificationCenter defaultCenter] removeObserver: self];

}

#pragma mark --------KVO-----------------

- (void)observeValueForKeyPath:(NSString*)keyPath
					  ofObject:(id)object
						change:(NSDictionary*)change
					   context:(void*)context
{
	if ( context == UseSmallFontInSelectionList )
	{
		[self setTableViewFont];
	}
	else if ( object == [self document] )
	{
		if ( [keyPath isEqualToString: DocKeySelectedItem] )
			[self onDocumentSelectionChanged];
	}
	else if ( object == _selectionListArrayController )
	{
		if ( [keyPath isEqualToString: @"selection"] )
			[self onSelectionListSelectionChanged];
	}
}

#pragma mark --------drawer notifications-----------------

@end

@implementation SelectionListTableController(Privat)

- (void) setTableViewFont
{
	float fontSize = 0;
	if ( [[NSUserDefaults standardUserDefaults] boolForKey: UseSmallFontInSelectionList] )
		fontSize = [NSFont smallSystemFontSize];
	else
		fontSize = [NSFont systemFontSize];
	
	NSFont *font = [NSFont systemFontOfSize: fontSize];
	
	NSEnumerator *columnEnum = [[_tableView tableColumns] objectEnumerator];
	NSTableColumn *column;
	while ( (column = [columnEnum nextObject]) != nil )
	{
		NSCell *cell = [column dataCell];
		if ( [cell type] == NSTextCellType )
			[cell setFont: font];
	}
	
	[_tableView setRowHeight: fontSize +4];
}

- (void) onDocumentSelectionChanged
{
    FSItem *item = [[self document] selectedItem];

	id selectionListSelection = [_selectionListArrayController selection];
	if ( selectionListSelection == NSNoSelectionMarker )
		selectionListSelection = nil;
	
	//NSNotApplicableMarker or NSMultipleValuesMarker?
	NSAssert( !NSIsControllerMarker( selectionListSelection ), @"unsupported controller marker detected" );
	
	if ( item != selectionListSelection )
	{
		//we have to unregister ourself from the selection list array constroller as we don't want to be notified
		//about this selection change
		//(the selection may be removed which will be propagated back to the document - see "onSelectionListSelectionChanged") 
		[_selectionListArrayController removeObserver: self forKeyPath: @"selection"];
		
		//optimization: if item is a folder or the selection list doesn't show the files of items's kind,
		//remove selection (as it is not in the list)
		if ( item != nil )
		{
			FileKindStatistic *selectedStat = [_kindStatisticsArrayController selection];
			NSAssert( !NSIsControllerMarker( selectedStat ), @"kind statistics popup button should always have a valid selection" );
			if ( ![selectedStat isAllFileKindsItem] && ![[selectedStat kindName] isEqualToString: [item kindName]]
				 || [[self document] itemIsNode: item] )
				item = nil;
		}
		
		if ( item == nil )
			[_selectionListArrayController setSelectionIndexes: [NSIndexSet indexSet]];
		else
			[_selectionListArrayController setSelectedObjects: [NSArray arrayWithObject: item]];
		
		[_selectionListArrayController addObserver: self forKeyPath: @"selection" options: 0 context: nil];
	}
}

- (void) onSelectionListSelectionChanged
{
	FileSystemDoc *doc = [self document];
	
	id selectionListSelection = [_selectionListArrayController selection];
	if ( selectionListSelection == NSNoSelectionMarker )
		selectionListSelection = nil;
	
	//NSNotApplicableMarker or NSMultipleValuesMarker?
	NSAssert( !NSIsControllerMarker( selectionListSelection ), @"unsupported controller marker detected" );
	
	if ( selectionListSelection != [doc selectedItem] )
		[doc setSelectedItem: selectionListSelection];
}

- (void) onDrawerOpened: (NSNotification*) notification
{
	[_selectionListArrayController resumeArrangedObjectsUpdates];
}

- (void) onDrawerClosed: (NSNotification*) notification
{
	[_selectionListArrayController suspendArrangedObjectsUpdates];
}

@end
