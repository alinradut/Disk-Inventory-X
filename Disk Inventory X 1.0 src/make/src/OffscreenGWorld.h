//
//  OffscreenGWorld.h
//  Encapsulates an offscreen QuickDraw graphics context (GWorld)
//
// example: in the drawRect: method of an NSQuickDrawView, the drawing is first made into an offscreen GWorld,
//          and then the content of the GWorld is copied to the view
//          (which can be a lot quicker than drawing directly into the view, especially when making a lot descrete drawings)
//
//         SetGWorld( [self qdPort], NULL );
//
//         OffscreenGWorld *newGWorld = [[OffscreenGWorld alloc] initCompatibleToPort: [self qdPort]];
//         [newGWorld lockFocus];
//
//         // do the drawing with QuickDraw functions...
//
//         [newGWorld unlockFocus];
//         [newGWorld copyContentToCurrentPortFromRect: [self viewBounds] toRect: [self viewBounds]];
//         [newGWorld release];
//
//
//  Created by Tjark Derlien on Thu Oct 09 2003.
//  Copyright (c) 2003 Tjark Derlien. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif

void CopyNSRectToQDRect( const NSRect *srcRect, Rect* destRect );
void CopyQDRectToNSRect( const Rect* srcRect, NSRect *destRect );

#ifdef __cplusplus
} 	//extern "C"
#endif

@interface OffscreenGWorld : NSObject
{
    GWorldPtr _qdPort;

    GrafPtr _pSavedGPort;
    GDHandle _hSavedGDevice;
}

- (id) initWithRect: (NSRect) rect colorDepth: (short) colorDepth;
- (id) initWithRect: (NSRect) rect colorDepthFromPort: (CGrafPtr) port;
- (id) initCompatibleToPort: (CGrafPtr) port; //init GWorld with same color depth and dimension as "port"

- (GWorldPtr) qdPort;

- (void) lockFocus;
- (void) unlockFocus;

- (void) setRect: (NSRect) rect;

- (void) copyContentToCurrentPortFromRect: (NSRect) srcRect toRect: (NSRect) destRect;
@end
