//
//     Generated by class-dump 3.5 (64 bit).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2013 by Steve Nygard.
//

#import "NSObject.h"

@class NSView;

@interface NTCarbonDragHelper : NSObject
{
    CDUnknownFunctionPointerType _trackingUPP;
    CDUnknownFunctionPointerType _receiveUPP;
    NSView *_view;
}

- (id)initWithView:(id)arg1;
- (void)dealloc;
- (void)installHandler;

@end

