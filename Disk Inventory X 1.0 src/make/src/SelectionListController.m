//
//  SelectionListController.m
//  Disk Inventory X
//
//  Created by Tjark Derlien on 31.03.05.
//  Copyright 2005 Tjark Derlien. All rights reserved.
//

#import "SelectionListController.h"
#import "FileSystemDoc.h"
#import "FileKindsPopupController.h"
#import <OmniFoundation/NSString-OFExtensions.h>
#import "Timing.h"

@interface SelectionListController(Privat)

- (NSArray*) filterItems: (NSArray*) items;
- (FSItemIndex*) currentIndexWithItems: (NSArray*) items;

- (void) startProgressAnimation;
- (void) stopProgressAnimation;
- (BOOL) progressAnimationIsRunning;

@end

@implementation SelectionListController

- (void) awakeFromNib
{
	[_kindsPopupController addObserver: self forKeyPath: @"arrangedObjects" options: 0 context: nil];
	
	_indexToSearch = FSItemIndexAll;
	
	//we have to set the template menu propgrammatically so our "validateMenuItem:" method is called
	//(this is a known bug - see http://www.cocoabuilder.com/archive/message/cocoa/2004/4/21/104991)
	[[_searchField cell] setSearchMenuTemplate:[[_searchField cell] searchMenuTemplate]];
}

- (void) dealloc
{
	[_serachString release];
	[_indexes release];
	
	[_kindsPopupController removeObserver: self forKeyPath: @"arrangedObjects"];
	
	[super dealloc];
}

- (FileSystemDoc*) document
{
	return [_windowController document];
}

- (NSArray*) arrangeObjects: (NSArray*) objects
{
	if ( ![NSString isEmptyString: [self searchString]] )
		objects = [self filterItems: objects];

	return [super arrangeObjects: objects];
}

- (void) rearrangeObjects
{
	//if a large number of files are to be shown, this can take some time
	//so animate the progress indicator
	BOOL startStopPogrInd = ![self progressAnimationIsRunning];
	if ( startStopPogrInd )
		[self startProgressAnimation];
	
	[super rearrangeObjects];
	
	if ( startStopPogrInd )
		[self stopProgressAnimation];
}

- (id) collectionModel
{
	FileKindStatistic *kindStatistic = [super collectionModel];
	
	if ( NSIsControllerMarker( kindStatistic ) )
		return kindStatistic;
	
	if ( [kindStatistic isAllFileKindsItem] )
	{
		NSMutableSet *allFSItems = [NSMutableSet set];
		
		NSEnumerator *statEnum = [(NSArray*) [_kindsPopupController arrangedObjects] objectEnumerator];
		FileKindStatistic *stat;
		while ( (stat = [statEnum nextObject]) != nil )
		{
			if ( [stat isKindOfClass: [FileKindStatistic class]] )
				[allFSItems unionSet: [stat items]];
		}
		
		return allFSItems;
	}
	else
	{
		return [kindStatistic items];
	}
}

- (NSString*) searchString
{
	return _serachString;
}

- (void) setSearchString: (NSString*) newSearchString
{
    if (_serachString != newSearchString)
	{
        [_serachString autorelease];
        _serachString = [newSearchString copy];
    }
}

- (IBAction) search: (id) sender
{
    [self setSearchString:[sender stringValue]];
    [self rearrangeObjects];    
}

- (void)observeValueForKeyPath:(NSString*)keyPath
					  ofObject:(id)object
						change:(NSDictionary*)change
					   context:(void*)context
{
	[super observeValueForKeyPath: keyPath ofObject: object change: change context: context];
	
	if ( object == _kindsPopupController )
	{
		if ( [keyPath isEqualToString: @"arrangedObjects"] )
			[_indexes removeAllObjects];
	}
}

- (IBAction) searchInAll: (id) sender
{
	_indexToSearch = FSItemIndexAll;
	if ( ![NSString isEmptyString: [self searchString]] )
		[self rearrangeObjects];
}

- (IBAction) searchInNames: (id) sender
{
	_indexToSearch = FSItemIndexName;
	if ( ![NSString isEmptyString: [self searchString]] )
		[self rearrangeObjects];
}

- (IBAction) searchInKindNames: (id) sender
{
	_indexToSearch = FSItemIndexKind;
	if ( ![NSString isEmptyString: [self searchString]] )
		[self rearrangeObjects];
}

