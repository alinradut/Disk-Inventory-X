//
//  GenericArrayController.h
//  Disk Inventory X
//
//  Created by Tjark Derlien on 19.03.05.
//  Copyright 2005 Tjark Derlien. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface GenericArrayController : NSArrayController
{
	NSMutableArray *_cachedObjects;
	NSMutableIndexSet *_mySelectionIndexes;
	
	id _model;
	NSString *_collectionKeyPath;
	
	struct
	{
		BOOL suspendUpdates;
		BOOL arrayIsValid;
	} _updateSuspensionInfo;
}

- (BOOL) suspendingArrangedObjectsUpdates;
- (void) suspendArrangedObjectsUpdates;
- (void) resumeArrangedObjectsUpdates;

- (id) collectionModel;
	//model's array (e.g. document.content)

- (void) onSelectionChanging;
- (void) onSelectionChanged;
- (NSIndexSet*) indexesForObjects: (NSArray*) objects;

@end
