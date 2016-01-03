//
//  NSTableViewWithContextMenu.m
//  Disk Inventory X
//
//  Created by Tjark Derlien on 31.03.05.
//  Copyright 2005 Tjark Derlien. All rights reserved.
//

#import "NSTableViewWithContextMenu.h"


@implementation NSTableViewWithContextMenu

// ask the delegate which menu to show
-(NSMenu*) menuForEvent:(NSEvent*)evt
{
    NSPoint point = [self convertPoint: [evt locationInWindow] fromView: nil];
    
    int columnIndex = [self columnAtPoint:point];
    int rowIndex = [self rowAtPoint:point];
	
    if ( rowIndex >= 0 && [self numberOfSelectedRows] <= 1)
        [self selectRow: rowIndex byExtendingSelection: NO];
	
    id delegate = [self delegate];
    
    if ( columnIndex >= 0 && rowIndex >= 0 )
    {
		//get context menu
        NSMenu *contextMenu = nil;
		if ( [delegate respondsToSelector:@selector(outlineView:menuForTableColumn:item:)] )
		{
			NSTableColumn *column = [[self tableColumns] objectAtIndex: columnIndex];
			contextMenu = [delegate tableView:self menuForTableColumn: column row: rowIndex];
		}
		else
			contextMenu = [self menu];
		
		//set first responder if we will show a context menu
		//(isn't nessecary for proper function, but makes sense as the user opens the context menu)
		if ( contextMenu != nil
			 && [self acceptsFirstResponder]
			 && [[self window] firstResponder] != self )
		{
			[[self window] makeFirstResponder: self];
		}
		
		return contextMenu;
    }
    else
        return NULL;
}

@end