- (IBAction) searchInPaths: (id) sender
{
	_indexToSearch = FSItemIndexPath;
	if ( ![NSString isEmptyString: [self searchString]] )
		[self rearrangeObjects];
}

- (BOOL) validateMenuItem: (id <NSMenuItem>) menuItem
{
    if ( [menuItem action] == @selector(searchInAll:) )
		[menuItem setState: (_indexToSearch == FSItemIndexAll) ? NSOnState : NSOffState];
	else if ( [menuItem action] == @selector(searchInNames:) )
		[menuItem setState: (_indexToSearch == FSItemIndexName) ? NSOnState : NSOffState];
	else if ( [menuItem action] == @selector(searchInKindNames:) )
		[menuItem setState: (_indexToSearch == FSItemIndexKind) ? NSOnState : NSOffState];
	else if ( [menuItem action] == @selector(searchInPaths:) )
		[menuItem setState: (_indexToSearch == FSItemIndexPath) ? NSOnState : NSOffState];
	
	return YES;
}

@end

@implementation SelectionListController(Privat)

- (FSItemIndex*) currentIndexWithItems: (NSArray*) items
{
	FileKindStatistic *kindStatistic = [super collectionModel];
	
	if ( NSIsControllerMarker( kindStatistic ) )
		return nil;
	
	//this method might get called prior to "awakeFromNib", so we need to create the Dictionary here
	if ( _indexes == nil )
		_indexes = [[NSMutableDictionary alloc] init];
	
	NSString *indexKey = [kindStatistic isAllFileKindsItem] ? @"the special index key when all files are shown" : [kindStatistic kindName];
	
	FSItemIndex *index = [_indexes objectForKey: indexKey];
	if ( index == nil )
	{
		//get the FileKindStatistic object for the selected kind or all FileKindStatistics if "all kinds" is selected
		//(in the kinds popup button)
		NSDictionary *kindStatistics = [kindStatistic isAllFileKindsItem] ? [[self document] kindStatistics] :
										[NSDictionary dictionaryWithObject: [[self document] kindStatisticForKind: [kindStatistic kindName]]
																	forKey: [kindStatistic kindName]];
		index = [[[FSItemIndex alloc] initWithKindStatistics: kindStatistics] autorelease];
		[_indexes setObject: index forKey: indexKey];
		
		BOOL startStopPogrInd = ([items count] > 5000) && ![self progressAnimationIsRunning];
		if ( startStopPogrInd )
			[self startProgressAnimation];
		
		uint64_t startTime = getTime();
		[index addItemsFromArray: items];
		LOG (@"index creation:  %.2f seconds", subtractTime( getTime(), startTime ) );
		
		if ( startStopPogrInd )
			[self stopProgressAnimation];
	}
	
	return index;
}

- (NSArray*) filterItems: (NSArray*) items
{	
	FileKindStatistic *kindStatistic = [super collectionModel];
	
	if ( NSIsControllerMarker( kindStatistic ) )
		return items;
	
	//if we are only searching for kind names and we're showing files of one kind,
	//we can take a shortcut here
	if ( _indexToSearch == FSItemIndexKind && ![kindStatistic isAllFileKindsItem] )
	{
		if ( [[kindStatistic kindName] rangeOfString: [self searchString] options: NSCaseInsensitiveSearch].location != NSNotFound )
			return items;
		else
			return [NSArray array];
	}

	//perform filterung using an index
	FSItemIndex *index = [self currentIndexWithItems: items];
	if ( index == nil )
		return items;
	
	uint64_t startTime = getTime();	
	items = [index searchItems: [self searchString] inIndex: _indexToSearch];
	LOG (@"perform search:  %.2f seconds", subtractTime( getTime(), startTime ) );
	
	return 	items;
}

- (void) startProgressAnimation
{
	[_progressIndicator setUsesThreadedAnimation: YES];
	[_progressIndicator setHidden: NO];
	[_progressIndicator startAnimation: self];
}

- (void) stopProgressAnimation
{
	[_progressIndicator stopAnimation: self];
	[_progressIndicator setHidden: YES];
	[_progressIndicator setUsesThreadedAnimation: NO];
}

- (BOOL) progressAnimationIsRunning
{
	return ![_progressIndicator isHidden];
}

@end

