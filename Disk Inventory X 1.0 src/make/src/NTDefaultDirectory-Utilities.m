//
//  NTDefaultDirectory-Utilities.m
//  Disk Inventory X
//
//  Created by Tjark Derlien on 18.11.04.
//  Copyright 2004 Tjark Derlien. All rights reserved.
//

#import "NTDefaultDirectory-Utilities.h"


@implementation NTDefaultDirectory(Utilities)

- (NTFileDesc*) safeTrashForDesc:(NTFileDesc*)desc
{
	return [NTFileDesc descResolve:[self safeTrashPathForDesc: desc]];
}

- (NSString*) safeTrashPathForDesc:(NTFileDesc*)desc
{
	//if desc is on the same volume as the home dir, return trash in the home dir
	//otherwise return trash on that volume for the current user (/.Trashes/<UserID>/)
	NTFileDesc *homeDesc = [self home];
	if ( [homeDesc volumeRefNum] == [desc volumeRefNum] )
		return [self trashPath];
	else
		return [self trashPathForDesc: desc];
}

@end
