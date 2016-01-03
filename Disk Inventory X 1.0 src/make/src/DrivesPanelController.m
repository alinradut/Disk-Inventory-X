//
//  DrivesPanelController.m
//  Disk Inventory X
//
//  Created by Tjark Derlien on 15.11.04.
//  Copyright 2004 Tjark Derlien. All rights reserved.
//

#import "DrivesPanelController.h"
#import <CocoaTechFoundation/NTVolumeMgr.h>
#import "FileSizeFormatter.h"
#import "VolumeNameTransformer.h"
#import "VolumeUsageTransformer.h"

//============ interface DrivesPanelController(Private) ==========================================================

@interface DrivesPanelController(Private)

- (void) rebuildVolumesArray;
- (void) rebuildProgressIndicatorArray;
- (void) onVolumesChanged: (NSNotification*) notification;

@end


@implementation DrivesPanelController

+ (DrivesPanelController*) sharedController
{
	static DrivesPanelController *controller = nil;
	
	if ( controller == nil )
		controller = [[DrivesPanelController alloc] init];
	
	return controller;
}

- (id) init
{
	self = [super init];
	
	//register volume transformers needed in the volume tableview (before Nib is loaded!)
	[NSValueTransformer setValueTransformer:[VolumeNameTransformer transformer] forName: @"volumeNameTransformer"];
	[NSValueTransformer setValueTransformer:[VolumeUsageTransformer transformer] forName: @"volumeUsageTransformer"];
	
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(onVolumesChanged:)
												 name: kNTVolumeMgrVolumeHasMountedNotification
											   object: [NTVolumeMgr sharedInstance]];
	
	[self rebuildVolumesArray];
	
	//load Nib with volume panel
    if ( ![NSBundle loadNibNamed: @"VolumesPanel" owner: self] )
	{
		[self release];
		self = nil;
	}
	else
	{
		//open volume on double clicked (can't be configured in IB?)
		[_volumesTableView setDoubleAction: @selector(openVolume:)];
		
		//set FileSizeFormatter for the columns displaying sizes (capacity, free)
		FileSizeFormatter *sizeFormatter = [[[FileSizeFormatter alloc] init] autorelease];
		[[[_volumesTableView tableColumnWithIdentifier: @"totalSize"] dataCell] setFormatter: sizeFormatter];
		[[[_volumesTableView tableColumnWithIdentifier: @"freeBytes"] dataCell] setFormatter: sizeFormatter];
	}
	
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];

    [_volumes release];
	[_progressIndicators release];
	
    [super dealloc];
}

- (NSArray*) volumes
{
	return _volumes;
}

- (IBAction)openVolume:(id)sender
{
	//get selected rows as an array of NSNumbers
	NSArray *indexArray = [[_volumesTableView selectedRowIndexes] array];
	
	//open volume shown in each of the selected rows
	NSEnumerator *indexEnum = [indexArray objectEnumerator];
	NSNumber *index;
	while ( (index = [indexEnum nextObject] ) != nil )
	{
		NSString *path = [[_volumes objectAtIndex: [index unsignedIntValue]] valueForKeyPath: @"volume.mountPointFileDesc.path"];
		
		//defer it till the next loop cycle (otherwise the "Open Volume" button stays in "pressed" mode during the loading)
		[[NSRunLoop currentRunLoop] performSelector:@selector(openDocumentWithContentsOfFile:)
											 target: [NSDocumentController sharedDocumentController]
										   argument: path
											  order: 1
											  modes: [NSArray arrayWithObject: NSDefaultRunLoopMode]];
	}
}

- (BOOL) panelIsVisible
{
	return [[self panel] isVisible];
}

- (void) showPanel
{
	[[self panel] orderFront: nil];
}

- (NSWindow*) panel
{
	return _volumesPanel;
}


@end

//============ implementation DrivesPanelController(Private) ==========================================================

@implementation DrivesPanelController(Private)

