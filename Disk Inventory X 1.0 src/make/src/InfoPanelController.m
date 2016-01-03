//
//  InfoPanelController.m
//  Disk Inventory X
//
//  Created by Tjark Derlien on 16.11.04.
//  Copyright 2004 Tjark Derlien. All rights reserved.
//

#import "InfoPanelController.h"
#import "DIXFileInfoView.h"

@implementation InfoPanelController

+ (InfoPanelController*) sharedController
{
	static InfoPanelController *controller = nil;
	
	if ( controller == nil )
		controller = [[InfoPanelController alloc] init];
	
	return controller;
}

- (id) init
{
	self = [super init];
		
	//load Nib with info panel
    if ( ![NSBundle loadNibNamed: @"InfoPanel" owner: self] )
	{
		[self release];
		self = nil;
	}
	else
	{
		/*
		NSRect frameRect = [_infoView frame];
		
		[_infoView removeFromSuperviewWithoutNeedingDisplay];
		
		_infoView = [[DIXFileInfoView alloc] initWithFrame: frameRect longFormat: YES];
		[_infoView autorelease];
		
		[_infoView setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
		
		[[_infoPanel contentView] addSubview: _infoView];
		 */
	}
	
	return self;
}

- (void) dealloc
{	
    [super dealloc];
}

- (BOOL) panelIsVisible
{
	return [[self panel] isVisible];
}

- (void) showPanel
{
	[[self panel] orderFront: nil];
}

- (void) hidePanel
{
	[[self panel] orderOut: nil];
}

- (NSWindow*) panel
{
	return _infoPanel;
}

- (void) showPanelWithFSItem: (FSItem*) fsItem
{
	[self showPanel];
	
	if ( fsItem == nil )
	{
		[_displayNameTextField setStringValue: @""];
		[_iconImageView setImage: nil];

		[_infoView setDesc: nil];
	}
	else if ( [fsItem fileDesc] != [_infoView desc] )
	{
		[_displayNameTextField setStringValue: [fsItem displayName]];
		[_iconImageView setImage: [fsItem iconWithSize: 32]];
			
		[_infoView setDesc: [fsItem fileDesc]];
	}
}

@end
