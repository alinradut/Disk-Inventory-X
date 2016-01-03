//
//  PrefsPanelController.h
//  Disk Inventory X
//
//  Created by Tjark Derlien on 28.11.04.
//  Copyright 2004 Tjark Derlien. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <OmniAppKit/OAPreferenceController.h>


@interface PrefsPanelController : OAPreferenceController {

}

+ (PrefsPanelController*) sharedPreferenceController;

@end
