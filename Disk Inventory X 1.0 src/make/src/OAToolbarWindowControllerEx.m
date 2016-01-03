//
//  OAToolbarWindowControllerEx.m
//  Disk Inventory X
//
//  Created by Tjark Derlien on 01.12.04.
//  Copyright 2004 Tjark Derlien. All rights reserved.
//

#import "OAToolbarWindowControllerEx.h"
#import <OmniFoundation/NSString-OFExtensions.h>
#import <OmniAppKit/OAToolbarItem.h>

@implementation NSToolbarItemValidationAdapter

- (void) setToolbarItem: (NSToolbarItem*) toolbarItem
{
	[toolbarItem retain];
	[_toolbarItem release];
	_toolbarItem = toolbarItem;
}

- (void) forwardInvocation: (NSInvocation*) anInvocation
{
	if ( [_toolbarItem respondsToSelector: [anInvocation selector]] )
	{
		[anInvocation setTarget: _toolbarItem];
		[anInvocation invoke];
	}
	else
		[super forwardInvocation: anInvocation];
}

- (NSMethodSignature *) methodSignatureForSelector:(SEL)aSelector
{
	if ( [_toolbarItem respondsToSelector: aSelector] )
		return [_toolbarItem methodSignatureForSelector: aSelector];
	else
		return [super methodSignatureForSelector: aSelector];
}

- (void)setState:(int)itemState
{
	OAToolbarWindowControllerEx *controller = [[_toolbarItem toolbar] delegate];
	
	NSAssert( [controller isKindOfClass: [OAToolbarWindowControllerEx class]],
		@"delegate of toolbar must be a subclass of 'OAToolbarWindowControllerEx'" );
	
	NSImage *image = [controller toolbar: [_toolbarItem toolbar]
					 imageForToolbarItem: _toolbarItem
								forState: itemState];
	
	if ( image != nil && image != [_toolbarItem image] )
		[_toolbarItem setImage: image];
}

@end


@interface NSMenu(FindExtensions)

- (id<NSMenuItem>) menuItemWithAction: (SEL) action;

@end

static NSToolbarItemValidationAdapter *g_toolbarItemValidationAdapter = nil;
static NSMutableDictionary *g_toolbatStateImages = nil;

@implementation OAToolbarWindowControllerEx

#pragma mark -----------------Toolbar support---------------------

+ (void) initialize
{
	g_toolbarItemValidationAdapter = [[NSToolbarItemValidationAdapter alloc] init];
	g_toolbatStateImages = [[NSMutableDictionary alloc] init];
}

//returns an image for a toolbar item with a specific state (NSOnState, NSOffState, NSMixedState like menu items)
- (NSImage*) toolbar: (NSToolbar*) theToolbar imageForToolbarItem: (NSToolbarItem*) item forState: (int) state; 
{
	NSString *imageKey = nil;
	switch( state )
	{
		case NSOnState:
			imageKey = @"imageName";
			break;
		case NSOffState:
			imageKey = @"imageNameOffState";
			break;
		case NSMixedState:
			imageKey = @"imageNameMixedState";
			break;
		default:
			NSAssert( NO, @"invalid item state for ToolbarItem" );
	}
	
	//get the image cache for our toolbar
	NSMutableDictionary *toolbarImageCache = [g_toolbatStateImages objectForKey: [self toolbarConfigurationName]];
	if ( toolbarImageCache == nil )
	{
		toolbarImageCache = [NSMutableDictionary dictionary];
		[g_toolbatStateImages setObject: toolbarImageCache forKey: [self toolbarConfigurationName]];
	}
	
	//get image cache for the toolbar item
	NSMutableDictionary *itemImageCache = [toolbarImageCache objectForKey: [item itemIdentifier]];
	if ( itemImageCache == nil )
	{
		itemImageCache = [NSMutableDictionary dictionary];
		[toolbarImageCache setObject: itemImageCache forKey: [item itemIdentifier]];
	}
	
	//get the state image from the toolbar item image cache
	NSImage *image = [itemImageCache objectForKey: imageKey];
	if ( image == nil )
	{
		//we call super's implementation as we don't need the menu synchronisation stuff (see above)
		NSDictionary *itemInfo = [super toolbarInfoForItem: [item itemIdentifier]];
		
		//get image name from info dictionary
		NSString *imageName = [itemInfo objectForKey: imageKey];
		if ( imageName == nil )
			imageName = [itemInfo objectForKey: @"imageName"];
		
		NSAssert1( imageName != nil, @"no image name for item '%@'", [item itemIdentifier] );
		
		image = [NSImage imageNamed: imageName];
		NSAssert1( image != nil, @"couldn't load image '%@'", imageName );
		
		[itemImageCache setObject: image forKey: imageKey];
	}
	
	return image;
}

