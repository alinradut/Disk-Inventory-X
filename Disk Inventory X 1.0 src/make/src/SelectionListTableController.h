//
//  SelectionListTableController.h
//  Disk Inventory X
//
//  Created by Tjark Derlien on 25.03.05.
//  Copyright 2005 Tjark Derlien. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FileSystemDoc.h"
#import "GenericArrayController.h"
#import "MainWindowController.h"
#import "FileKindsPopupController.h"

@interface SelectionListTableController : NSObject
{
    IBOutlet NSTableView *_tableView;
    IBOutlet MainWindowController *_windowController;
	IBOutlet GenericArrayController *_selectionListArrayController;
	IBOutlet FileKindsPopupController *_kindStatisticsArrayController;
}

- (FileSystemDoc*) document;

@end
