//
//  DIXFileInfoView.m
//  Disk Inventory X
//
//  Created by Tjark Derlien on 04.12.04.
//  Copyright 2004 Tjark Derlien. All rights reserved.
//

#import "DIXFileInfoView.h"


@interface NTInfoView (MakeVisible)
- (NSArray*)infoPairs;
- (NSArray*)longInfoPairs;
@end

@interface DIXFileInfoView(Private)
- (NSArray*)infoPairs;
@end

@implementation DIXFileInfoView

@end

@implementation DIXFileInfoView(Private)

- (NSArray*)infoPairs
{
	NTFileDesc *desc = [self desc];
	
	NSMutableArray *infoPairs = (NSMutableArray*) [super infoPairs];
	OBPRECONDITION( [infoPairs isKindOfClass: [NSMutableArray class]] );

	//NTInfoView shows the display name (possibly localized and with hidden extension), but we want the "raw" name
	//(the display name is shown above next to the image in the inspector panel)
	if ( desc != nil )
	{
		NTTitledInfoPair *oldNameInfoPair = [infoPairs objectAtIndex: 0];
		
		[infoPairs replaceObjectAtIndex: 0
							 withObject: [NTTitledInfoPair infoPair: [oldNameInfoPair title] info: [desc name]]];
	}

	return infoPairs;
}


@end
