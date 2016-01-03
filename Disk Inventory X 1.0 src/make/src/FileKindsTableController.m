//
//  FSItem.m
//  Disk Inventory X
//
//  Created by Tjark Derlien on Mon Sep 29 2003.
//  Copyright (c) 2003 Tjark Derlien. All rights reserved.
//

#import "FileKindsTableController.h"
#import <TreeMapView/TMVCushionRenderer.h>
#import <TreeMapView/NSBitmapImageRep-CreationExtensions.h>
#import "Preferences.h"
#import "MainWindowController.h"

#import "FSItemIndex.h"


//============ interface FileKindsTableController(Private) ==========================================================

@interface FileKindsTableController(Private)

- (NSImage*) colorImageForRow: (int) row column: (NSTableColumn*) column;
- (void) setTableViewFont;

@end

//============ implementation FileKindsTableController ==========================================================

@implementation FileKindsTableController

- (void) awakeFromNib
{
	FileSystemDoc *doc = [self document];
	
	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
	
    [center addObserver: self
			   selector: @selector(documentSelectionChanged:)
				   name: GlobalSelectionChangedNotification
				 object: doc];
	
    [center addObserver: self
			   selector: @selector(windowWillClose:)
				   name: NSWindowWillCloseNotification
				 object: [_windowController window]];
	
	//set up KVO
	NSUserDefaultsController *sharedDefsController = [NSUserDefaultsController sharedUserDefaultsController];
	[sharedDefsController addObserver: self
						   forKeyPath: [@"values." stringByAppendingString: UseSmallFontInKindStatistic]
							  options: 0
							  context: UseSmallFontInKindStatistic];
	[sharedDefsController addObserver: self
						   forKeyPath: [@"values." stringByAppendingString: ShareKindColors]
							  options: 0
							  context: ShareKindColors];
	
	[_kindsTableArrayController addObserver: self forKeyPath: @"arrangedObjects" options: 0 context: nil];
	
	//set small font for all for all columns if needed
	[self setTableViewFont];
    
	//set initial sorting (descendant size)
	NSTableColumn *sizeColumn = [_tableView tableColumnWithIdentifier: @"size"];
	NSArray *initialSortDescriptors = [NSArray arrayWithObject: [[sizeColumn sortDescriptorPrototype] reversedSortDescriptor]];
	[_kindsTableArrayController setSortDescriptors: initialSortDescriptors];
}

- (void) dealloc
{    
    [_cushionImages release];

    [super dealloc];
}

- (FileSystemDoc*) document
{
	return [_windowController document];
}

- (IBAction) showFilesInSelectionList: (id) sender
{
	int selectionListDrawerState = [[_windowController selectionListDrawer] state];
	
	if ( selectionListDrawerState == NSDrawerClosingState || selectionListDrawerState == NSDrawerClosedState )
		[[_windowController selectionListDrawer] toggle: self];
	
	int selectedRow = [_tableView selectedRow];
	NSAssert( selectedRow >= 0, @"kinds tableview should have a selection" );
	
	FileKindStatistic *kindStat = [(NSArray*)[_kindsTableArrayController arrangedObjects] objectAtIndex: selectedRow];
	[_kindsPopupArrayController setSelectedObjects: [NSArray arrayWithObject: kindStat]];
}

#pragma mark --------NSTableView delegate methods-----------------

//NSTableView delegate
- (void) tableView: (NSTableView*) tableView willDisplayCell: (id) cell forTableColumn: (NSTableColumn*) tableColumn row: (int) row
{
	if ( [[tableColumn identifier] isEqualToString: @"color"] )
		[cell setImage: [self colorImageForRow: row column: tableColumn]];
}

#pragma mark --------NSTableView notifications-----------------

- (void) tableViewSelectionDidChange: (NSNotification *) aNotification
{
    //int row = [_tableView selectedRow];
}

#pragma mark --------KVO-----------------

