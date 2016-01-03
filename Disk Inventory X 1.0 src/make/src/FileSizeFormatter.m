//
//  FileSizeFormatter.m
//  Disk Inventory X
//
//  Created by Tjark Derlien on Sat Mar 27 2004.
//  Copyright (c) 2004 Tjark Derlien. All rights reserved.
//

#import "FileSizeFormatter.h"


@implementation FileSizeFormatter

- (id) init
{
	self = [super init];
	
    [self setFormatterBehavior:NSNumberFormatterBehavior10_0];
	[self setLocalizesFormat: YES];
	[self setFormat: @"#,#0.0"];
	
	return self;
}

- (NSString *) stringForObjectValue:(id)anObject
{
	NSParameterAssert( [anObject respondsToSelector: @selector(doubleValue)] );
	
	double dsize = [anObject doubleValue];
	
	NSString* units[] = {@"Bytes", @"kB", @"MB", @"GB", @"TB"};
	
	unsigned i = 0;
	while ( dsize >= 1024 && i < 5 )
	{
		i++;
		
		dsize /= 1024;
	}
	
	if ( i <= 1 )
		//Bytes, kB are displayed as integers (like the finder does)
		return [NSString stringWithFormat: @"%u %@", (unsigned) round(dsize), units[i] ];
	else
	{
		//MB, GB or TB
		NSString *ret = [super stringForObjectValue: [NSNumber numberWithDouble: dsize]];
		return [ret stringByAppendingFormat: @" %@", units[i]];
	}	
}


@end
