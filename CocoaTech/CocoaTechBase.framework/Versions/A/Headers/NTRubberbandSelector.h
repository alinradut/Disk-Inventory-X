//
//     Generated by class-dump 3.5 (64 bit).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2013 by Steve Nygard.
//

#import "NSObject.h"

@class NSArray, NSView, NTClickState;

@interface NTRubberbandSelector : NSObject
{
    NSView *_delegateView;
    struct _NSPoint _startMousePoint;
    struct _NSPoint _previousMousePoint;
    struct _NSPoint _currentMousePoint;
    NSArray *_selection;
    NTClickState *_clickState;
    BOOL _didSelectWhileDragging;
}

+ (id)rubberbandWithView:(id)arg1 clickState:(id)arg2 selection:(id)arg3;
- (id)initWithView:(id)arg1 clickState:(id)arg2 selection:(id)arg3;
- (void)dealloc;
- (struct _NSPoint)startPoint;
- (struct _NSPoint)previousPoint;
- (struct _NSPoint)currentPoint;
- (void)updateMousePoint:(struct _NSPoint)arg1;
- (struct _NSRect)rubberbandRect;
- (BOOL)shiftKeyDown;
- (BOOL)commandKeyDown;
- (id)selection;
- (void)setDidSelectWhileDragging:(BOOL)arg1;
- (BOOL)didSelectWhileDragging;

@end

