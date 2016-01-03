//
//  GenericArrayController.m
//  Disk Inventory X
//
//  Created by Tjark Derlien on 19.03.05.
//  Copyright 2005 Tjark Derlien. All rights reserved.
//

#import "GenericArrayController.h"

NSString *contentArrayBindingContext = @"contentArrayBindingContext";

@interface GenericArrayController(Privat)

@end

@implementation GenericArrayController

- (id ) init
{
	self = [super init];
	
	if ( self != nil )
	{
		_updateSuspensionInfo.suspendUpdates = NO;
		_updateSuspensionInfo.arrayIsValid = YES;
		
		_mySelectionIndexes = [[NSMutableIndexSet alloc] init];
	}
	
	return self;
}

- (void) dealloc
{
	[_cachedObjects release];
	[_mySelectionIndexes release];
	[_collectionKeyPath release];
	
	[super dealloc];
}

#pragma mark --------binding support-----------------

- (void) bind: (NSString*) binding
	 toObject: (id) observableController
  withKeyPath: (NSString*) keyPath
	  options: (NSDictionary*) options
{
	if ( [binding isEqualToString: @"contentArray"] )
	{
		LOG( @"binding '%@': object: %x (%@), key path: %@, options: %@", binding, observableController, [observableController class], keyPath, options );
		
		_model = observableController;
		_collectionKeyPath = [keyPath copy];
		
		[_model addObserver: self forKeyPath: _collectionKeyPath options: NSKeyValueObservingOptionNew context: contentArrayBindingContext];
	}
	else
	{
		LOG( @"unknown binding '%@' requested: object: %x (%@), key path: %@, options: %@", binding, observableController, [observableController class], keyPath, options );

		[super bind: binding toObject: observableController withKeyPath: keyPath options: options];
	}
}

