//
//  NTFileDesc-AccessExtensions.h
//  Disk Inventory X
//
//  Created by Tjark Derlien on 03.10.04.
//  Copyright 2004 Tjark Derlien. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NTFileDesc(AccessExtensions)

- (NTFSRefObject*) fsRefObject;

- (void) setKindString: (NSString*) kindString;
- (BOOL) isKindStringSet;

- (void) setSize: (UInt64) size;

- (NSString*) displayName_fast;

@end

@interface NTFileDesc(MakePublic)

- (id)initWithFSRefObject:(NTFSRefObject*)refObject;
	//this method is implemented in NTFileDesc, but it's not public, so we only declare it here

@end
