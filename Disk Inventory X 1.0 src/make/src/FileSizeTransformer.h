//
//  FileSizeTransformer.h
//  Disk Inventory X
//
//  Created by Tjark Derlien on 25.03.05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FileSizeFormatter.h"


@interface FileSizeTransformer : NSValueTransformer
{
	FileSizeFormatter *_sizeFormatter;
}

+ (id) transformer;

@end
