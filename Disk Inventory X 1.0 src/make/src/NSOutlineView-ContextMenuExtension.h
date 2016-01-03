//
//  NSOutlineView+ContextMenuExtension.h
//  Disk Inventory X
//
//  Created by Tjark Derlien on 29.03.05.
//  Copyright 2005 Tjark Derlien. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSOutlineView(ContextMenuExtension)

- (id) selectedItem;

@end

@interface NSObject(NSOutlineViewDelegateContextMenu)
- (NSMenu*) outlineView: (NSOutlineView *) outlineView menuForTableColumn: (NSTableColumn*) column item: (id) item;
@end

