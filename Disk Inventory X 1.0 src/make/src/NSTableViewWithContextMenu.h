//
//  NSTableViewWithContextMenu.h
//  Disk Inventory X
//
//  Created by Tjark Derlien on 31.03.05.
//  Copyright 2005 Tjark Derlien. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSObject(NSTableViewDelegateContextMenu)
- (NSMenu*) tableView: (NSTableView *) tableView menuForTableColumn: (NSTableColumn*) column row: (int) row;
		//delegate will be asked what menu to show (if not implemented by delegate [self menu] is used)
@end

@interface NSTableViewWithContextMenu : NSTableView {

}

@end