- (void)unbind: (NSString*) bindingName
{
    if ([bindingName isEqualToString:@"contentArray"])
    {
		LOG( @"un-binding '%@'", bindingName );
		
		[_model removeObserver:self forKeyPath: _collectionKeyPath];
		_model = nil;
		
		[_collectionKeyPath release];
		_collectionKeyPath = nil;
		
		[_mySelectionIndexes release];
		_mySelectionIndexes = nil;
		
		[self rearrangeObjects];
    }
	else
	{
		LOG( @"unknown un-binding '%@' requested", bindingName );
		
		[super unbind: bindingName];
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ( context == contentArrayBindingContext )
		[self rearrangeObjects];
}

#pragma mark --------data management-----------------

- (BOOL) suspendingArrangedObjectsUpdates
{
	return _updateSuspensionInfo.suspendUpdates;
}

- (void) suspendArrangedObjectsUpdates
{
	_updateSuspensionInfo.suspendUpdates = YES;
	_updateSuspensionInfo.arrayIsValid = YES; //arranged objects are considered to be valid
}

- (void) resumeArrangedObjectsUpdates
{
	if ( _updateSuspensionInfo.suspendUpdates )
	{
		_updateSuspensionInfo.suspendUpdates = NO;
		if ( !_updateSuspensionInfo.arrayIsValid )
			[self rearrangeObjects];
	}
}

- (id) collectionModel
{
	return [_model valueForKeyPath: _collectionKeyPath];
}

- (id) arrangedObjects
{
	if ( _model == nil )
		return NSNotApplicableMarker;
	
	if ( _cachedObjects == nil )
	{
		id collection = [self collectionModel];
		
		if ( collection == nil )
			return NSNotApplicableMarker;
		if ( NSIsControllerMarker( collection ) )
			return collection;

		NSArray *newObjects = nil;
		
		if ( [newObjects isKindOfClass: [NSArray class]] ) //NSArray, NSMutableArray
			newObjects = collection;
		else if ( [collection respondsToSelector: @selector(allValues)] ) //NSDictionary
			newObjects = [collection allValues];
		else if ( [collection respondsToSelector: @selector(allObjects)] )	//NSSet
			newObjects = [collection allObjects];
		else
		{
			NSAssert( [collection respondsToSelector: @selector(objectEnumerator)], @"can't get objects in collection as an array" );
			newObjects = [[collection objectEnumerator] allObjects];
		}
		
		_cachedObjects = [[self arrangeObjects: newObjects] retain];
	}
	
	return _cachedObjects;
}

- (void)rearrangeObjects
{
	if ( _updateSuspensionInfo.suspendUpdates )
		_updateSuspensionInfo.arrayIsValid = NO;
	else
	{
		[self willChangeValueForKey: @"arrangedObjects"];
		
		NSArray *selectedObjects = nil;
		if ( _cachedObjects != nil )
			selectedObjects = [self selectedObjects];
		
		[_mySelectionIndexes removeAllIndexes];
		
		[_cachedObjects release];
		_cachedObjects = nil;
		
		_updateSuspensionInfo.arrayIsValid = YES;
				
		[self didChangeValueForKey: @"arrangedObjects"];
		
		if ( selectedObjects != nil )
		{
			if ( !NSIsControllerMarker( selectedObjects ) )
				[self setSelectedObjects: selectedObjects];
			else
				[self setSelectionIndexes: [NSIndexSet indexSet]];
		}
	}
}

- (void)setSortDescriptors:(NSArray *)sortDescriptors
{
	[super setSortDescriptors: sortDescriptors];
	
	[self rearrangeObjects];
}

#pragma mark --------selection support-----------------

- (id) selection
{
	switch ( [_mySelectionIndexes count] )
	{
		case 0:
			return NSNoSelectionMarker;
		case 1:
		{
			NSArray *allObjects = [self arrangedObjects];
			if ( NSIsControllerMarker( allObjects ) )
				return allObjects;
			else
				return [allObjects objectAtIndex: [_mySelectionIndexes firstIndex]];
		}
		default:
			return NSMultipleValuesMarker;
	}
}

- (BOOL)setSelectionIndex:(unsigned int)index
{
	NSArray *allObjects = [self arrangedObjects];
	if ( NSIsControllerMarker( allObjects ) )
		return FALSE;
	
	if ( index >= [allObjects count] )
		return FALSE;
	
	if ( [_mySelectionIndexes count] == 1 && [_mySelectionIndexes firstIndex] == index )
		return YES;
		 
	[self onSelectionChanging];
	
	[_mySelectionIndexes autorelease];
	_mySelectionIndexes = [[NSMutableIndexSet alloc] initWithIndex: index];

	[self onSelectionChanged];
	
	return YES;
}

- (unsigned int)selectionIndex
{
	//returns NSNotFound if set is empty
	return _mySelectionIndexes == nil ? NSNotFound : [_mySelectionIndexes firstIndex];
}

- (NSIndexSet *)selectionIndexes
{
	return _mySelectionIndexes;
}

- (BOOL)setSelectionIndexes:(NSIndexSet *)indexes
{
	if ( [_mySelectionIndexes isEqualToIndexSet: indexes] )
		return YES;
	
	[self onSelectionChanging];
	
	[_mySelectionIndexes autorelease];
	_mySelectionIndexes = [indexes mutableCopy];
	
	[self onSelectionChanged];
	
	return YES;
}

- (BOOL)addSelectionIndexes:(NSIndexSet *)indexes
{
	if ( [_mySelectionIndexes containsIndexes: indexes] )
		return YES;
	
	[self onSelectionChanging];
	
	if ( _mySelectionIndexes == nil )
		_mySelectionIndexes = [indexes copy];
	else
		[_mySelectionIndexes addIndexes: indexes];
	
	[self onSelectionChanged];
	
	return YES;
}

- (BOOL)removeSelectionIndexes:(NSIndexSet *)indexes
{
	if ( [indexes count] == 0 )
		return YES;
	
	if ( ![_mySelectionIndexes containsIndexes: indexes] )
		return NO;
	
	[self onSelectionChanging];
	
	[_mySelectionIndexes removeIndexes: indexes];
	
	[self onSelectionChanged];
	
	return YES;
}

- (NSArray *)selectedObjects
{
	NSMutableArray *selectedObjects = [NSMutableArray arrayWithCapacity: [_mySelectionIndexes count]];
	
	NSArray *allObjects = [self arrangedObjects];
	
	if ( !NSIsControllerMarker( allObjects ) && [_mySelectionIndexes count] > 0 )
	{
		unsigned index;
		for ( index = [_mySelectionIndexes firstIndex]; index != NSNotFound; index = [_mySelectionIndexes indexGreaterThanIndex: index] )
			[selectedObjects addObject: [allObjects objectAtIndex: index]];
	}
	
	return selectedObjects;
}

- (BOOL)setSelectedObjects:(NSArray *)objects
{
	if ( NSIsControllerMarker( [self arrangedObjects] ) )
		return FALSE;
	
	NSIndexSet *newIndexes = [self indexesForObjects: objects];
	return [self setSelectionIndexes: newIndexes];
}

- (BOOL)addSelectedObjects:(NSArray *)objects
{
	if ( NSIsControllerMarker( [self arrangedObjects] ) )
		return FALSE;
		
	NSIndexSet *newIndexes = [self indexesForObjects: objects];
	return [self addSelectionIndexes: newIndexes];
}

- (BOOL)removeSelectedObjects:(NSArray *)objects
{
	if ( NSIsControllerMarker( [self arrangedObjects] ) )
		return FALSE;
	
	NSIndexSet *indexesToRemove = [self indexesForObjects: objects];
	return [self removeSelectionIndexes: indexesToRemove];
}

- (void) onSelectionChanging
{
	[self willChangeValueForKey: @"selection"];
	[self willChangeValueForKey: @"selectionIndex"];
	[self willChangeValueForKey: @"selectionIndexes"];
	[self willChangeValueForKey: @"selectedObjects"];
}

- (void) onSelectionChanged
{
	[self didChangeValueForKey: @"selection"];
	[self didChangeValueForKey: @"selectionIndex"];
	[self didChangeValueForKey: @"selectionIndexes"];
	[self didChangeValueForKey: @"selectedObjects"];
}

- (NSIndexSet*) indexesForObjects: (NSArray*) objects
{
	NSArray *allObjects = [self arrangedObjects];
	NSAssert( !NSIsControllerMarker( allObjects ), @"collection model for array controller has no objects" );
	
	NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
	
	unsigned int i;
	for ( i = 0; i < [objects count]; i++ )
	{
		unsigned int index = [allObjects indexOfObjectIdenticalTo: [objects objectAtIndex: i]];
		if ( index != NSNotFound )
			[indexes addIndex: index];
	}
	
	return indexes;
}

@end

@implementation GenericArrayController(Privat)


@end











