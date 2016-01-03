//
//  VolumeNameCell.h
//  Disk Inventory X
//
//  Created by Tjark Derlien on 08.11.04.
//  Copyright 2004 Tjark Derlien. All rights reserved.
//

#import <Cocoa/Cocoa.h>

//created an attributed string to be displayed in the volume name column
@interface VolumeNameTransformer : NSValueTransformer
{
}

+ (id) transformer;

+ (NSDictionary*) volumeTitleAttributes;
+ (NSDictionary*) volumeTypeAttributes;

@end
