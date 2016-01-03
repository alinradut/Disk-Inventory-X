//
//  NTFileDesc-AccessExtensions.m
//  Disk Inventory X
//
//  Created by Tjark Derlien on 03.10.04.
//  Copyright 2004 Tjark Derlien. All rights reserved.
//

#import "NTFileDesc-AccessExtensions.h"
#import <CocoaTechFoundation/NTFileDesc.h>

@implementation NTFileDesc(AccessExtensions)

- (NTFSRefObject*) fsRefObject
{
	return _fsRefObject;
}

- (void) setKindString: (NSString*) kindString
{
	[_lock lock];
	
	[kindString retain];
	[_kindString release];
	_kindString = kindString;
	
	_bools.kindString_initialized = YES;
	
	[_lock unlock];
}

- (BOOL) isKindStringSet
{
	return _bools.kindString_initialized;
}

//NTFileDesc calls "FSGetTotalForkSizes(..)" to get the size of a file and
//to get a folder's size, you need caluculate it by youself and then call [fileDesc setFolderSize:].
//(PathFinders spawns a thread to calculate a folder's size in the background)
//We calculate the size during the folder traversal so we don't need the thread nor
//"FSGetTotalForkSizes(..)".
//(we just add the logical sizes of the data and resource forks to get a file's size)
- (void) setSize: (UInt64) size
{
	[_lock lock];
	
	_sizeOfAllForks = size;
	
	_bools.folderSizeIsCalculated = YES;
	_folderSize = size;
	
	[_lock unlock];
}

- (NSString*) displayName_fast
{
	//this method tries to avoid to call LSCopyDisplayNameForRef (in NTFileDesc.displayName)
	
	//directories (especially packages) may have localized names
	if ( _bools.displayName_initialized || [self isDirectory] )
		return [self displayName];
	
	//if a file's name has no extension or if we know the extennsion is hidden, we can determine
	//the display name without any help, otherwise call [self displayName]
	BOOL nameHasExtension = NO;
	
	NSString *name = [self name];
	
	NSRange extensionRange = [name rangeOfString: @"." options: NSLiteralSearch | NSBackwardsSearch];
	if ( extensionRange.location != NSNotFound && extensionRange.location > 0 )
		// search for a space
		nameHasExtension = [name rangeOfString:@" " options: NSLiteralSearch range: extensionRange].location == NSNotFound;
	
	if ( !nameHasExtension || _bools.itemInfo_initialized )
	{
		[_lock lock];
		
		if ( !nameHasExtension || !_bools.isExtensionHidden )
			_displayName = [name retain];
		else
			_displayName = [[name substringToIndex: extensionRange.location] retain];
		
		_bools.displayName_initialized = YES;
			
		[_lock unlock];
		
		return _displayName;
	}
	else
		return [self displayName];
}

@end
