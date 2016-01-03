//
//  FileSizeTransformer.m
//  Disk Inventory X
//
//  Created by Tjark Derlien on 25.03.05.
//  Copyright 2005 Tjark Derlien. All rights reserved.
//

#import "FileSizeTransformer.h"


@implementation FileSizeTransformer

- (id) init
{
	self = [super init];
	
	_sizeFormatter = [[FileSizeFormatter alloc] init];
	
	return self;
}

- (void) dealloc
{
	[_sizeFormatter release];
	
	[super dealloc];
}

+ (id) transformer
{
	return [[[[self class] alloc] init] autorelease];
}

- (id)transformedValue:(id)value 
{
	if ( value == nil )
		return nil;
	
	return [_sizeFormatter stringForObjectValue: value];
}

+ (Class) transformedValueClass
{
	return [NSString class];
}

@end
