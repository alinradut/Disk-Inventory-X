//
//  MyDocumentController.h
//  Disk Accountant
//
//  Created by Tjark Derlien on Wed Oct 08 2003.
//  Copyright (c) 2003 Tjark Derlien. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MyDocumentController : NSDocumentController
{
	IBOutlet NSMenu* _zoomStackMenu;
	IBOutlet NSPanel* _donationPanel;
}

- (IBAction) showPreferencesPanel: (id) sender;
- (IBAction) gotoHomepage: (id) sender;
- (IBAction) closeDonationPanel: (id) sender;

- (void) openDocumentWithContentsOfFile: (NSString*) fileName; //calls "openDocumentWithContentsOfFile: fileName display: [self shouldCreateUI]"
@end
