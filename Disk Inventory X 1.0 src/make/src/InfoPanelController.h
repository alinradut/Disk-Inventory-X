//
//  InfoPanelController.h
//  Disk Inventory X
//
//  Created by Tjark Derlien on 16.11.04.
//  Copyright 2004 Tjark Derlien. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FSItem.h"

@class DIXFileInfoView;

@interface InfoPanelController : NSObject
{
	IBOutlet DIXFileInfoView *_infoView;
	IBOutlet NSWindow* _infoPanel;
	IBOutlet NSTextField* _displayNameTextField;
	IBOutlet NSImageView* _iconImageView;
}

+ (InfoPanelController*) sharedController;

- (BOOL) panelIsVisible;
- (void) showPanel;
- (void) hidePanel;
- (void) showPanelWithFSItem: (FSItem*) fsItem;
- (NSWindow*) panel;

@end
