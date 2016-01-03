//
//  VolumeNameTransformer.m
//  Disk Inventory X
//
//  Created by Tjark Derlien on 08.11.04.
//  Copyright 2004 Tjark Derlien. All rights reserved.
//

#import "VolumeNameTransformer.h"


@implementation VolumeNameTransformer

+ (void) initialize
{
}

+ (id) transformer
{
	return [[[VolumeNameTransformer alloc] init] autorelease];
}

- (id)transformedValue:(id)value 
{
	if ( value == nil )
		return nil;
	
	NSString *name = [value valueForKeyPath: @"mountPointFileDesc.displayName"];
	NSString *volumeType = [value valueForKeyPath: @"mountPointFileDesc.volumeFormat"];
	
	//create an attributed string with the format "<volume display name><line break> <volume format>"
	
	//volume display name
	NSMutableAttributedString *attribString = [[NSMutableAttributedString alloc] initWithString: name 
																					 attributes: [VolumeNameTransformer volumeTitleAttributes]];
	
	//add line break to string
	[attribString appendAttributedString: [[[NSAttributedString alloc] initWithString: @"\n "] autorelease]];
	
	//volume type (e.g. "HFS+")
	NSAttributedString *volumeTypeString = [[NSAttributedString alloc] initWithString: volumeType
																		   attributes: [VolumeNameTransformer volumeTypeAttributes]];
	
	//add volume format as second line
	[attribString appendAttributedString: volumeTypeString];
	[volumeTypeString release];
	
	return [attribString autorelease];
}

+ (NSDictionary*) volumeTitleAttributes
{
	static NSDictionary *attribs = nil;
	
	if ( attribs == nil )
	{
		NSFont *font = [NSFont systemFontOfSize: 0 /*default size*/];
		attribs = [[NSDictionary alloc] initWithObjectsAndKeys: font, NSFontAttributeName, nil];
	}
	
	return attribs;
}

+ (NSDictionary*) volumeTypeAttributes
{
	static NSDictionary *attribs = nil;
	
	if ( attribs == nil )
	{
		NSFont *font = [NSFont systemFontOfSize: [NSFont smallSystemFontSize]];
		attribs = [[NSDictionary alloc] initWithObjectsAndKeys: font, NSFontAttributeName, nil];
	}
	
	return attribs;
}

+ (Class) transformedValueClass
{
	return [NSAttributedString class];
}

@end
