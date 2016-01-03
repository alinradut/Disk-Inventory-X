//
//  NTDefaultDirectory-Utilities.h
//  Disk Inventory X
//
//  Created by Tjark Derlien on 18.11.04.
//  Copyright 2004 Tjark Derlien. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NTDefaultDirectory(Utilities)

//The trashForDesc and trashPathForDesc methods of NTDefaultDirectory return /.Trashes/<UserID>/ for every volume,
//even if it's the drive where the user home lies (then the trash it at /.../username/.Trash).
//These 2 methods returns the correct trash folder path in every case.
- (NTFileDesc*) safeTrashForDesc:(NTFileDesc*)desc;
- (NSString*) safeTrashPathForDesc:(NTFileDesc*)desc;

@end
