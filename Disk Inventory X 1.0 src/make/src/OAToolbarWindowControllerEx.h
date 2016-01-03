//
//  OAToolbarWindowControllerEx.h
//  Disk Inventory X
//
//  Created by Tjark Derlien on 01.12.04.
//  Copyright 2004 Tjark Derlien. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <OmniAppKit/OAToolbarWindowController.h>

@interface NSToolbarItemValidationAdapter : NSObject
{
	NSToolbarItem* _toolbarItem;
}

- (void) setToolbarItem: (NSToolbarItem*) toolbarItem;
- (void) forwardInvocation: (NSInvocation*) anInvocation;

@end

@interface OAToolbarWindowControllerEx : OAToolbarWindowController {

}

- (NSImage*) toolbar: (NSToolbar*) theToolbar imageForToolbarItem: (NSToolbarItem*) item forState: (int) state; 

@end
