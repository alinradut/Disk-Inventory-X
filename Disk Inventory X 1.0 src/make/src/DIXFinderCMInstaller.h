//
//  DIXFinderCMInstaller.h
//  Disk Inventory X
//
//  Created by Tjark Derlien on 06.04.05.
//  Copyright 2005 Tjark Derlien. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NTFileDesc(DIXFinderCM)

+ (NSString*) DIXFinderCMFileName;
- (BOOL) isDIXFinderCM;

- (NSString*) extensionVersion;
- (NSComparisonResult) compareExtensionVersion: (NTFileDesc*) other;

@end


@interface DIXFinderCMInstaller : NSObject
{
	NTFileDesc *_builtInExtension;
	NTFileDesc *_installedExtension;
}

+ (id) installer;

- (BOOL) isInstalled;

- (NTFileDesc*) installedExtensionDesc;
- (NTFileDesc*) builtInExtensionDesc;

- (BOOL) installToDomain: (int) domain;
- (BOOL) remove;

@end
