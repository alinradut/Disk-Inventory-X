//
//  NTFileDesc-Utilities.m
//  Disk Inventory X
//
//  Created by Tjark Derlien on 08.04.05.
//  Copyright 2005 Tjark Derlien. All rights reserved.
//

#import "NTFileDesc-Utilities.h"
#import "NTFileDesc-AccessExtensions.h"

@implementation NTFileDesc(Utilities)

- (NSString*) displayPath
{
	NSArray *fsRefPath = [self FSRefPath];
	NSString *displayPath = NSOpenStepRootDirectory();
	unsigned i = [fsRefPath count];
	while ( i-- )
	{
		NTFSRefObject *fsRef = [fsRefPath objectAtIndex: i];
		NTFileDesc *fileDesc = [[NTFileDesc alloc] initWithFSRefObject: fsRef];
		
		displayPath = [displayPath stringByAppendingPathComponent: [fileDesc displayName]];
		
		[fileDesc release];
	}
	
	return displayPath;
}

@end
