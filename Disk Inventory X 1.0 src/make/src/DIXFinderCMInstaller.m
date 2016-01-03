//
//  DIXFinderCMInstaller.m
//  Disk Inventory X
//
//  Created by Tjark Derlien on 06.04.05.
//  Copyright 2005 Tjark Derlien. All rights reserved.
//

#import "DIXFinderCMInstaller.h"

@implementation NTFileDesc(DIXFinderCM)

- (BOOL) isDIXFinderCM
{
	return [self isValid]
		&& [self isDirectory]
		&& [[self name] isEqualToString: [NTFileDesc DIXFinderCMFileName]];
}

+ (NSString*) DIXFinderCMFileName
{
	return @"Disk Inventory X Finder CM.plugin";
}

- (NSString*) extensionVersion
{
	NSString *version = nil;
	
	NSString *infoplistPath = [[self path] stringByAppendingString: @"/Contents/Info.plist"];
	NSDictionary *infoDict = [NSDictionary dictionaryWithContentsOfFile: infoplistPath];
	if ( infoDict != nil )
		version = [infoDict objectForKey: @"CFBundleShortVersionString"];
		 
	/*
	NSBundle *bundle = [NSBundle bundleWithPath: [self path]];
	
	if ( bundle != nil )
		version = [[bundle infoDictionary] objectForKey: @"CFBundleShortVersionString"];
	*/
	return version;
}

- (NSComparisonResult) compareExtensionVersion: (NTFileDesc*) other
{
	//we use a simple version scheme (e.g. version 1.2)
	//so the version can be interpreted as a float value
	float myVersion = [[self extensionVersion] floatValue];
	float otherVersion = [[other extensionVersion] floatValue];
	
	if ( myVersion < otherVersion )
		return NSOrderedAscending;
	if ( myVersion > otherVersion )
		return NSOrderedDescending;
	else
		return NSOrderedSame;
}

@end



@interface DIXFinderCMInstaller(Privat)
- (NSString*) extensionPathForDomain: (int) domain;
@end

@implementation DIXFinderCMInstaller

+ (id) installer
{
	return [[[[self class] alloc] init] autorelease];
}

- (void) dealloc
{
	[_installedExtension release];
	[_builtInExtension release];
	
	[super dealloc];
}

- (BOOL) isInstalled
{
	NTFileDesc *installedExtensionDesc = [self installedExtensionDesc];
	NTFileDesc *builtInExtensionDesc = [self builtInExtensionDesc];
	NSAssert( builtInExtensionDesc != nil, @"exetutable doesn't contain the finder menu extension");
	
	if ( installedExtensionDesc == nil )
		return NO;
	
	return [builtInExtensionDesc compareExtensionVersion: installedExtensionDesc] != NSOrderedDescending;
}

- (NTFileDesc*) installedExtensionDesc
{
	if ( _installedExtension == nil )
	{
		//first try user domain (~/Library/Contextual Menu Items)
		NSString *extensionPath = [self extensionPathForDomain: kUserDomain];
		
		NTFileDesc *extensionDesc = [NTFileDesc descNoResolve: extensionPath];
		if ( ![extensionDesc isDIXFinderCM] )
		{
			//then try system domain (/Library/Contextual Menu Items)
			NSString *extensionPath = [self extensionPathForDomain: kSystemDomain];
			
			extensionDesc = [NTFileDesc descNoResolve: extensionPath];
		}
		
		_installedExtension = [extensionDesc isDIXFinderCM] ? [extensionDesc retain] : (id) [NSNull null];
	}
	
	return _installedExtension == (id) [NSNull null] ? nil : _installedExtension;
}

- (NTFileDesc*) builtInExtensionDesc
{
	if ( _builtInExtension == nil )
	{
		NSString *extensionPath = [[NSBundle mainBundle] pathForAuxiliaryExecutable: [NTFileDesc DIXFinderCMFileName]];
		NTFileDesc *extensionDesc = [NTFileDesc descNoResolve: extensionPath];
		
		_builtInExtension = [extensionDesc isDIXFinderCM] ? [extensionDesc retain] : (id) [NSNull null];
	}
	
	return _builtInExtension == (id) [NSNull null] ? nil : _builtInExtension;
}

- (BOOL) installToDomain: (int) domain
{
	OBPRECONDITION( domain == kUserDomain || domain == kLocalDomain );
	
	NTFileDesc *installedExtensionDesc = [self installedExtensionDesc];
	NTFileDesc *builtInExtensionDesc = [self builtInExtensionDesc];
	NSAssert( builtInExtensionDesc != nil, @"exetutable doesn't contain the finder menu extension");

	NSString *extensionPath = nil;
	
	//delete old extension
	if ( installedExtensionDesc != nil )
	{
		extensionPath = [installedExtensionDesc path];
		
		if ( ![self remove] )
			return FALSE;
	}
	else
		extensionPath = [self extensionPathForDomain: domain];
	
	//copy extension
	if ( [[NTFileCopyManager sharedInstance] copy: NO //syncronous
												src: builtInExtensionDesc
										  positions: nil
											   dest: extensionPath] )
	{
		return YES;
	}
	else
		return NO;
}

- (BOOL) remove
{
	NTFileDesc *installedExtensionDesc = [self installedExtensionDesc];
	if ( installedExtensionDesc != nil )
	{
		//try to delete it
		if ( ![[NTFileCopyManager sharedInstance] destroy: NO //syncronous
												src: installedExtensionDesc] )
			
		{
			//deleting didn't work, so try to move it to trash
			NSArray *filesToTrash = [NSArray arrayWithObject: [installedExtensionDesc name]];
			int tag = 0;
			if ( ![[NSWorkspace sharedWorkspace] performFileOperation: NSWorkspaceRecycleOperation
															  source: [installedExtensionDesc parentPath: NO]
														 destination: @""
															   files: filesToTrash
																 tag: &tag] )
			{
				return NO;
			}
		}
		return YES;
	}
	
	//nothing to remove
	return YES;
}

@end

@implementation DIXFinderCMInstaller(Privat)

- (NSString*) extensionPathForDomain: (int) domain
{
	OBPRECONDITION( domain == kUserDomain || domain == kLocalDomain );
	
	NSString *extensionPath;
	if ( domain == kUserDomain )
		extensionPath = [[NTDefaultDirectory sharedInstance] userContextualMenuItemsPath];
	else
		extensionPath = [[NTDefaultDirectory sharedInstance] contextualMenuItemsPath];
	
	return [extensionPath stringByAppendingPathComponent: [NTFileDesc DIXFinderCMFileName]];
}

@end