- (NSDictionary *)toolbarInfoForItem:(NSString *)identifier;
{
	NSMutableDictionary *itemInfo = [NSMutableDictionary dictionaryWithDictionary: [super toolbarInfoForItem: identifier]];
	
	//localize existing strings
#define LOCALIZE_PROPERTY( propname )									\
	if ( ![NSString isEmptyString: [itemInfo objectForKey: propname]] )	\
	{																	\
		NSString *localized = NSLocalizedString( [itemInfo objectForKey: propname], @"" ); \
		[itemInfo setObject: localized forKey: propname];				\
	}
	
	LOCALIZE_PROPERTY( @"label" );
	LOCALIZE_PROPERTY( @"paletteLabel" );
	LOCALIZE_PROPERTY( @"toolTip" );
	
#undef LOCALIZE_PROPERTY
	
	//We now try get the title and tooltip for the toolbar item from the menu.
	//This is done by searching for a menu item with the same action as the toolbar item.
	//Doing this, we don't need to type indentical strings in both the menu resource and the toolbar resource (.toolbar plist file).
	//And they only need to be localized in one place!
	
	NSString *actionString = [itemInfo objectForKey:@"action"];
	//did someone forgot the ':' at the end of the string? (actions always have the sender as a parameter)
	if ( ![NSString isEmptyString: actionString] && [actionString characterAtIndex: [actionString length] -1] != ':' )
	{
		actionString = [actionString stringByAppendingString: @":"];
		[itemInfo setObject: actionString forKey:@"action"];
	}
	
	SEL action = NSSelectorFromString( actionString );
	
	if (  action != 0
		  && ( [itemInfo objectForKey:@"label"] == nil || [itemInfo objectForKey:@"toolTip"] == nil ) )
	{
		id<NSMenuItem> menuItem = [[NSApp mainMenu] menuItemWithAction: action];
		if ( menuItem != nil )
		{
			//set label?
			if ( [itemInfo objectForKey:@"label"] == nil && ![NSString isEmptyString: [menuItem title]] )
			{
				//delete periods at end of title (e.g. "Preferences...")
				NSString *title = [menuItem title];
				unsigned numOfRemainingChars = [title length];
				unichar lastChar;
				do
				{
					numOfRemainingChars--;
					lastChar = [title characterAtIndex: numOfRemainingChars];
				}
				while ( ( lastChar == '.' || isspace(lastChar) ) && numOfRemainingChars > 0 );
				title = [title substringToIndex: numOfRemainingChars+1];
				
				[itemInfo setObject: title forKey: @"label"];
			}
			//set tooltip?
			if ( [itemInfo objectForKey:@"toolTip"] == nil && ![NSString isEmptyString: [menuItem toolTip]] )
				[itemInfo setObject: [menuItem toolTip] forKey: @"toolTip"];
		}
	}
	
	//if no string for "paletteLabel" is set, use the one for "toolTip" or "label"
	//(the paletteLabel is used as the toolbar item's title in the customizable sheet)
	if ( [itemInfo objectForKey:@"paletteLabel"] == nil )
	{
/*		if ( [itemInfo objectForKey:@"toolTip"] != nil )
			[itemInfo setObject: [itemInfo objectForKey:@"toolTip"] forKey: @"paletteLabel"];
		else*/ if ( [itemInfo objectForKey:@"label"] != nil )
			[itemInfo setObject: [itemInfo objectForKey:@"label"] forKey: @"paletteLabel"];
	}
	
    return itemInfo;
}

// NSObject (NSToolbarDelegate) subclass 

- (NSToolbarItem *)toolbar:(NSToolbar *)aToolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)willInsert
{
	//In addition to OAToolbarWindowController's support for specifying the target of a ToolbarItem, we
	//allow to the the document controller or the application object to be the traget.
	//OAToolbarWindowController's only sets self or the first responder.
	NSToolbarItem *toolbarItem = [super toolbar: aToolbar itemForItemIdentifier: itemIdentifier willBeInsertedIntoToolbar: willInsert];
	
	//we call super's implementation as we don't need the menu synchronisation stuff (see above)
	NSDictionary *itemInfo = [super toolbarInfoForItem: itemIdentifier];
	
	NSString *target = [itemInfo objectForKey: @"target"];
	
	if ( [target isEqualToString: @"documentController"] )
		[toolbarItem setTarget: [NSDocumentController sharedDocumentController]];
	else if ( [target isEqualToString: @"application"] )
		[toolbarItem setTarget: NSApp];
	
	//NSToolbarItem calls it's target to validate itself (through validateToolbarItem:).
	//If the target is not self we have no control over the validation.
	//This "problem" can be solved to set ourself as the delegate. OAToolbarItem's delegate
	//has the last word in the validation process.
	//(OAToolbarWindowController does this only for items with a custom view).
	[(OAToolbarItem*)toolbarItem setDelegate: self];
	
	return toolbarItem;
}

// NSObject (NSToolbarItemValidation)

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem;
{
    if ( ![[self window] isKeyWindow] )
		return NO;
	
	[g_toolbarItemValidationAdapter setToolbarItem: theItem];
	
	return [self validateMenuItem: (id<NSMenuItem>) g_toolbarItemValidationAdapter];
}

@end


@implementation NSMenu(FindExtensions)

//linear search through all menu items (including sub menus)
- (id<NSMenuItem>) menuItemWithAction: (SEL) action
{
	//we enumerate backwards as for the main menu bar the more application specific actions
	//are often in the menus after "File" and "Edit", so it is more likely to find the
	//item in question in the rear menus (this may not apply to sub menus, but we do a linar search anyway) 
	int i = [self numberOfItems];
	while ( i-- )
	{
		id <NSMenuItem> menuItem = [self itemAtIndex: i];
		
		if ( [menuItem action] == action )
			return menuItem;
		
		if ( [menuItem hasSubmenu] )
		{
			menuItem = [[menuItem submenu] menuItemWithAction: action];
			if ( menuItem != nil )
				return menuItem;
		}
	}
	
	//not found
	return nil;
}

@end