- (void)observeValueForKeyPath:(NSString*)keyPath
					  ofObject:(id)object
						change:(NSDictionary*)change
					   context:(void*)context
{
	LOG( @"FileKindsTableColumn.observeValueForKeyPath: keyPath: %@, change dict:%@", keyPath, change );
	
	if ( context == UseSmallFontInKindStatistic )
		[self setTableViewFont];
	else if ( context == ShareKindColors )
	{
		[_cushionImages release];
		_cushionImages = nil;
		
		[_tableView setNeedsDisplay: YES];
	}
	else if ( object == _kindsTableArrayController )
	{
		if ( [keyPath isEqualToString: @"arrangedObjects"] )
			[_cushionImages removeAllObjects];
	}
}

@end

//============ implementation FileKindsTableController(Private) ===============================================

@implementation FileKindsTableController(Private)

//returns a cushion image for a given row in the tableview
- (NSImage*) colorImageForRow: (int) row column: (NSTableColumn*) column
{
	if ( _cushionImages == nil )
		_cushionImages = [[NSMutableDictionary alloc] init];
		
	FileKindStatistic *kindStatistic = [(NSArray*)[_kindsTableArrayController arrangedObjects] objectAtIndex: row];
	
	NSImage *image = [_cushionImages objectForKey: [kindStatistic kindName]];
	
	NSSize cellSize = NSMakeSize( [column width], [_tableView rowHeight] );
	
	//if we don't have any image for that row yet or the cell size has changed, create a new image
	if ( image == nil || !NSEqualSizes( [image size], cellSize ) )
	{
		//create a Bitmap with 24 bit color depth and no alpha component							 
		NSBitmapImageRep* bitmap = [[ NSBitmapImageRep alloc]
										initRGBBitmapWithWidth: cellSize.width height: cellSize.height];
		
		//..and draw a cushion in that bitmap
		TMVCushionRenderer *cushionRenderer = [[TMVCushionRenderer alloc] initWithRect: NSMakeRect(0, 0, cellSize.width, cellSize.height)];
		
		FileTypeColors *kindColors = [[self document] fileTypeColors];
		[cushionRenderer setColor: [kindColors colorForKind: [kindStatistic kindName]]];
		
		[cushionRenderer addRidgeByHeightFactor: 0.5];
		[cushionRenderer renderCushionInBitmap: bitmap];
		
		[cushionRenderer release];
		
		//put an image with the cushion in the _cushionImages array for the next time this row is about to be drawn
		image = [bitmap suitableImageForView: _tableView];
		[bitmap release];
		
		[_cushionImages setObject: image forKey: [kindStatistic kindName]];
	}

	return image;
}

- (void) setTableViewFont
{
	float fontSize = 0;
	if ( [[NSUserDefaults standardUserDefaults] boolForKey: UseSmallFontInKindStatistic] )
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

#pragma mark --------document notifications-----------------

- (void) documentSelectionChanged: (NSNotification*) notification
{
	FileSystemDoc *doc = [self document];
	
    FSItem *item = [doc selectedItem];
	//optimization: if item is a folder, remove selection (as it is not in the list anyway)
	FileKindStatistic *stat = [doc itemIsNode: item] ? nil : [doc kindStatisticForItem: item];
	
	id tableViewSelection = [_kindsTableArrayController selection];
	if ( tableViewSelection == NSNoSelectionMarker )
		tableViewSelection = nil;
	
	if ( stat != tableViewSelection )
	{
		if ( stat == nil )
			[_kindsTableArrayController setSelectionIndexes: [NSIndexSet indexSet]];
		else
			[_kindsTableArrayController setSelectedObjects: [NSArray arrayWithObject: stat]];
	}
}

#pragma mark --------window notifications-----------------

- (void) windowWillClose: (NSNotification*) notification
{
	NSUserDefaultsController *sharedDefsController = [NSUserDefaultsController sharedUserDefaultsController];
	[sharedDefsController removeObserver: self forKeyPath: [@"values." stringByAppendingString: UseSmallFontInKindStatistic]];
	[sharedDefsController removeObserver: self forKeyPath: [@"values." stringByAppendingString: ShareKindColors]];

	[_kindsTableArrayController removeObserver: self forKeyPath: @"arrangedObjects"];
	
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

@end
