//
//  FinderCMPrefPage.h
//  Disk Inventory X
//
//  Created by Tjark Derlien on 07.04.05.
//  Copyright 2005 Tjark Derlien. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PrefsPageBase.h"


@interface FinderCMPrefPage : PrefsPageBase
{
	IBOutlet NSTextField *_statusInfoTextField;
	IBOutlet NSTextField *_extensionPathTextField;
	IBOutlet NSTextField *_noteTextField;
	IBOutlet NSButton *_installButton;
	IBOutlet NSButton *_removeButton;
	IBOutlet NSButton *_revealInFinderButton;
	IBOutlet NSMatrix *_domainMatrix;
}

- (IBAction) install: (id) sender;
- (IBAction) remove: (id) sender;
- (IBAction) revealInFinder: (id) sender;

@end
