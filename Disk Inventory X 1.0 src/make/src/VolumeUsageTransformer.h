//
//  VolumeNameCell.h
//  Disk Inventory X
//
//  Created by Tjark Derlien on 08.11.04.
//  Copyright 2004 Tjark Derlien. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FileSizeFormatter.h"

//created an attributed string to be displayed in the volume usage column
@interface VolumeUsageTransformer : NSValueTransformer
{
	FileSizeFormatter *_sizeFormatter;
}

+ (id) transformer;

+ (NSDictionary*) capacityStringAttributes;
+ (NSDictionary*) usedAndFreeStringAttributes;

@end
