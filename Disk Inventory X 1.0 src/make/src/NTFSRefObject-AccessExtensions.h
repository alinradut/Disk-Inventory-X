//
//  NTFSRefObject-AccessExtensions.h
//  Disk Inventory X
//
//  Created by Tjark Derlien on 29.11.04.
//  Copyright 2004 Tjark Derlien. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NTFSRefObject(AccessExtensions)

- (UInt64)rsrcForkPhysicalSize;
- (UInt64)dataForkPhysicalSize;

- (BOOL) isPathSet;
- (void) setPath: (NSString*) path;

@end
