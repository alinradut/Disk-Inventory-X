//
//  DrivesPanelController.h
//  Disk Inventory X
//
//  Created by Tjark Derlien on 15.11.04.
//  Copyright 2004 Tjark Derlien. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DrivesPanelController : NSObject
{
	NSMutableArray *_volumes;
	NSMutableArray *_progressIndicators;
	IBOutlet NSTableView* _volumesTableView;
	IBOutlet NSWindow* _volumesPanel;
	IBOutlet NSButton* _openVolumeButton;
	IBOutlet NSArrayController *_volumesController;
}

+ (DrivesPanelController*) sharedController;

- (BOOL) panelIsVisible;
- (void) showPanel;
- (NSWindow*) panel;

- (NSArray*) volumes;

- (IBAction) openVolume:(id)sender;

@end
