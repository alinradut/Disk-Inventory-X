//
//  FSItem-Utilities.m
//  Disk Inventory X
//
//  Created by Tjark Derlien on 19.11.04.
//  Copyright 2004 Tjark Derlien. All rights reserved.
//

#import "FSItem.h"
#import "FSItem-Utilities.h"

@implementation FSItem(Utilities)

- (unsigned) deepFileCountIncludingPackages: (BOOL) lookInPackages
{
	if ( [self isSpecialItem] )
		return 0;
	
	int i;
	unsigned deepChildCount = 0;
	for ( i = 0; i < [self childCount]; i++ )
	{
		FSItem *child = [self childAtIndex: i];
		
		if ( [child isFolder] )
		{
			if ( lookInPackages || ![self isPackage] )
				deepChildCount += [child deepFileCountIncludingPackages: lookInPackages];
		}
		else
			deepChildCount++;
	}
	
	return deepChildCount;
}

- (FSItem*) findItemByAbsolutePath: (NSString*) path allowAncestors: (BOOL) allowAncestors
{
	NSString *myPath = [self path];
	
	if ( [path isEqualToString: myPath] )
		return self;

	if ( ![path hasPrefix: myPath] )
		return nil; //path defines no child
	
	//get relative child path (relative to self)
	unsigned childPathStartIndex = [myPath length];
	if ( ![myPath isEqualToString: NSOpenStepRootDirectory()] ) // should just be @"/"
		childPathStartIndex++;
	
	NSString *childPath = [path substringFromIndex: childPathStartIndex]; 
	
	return [self findItemByRelativePath: childPath allowAncestors: allowAncestors];
}

- (FSItem*) findItemByRelativePath: (NSString*) path allowAncestors: (BOOL) allowAncestors
{
	if ( [path length] == 0 )
		return self;
	else
		return [self findChildByRelativePathComponents: [path pathComponents] allowAncestors: allowAncestors];
}

- (FSItem*) findChildByRelativePathComponents: (NSArray*) pathComponents allowAncestors: (BOOL) allowAncestors
{
	NSAssert( [pathComponents count] > 0, @"path must contain at least 1 component" );
	
	FSItem *parent = self;
	FSItem *child = nil;
	NSEnumerator *pathEnum = [pathComponents objectEnumerator];
	NSString *name;
	while( (name = [pathEnum nextObject]) != nil )
	{
		NSEnumerator *childEnum = [parent childEnumerator];
		//find child by name
		while ( (child = [childEnum nextObject]) != nil && ![[child name] isEqualToString: name] );
		
		if ( child == nil )
		{	//not found
			return allowAncestors ? parent : nil;
		}

		parent = child;
	}
	
	return child;
}

- (NSArray*) fsItemPath	//path from root to self
{
	return [self fsItemPathFromAncestor: nil];
}

//path from a specific ancestor to self as FSItems: <ancestor><child1><child2><self>
- (NSArray*) fsItemPathFromAncestor: (FSItem*) ancestor
{
	NSMutableArray *pathToSelf = [NSMutableArray array];
	
	FSItem *item = self;
	do
	{
		[pathToSelf insertObject: item atIndex: 0];
		
		item = [item parent];
	}
	while ( item != nil && item != ancestor );
	
	NSAssert( item == ancestor, @"the given item is no ancestor of self" );

	//finally add the ancestor to the array
	if ( item != nil )
		[pathToSelf insertObject: item atIndex: 0];
	
	return pathToSelf;
}

//return YES if receiver is a descendant of ancestor
- (BOOL) isDescendantOf: (FSItem*) ancestor
{
	FSItem *aParent = self;
	
	do
	{
		aParent = [aParent parent];
	}
	while ( aParent != nil && aParent != ancestor );
	
	return aParent != nil;
}

@end
