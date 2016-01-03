//
//  LoadingPanelController.m
//  Disk Inventory X
//
//  Created by Tjark Derlien on 03.12.04.
//  Copyright 2004 Tjark Derlien. All rights reserved.
//

#import "LoadingPanelController.h"
#import "timing.h"


@implementation LoadingPanelController

- (id) init
{
	self = [super init];
	
    //load Nib with progress panel
	if ( ![NSBundle loadNibNamed: @"LoadingPanel" owner: self] )
		NSAssert( NO, @"couldn't load LoadingPanel.nib" );
	
	[_loadingProgressIndicator setUsesThreadedAnimation: NO];
    [_loadingProgressIndicator startAnimation: self];
	
	[_loadingPanel display];
	
	//start modal session for the progress window
	_loadingPanelModalSession = [[NSApplication sharedApplication] beginModalSessionForWindow: _loadingPanel];
	_lastEventLoopRun = 0;
	
	_cancelPressed = NO;
	
	return self;
}

- (id) initAsSheetForWindow: (NSWindow*) window
{
	self = [super init];
	
    //load Nib with progress panel
	if ( ![NSBundle loadNibNamed: @"LoadingPanel" owner: self] )
		NSAssert( NO, @"couldn't load LoadingPanel.nib" );
	
	[NSApp beginSheet: _loadingPanel
	   modalForWindow: window
		modalDelegate: self
	   didEndSelector: nil
		  contextInfo: NULL];
	
	[_loadingPanel setWorksWhenModal: YES];
	
	[_loadingProgressIndicator setUsesThreadedAnimation: NO];
    [_loadingProgressIndicator startAnimation: self];
	
	//we don't have modal session if we show the panel as a sheet
	_loadingPanelModalSession = 0;
	
	_lastEventLoopRun = 0;
	
	_cancelPressed = NO;
	
	return self;
}

- (void) dealloc
{
	if ( _loadingPanel != nil )
		[self close];
	
	[super dealloc];
}

- (void) close
{
	if ( [_loadingPanel isSheet] )
	{
		[NSApp endSheet: _loadingPanel];
		[_loadingPanel close]; //will be released (panel has style "release when close")
		
		_loadingPanel = nil;
		_loadingProgressIndicator = nil;
		_loadingTextField = nil;
		_loadingCancelButton = nil;
	}
	else
	{
		OBPRECONDITION( _loadingPanelModalSession != 0 );
		[[NSApplication sharedApplication] endModalSession: _loadingPanelModalSession];
		_loadingPanelModalSession = 0;
		
		[self closeNoModalEnd];
	}
}

- (void) closeNoModalEnd
{
	//this only works if we startet a modal session for a panel (no sheet)
	OBPRECONDITION( ![_loadingPanel isSheet] );
	
	//the sender asked us not to end the modal session (maybe because sender has run into an exception)
	_loadingPanelModalSession = 0;
	
	[_loadingPanel close]; //will be released (panel has style "release when close")
	
	_loadingPanel = nil;
    _loadingProgressIndicator = nil;
	_loadingTextField = nil;
	_loadingCancelButton = nil;
}

- (void) enableCancelButton: (BOOL) enable
{
	[_loadingCancelButton setEnabled: enable];
}

- (BOOL) cancelPressed
{
	return _cancelPressed;
}

- (void) startAnimation;
{
	[_loadingProgressIndicator startAnimation: nil];
}

- (void) stopAnimation;
{
	[_loadingProgressIndicator stopAnimation: nil];
}

- (void) setMessageText: (NSString*) msg
{
	[msg retain];
	[_message release];
	_message = msg;
}

- (void) runEventLoop;
{
	//we only let the UI update itself every 0.2 second, otherwise running
	//the event loop eats over half of the total scan time!
	uint64_t currentTime = getTime();
	BOOL runEventLoop = _lastEventLoopRun == 0 || subtractTime( currentTime, _lastEventLoopRun ) > 0.2;

	if ( _message != nil )
	{
		[_loadingTextField setStringValue: _message];
		
		//set message to nil so it won't be set a again in the NSTextField
		[self setMessageText: nil];
			
		//if we don't run the event loop, just update the text field
		if ( !runEventLoop )
			[_loadingTextField displayIfNeeded];
	}
	
	if ( runEventLoop )
	{
		_lastEventLoopRun = currentTime;
		
		//give progress dialog some processor cycles
		if ( _loadingPanelModalSession != 0 )
		{
			if ( [[NSApplication sharedApplication] runModalSession: _loadingPanelModalSession]
																			!= NSRunContinuesResponse )
			{
				NSAssert( NO, @"run loop stopped by unknown party" );
			}
		}
		else
		{
			[[NSRunLoop currentRunLoop] runUntilDate: [NSDate date]];
		}
	}
}

- (IBAction) cancel:(id)sender
{
	_cancelPressed = YES;
	
	[_loadingCancelButton setEnabled: NO];
}

@end