//fill array "_volumes" with mounted volumes and their images
- (void) rebuildVolumesArray
{
	NSArray *vols;
	if ( _volumes == nil )
		//first time, so use the class method (will enumerate volumes instantly)
		vols = [NTVolumeMgr mountedVolumes: YES /*userViewableOnly*/];
	else
		//called due to a kNTVolumeMgrVolumeHasMountedNotification, so get a copy of [NTVolumeMgr sharedInstance]'s cached volume array
		vols = [[NTVolumeMgr sharedInstance] mountedVolumes];
	
	[self willChangeValueForKey: @"volumes"];

	NS_DURING
		[_volumes release];
		_volumes = [[NSMutableArray alloc] initWithCapacity: [vols count]];
		
		NSEnumerator *volEnum = [vols objectEnumerator];
		NTVolume *volume;
		while ( ( volume = [volEnum nextObject] ) != nil )
		{
			//filter out the virtual "Network" volume
			if ( ![[volume driveName] isEqualToString: @"Network"] )
			{
				//put NTVolume object for key "volume" in the entry dictionary
				NSMutableDictionary *entry = [NSMutableDictionary dictionaryWithObject: volume forKey: @"volume"];
				
				//put volume icon for key "image" in the entry dictionary
				NSImage *volImage = [NSImage imageForDesc:[volume mountPointFileDesc] size: 32];
				
				[entry setObject: ( volImage == nil ? (id)[NSNull null] : volImage )
						  forKey: @"image"];
				
				[_volumes addObject: entry];
			}
		}
	NS_HANDLER
	NS_ENDHANDLER
	
	[self rebuildProgressIndicatorArray];
	
	[self didChangeValueForKey: @"volumes"];
}

//keeps array of progress indicators (for graphical usage display) in sync with volumes array
- (void) rebuildProgressIndicatorArray
{
	if ( _progressIndicators == nil )
		_progressIndicators = [[NSMutableArray alloc] initWithCapacity: [_volumes count]];
	
	unsigned i;
	for ( i = 0; i < [_volumes count]; i++ )
	{
		NSProgressIndicator *progrInd = nil;
		if ( i >= [_progressIndicators count] )
		{
			progrInd = [[[NSProgressIndicator alloc] init] autorelease];
			[progrInd setStyle: NSProgressIndicatorBarStyle];
			[progrInd setIndeterminate: NO];
			
			[_progressIndicators addObject: progrInd];
		}
		else
			//reuse existing progress indicator
			progrInd = [_progressIndicators objectAtIndex: i];
		
		NTVolume *vol = [[_volumes objectAtIndex: i] objectForKey : @"volume"];
		
		[progrInd setMinValue: 0];
		[progrInd setMaxValue: [vol totalBytes]];
		[progrInd setDoubleValue: ([vol totalBytes] - [vol freeBytes])];
	}
	
	while ( [_progressIndicators count] > [_volumes count] )
	{
		[[_progressIndicators lastObject] removeFromSuperviewWithoutNeedingDisplay];
		[_progressIndicators removeLastObject];
	}
}

#pragma mark --------NTVolumeMgr notifications-----------------

- (void) onVolumesChanged: (NSNotification*) notification
{
	[self rebuildVolumesArray];
}

#pragma mark --------NSTableView notifications-----------------

- (void) tableViewSelectionDidChange: (NSNotification*) notification
{
}

#pragma mark --------NSTableView delegates-----------------

- (void) tableView:(NSTableView *) tableView willDisplayCell:(id) cell forTableColumn:(NSTableColumn *) tableColumn row:(int) row
{
	if ( [[tableColumn identifier] isEqualToString: @"usagePercent"] )
	{
		NSProgressIndicator *progrInd = [_progressIndicators objectAtIndex: row];
		
		//add progress indicator as subview of table view
		if ( [progrInd superview] != tableView )
			[tableView addSubview: progrInd];
		
		int colIndex = [tableView columnWithIdentifier: [tableColumn identifier]];
		NSRect cellRect = [tableView frameOfCellAtColumn: colIndex row: row];
		
		const float progrIndThickness = NSProgressIndicatorPreferredLargeThickness; 
		const float extraSpace = 16; //space before and after progress indicator (relative to left and right side of cell)
		
		//center it vertically in cell
		NSAssert( NSHeight(cellRect) > progrIndThickness, @"rows need to be higher than progress indicator thickness" );
		cellRect.origin.y += (NSHeight(cellRect) - progrIndThickness) / 2;
		cellRect.size.height = progrIndThickness;

		//add space before and after
		cellRect.origin.x += extraSpace;
		cellRect.size.width -= 2*extraSpace;
		
		[progrInd setFrame: cellRect];
		[progrInd stopAnimation: nil];
	}
}



@end
