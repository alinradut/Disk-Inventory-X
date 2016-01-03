//
//  FileKindsPopupController.m
//  Disk Inventory X
//
//  Created by Tjark Derlien on 31.03.05.
//  Copyright 2005 Tjark Derlien. All rights reserved.
//

#import "FileKindsPopupController.h"
#import <TreeMapView/TMVCushionRenderer.h>
#import <TreeMapView/NSBitmapImageRep-CreationExtensions.h>


@implementation FileKindStatistic(AllKinds)
- (BOOL) isAllFileKindsItem
{
	return ![self isKindOfClass: [FileKindStatistic class]];
}
@end

@implementation NSDictionary(AllKinds)
- (BOOL) isAllFileKindsItem
{
	return ![self isKindOfClass: [FileKindStatistic class]];
}
@end

@interface FileKindsPopupController(Privat)

- (void) windowWillClose: (NSNotification*) notification;
- (void) setFileKindsImages;

@end

@implementation FileKindsPopupController

- (void) dealloc
{
	[super dealloc];
}

- (void) awakeFromNib
{
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	
    [notificationCenter addObserver: self
						   selector: @selector(windowWillClose:)
							   name: NSWindowWillCloseNotification
							 object: [_windowController window]];
	
	NSUserDefaultsController *sharedDefsController = [NSUserDefaultsController sharedUserDefaultsController];
	[sharedDefsController addObserver: self
						   forKeyPath: [@"values." stringByAppendingString: ShareKindColors]
							  options: 0
							  context: ShareKindColors];
	
	NSSortDescriptor *sortDesc = [[NSSortDescriptor alloc] initWithKey: @"kindName" ascending: YES selector: @selector(compareAsFilesystemName:)];
	[self setSortDescriptors: [NSArray arrayWithObject: sortDesc]];
	[sortDesc release];	
}

- (NSArray *)arrangeObjects:(NSArray *)objects
{
	NSMutableArray *arrangedObjects = [[objects mutableCopy] autorelease];
		
	[arrangedObjects sortUsingDescriptors: [self sortDescriptors]];

	unsigned totalFileCount = 0;
	unsigned i = [arrangedObjects count];
	while ( i-- )
		totalFileCount += [(FileKindStatistic*) [arrangedObjects objectAtIndex: i] fileCount];
			
	NSString *fakedItemTitle = NSLocalizedString( @"(all kinds)", @"" );
	fakedItemTitle = [fakedItemTitle stringByAppendingFormat: @"  (%u)", totalFileCount];

	[arrangedObjects insertObject: [NSDictionary dictionaryWithObject: fakedItemTitle forKey: @"kindName"] atIndex: 0];
	
	return arrangedObjects;
}

- (void) rearrangeObjects
{
	unsigned oldSelectionIndex = [self selectionIndex];
	
	[super rearrangeObjects];
	
	NSArray *kindStatistics = [self arrangedObjects];
	
	if ( NSIsControllerMarker( kindStatistics ) )
		return;
	
	//we always want a valid selection
	if ( oldSelectionIndex == 0 )
		[self setSelectionIndex: 0];
	else if ( [self selectionIndex] == NSNotFound )
		[self setSelectionIndex: ([kindStatistics count] == 0 ? 0 : 1)];
	
	[self setFileKindsImages];
}

- (void) onSelectionChanged
{
	[super onSelectionChanged];
	
	//if the selection is not changed through the popup button our images
	//are gone, so set them again
	[self setFileKindsImages];
}

- (FileSystemDoc*) document
{
	return [_windowController document];
}

#pragma mark --------KVO-----------------

- (void)observeValueForKeyPath:(NSString*)keyPath
					  ofObject:(id)object
						change:(NSDictionary*)change
					   context:(void*)context
{
	[super observeValueForKeyPath: keyPath ofObject: object change: change context: context];
	
	if ( context == ShareKindColors )
	{
		[self setFileKindsImages];
	}
}
@end

@implementation FileKindsPopupController(Privat)

#pragma mark --------window notifications-----------------

- (void) windowWillClose: (NSNotification*) notification
{
	NSUserDefaultsController *sharedDefsController = [NSUserDefaultsController sharedUserDefaultsController];
	[sharedDefsController removeObserver: self forKeyPath: [@"values." stringByAppendingString: ShareKindColors]];
	
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

- (void) setFileKindsImages
{
	//It's really a pity that NSPopUpButton doesn't support to set an image via bindings (or I didn't get it).
	//So we have to do it manually here.
	
	int imageHeight = [[[_kindsPopUpButton cell] font] pointSize];
	int imageWidth = (float)imageHeight * 1.5 ;
	
	TMVCushionRenderer *cushionRenderer = [[TMVCushionRenderer alloc] initWithRect: NSMakeRect(0, 0, imageWidth, imageHeight)];
	[cushionRenderer autorelease];
	
	[cushionRenderer addRidgeByHeightFactor: 0.6];
	
	FileTypeColors *kindColors = [[self document] fileTypeColors];
	NSArray *kindStatistics = [self arrangedObjects];
	NSArray *popupItems = [_kindsPopUpButton itemArray];
	
	unsigned i;
	for ( i = 0; i < [popupItems count]; i++ )
	{
		id<NSMenuItem> menuItem = [popupItems objectAtIndex: i];
		//the menu item's represented object is a NSNumber giving an array index of our arranged objects
		NSNumber *index = [menuItem representedObject];
		FileKindStatistic *stat = [kindStatistics objectAtIndex: [index unsignedIntValue]];
		
		if ( ![stat isAllFileKindsItem] )
		{
			//create a Bitmap with 24 bit color depth and no alpha component							 
			NSBitmapImageRep* bitmap = [[NSBitmapImageRep alloc]
										initRGBBitmapWithWidth: imageWidth height: imageHeight];
			
			//..and draw a cushion in that bitmap
			[cushionRenderer setColor: [kindColors colorForKind: [stat kindName]]];
			[cushionRenderer renderCushionInBitmap: bitmap];
			
			//create an an image with this bitmap
			NSImage *image = [bitmap suitableImageForView: _kindsPopUpButton];
			[bitmap release];
			
			//set image in menu item
			[menuItem setImage: image];
			
			NSString *title = [[stat kindName] stringByAppendingFormat: @"  (%u)", [stat fileCount]];
			[menuItem setTitle: title];
		}
	}
}

@end

