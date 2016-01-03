//
//  FSItem-Utilities.h
//  Disk Inventory X
//
//  Created by Tjark Derlien on 19.11.04.
//  Copyright 2004 Tjark Derlien. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface FSItem(Utilities)

- (unsigned) deepFileCountIncludingPackages: (BOOL) lookInPackages;	//count of files in all subdirectories

//if allowAncestors == YES, these methods will return an existing ancestor of the child to find if child doesn't exist
- (FSItem*) findItemByAbsolutePath: (NSString*) path allowAncestors: (BOOL) allowAncestors;
	//path e.g. /Applications/Utilities/Terminal.app

- (FSItem*) findItemByRelativePath: (NSString*) path allowAncestors: (BOOL) allowAncestors;
	//path e.g. Utilities/Terminal.app
- (FSItem*) findChildByRelativePathComponents: (NSArray*) pathComponent allowAncestors: (BOOL) allowAncestorss;

- (NSArray*) fsItemPath;
	//path from root to self as FSItems: <rootItem><child1><child2><self>
- (NSArray*) fsItemPathFromAncestor: (FSItem*) ancestor;
	//path from a specific ancestor to self as FSItems: <ancestor><child1><child2><self>
- (BOOL) isDescendantOf: (FSItem*) ancestor;
	//return YES if receiver is a descendant of ancestor

@end
