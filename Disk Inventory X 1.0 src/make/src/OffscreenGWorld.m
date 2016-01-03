//
//  OffscreenGWorld.m
//  Disk Accountant
//
//  Created by Tjark Derlien on Thu Oct 09 2003.
//  Copyright (c) 2003 Tjark Derlien. All rights reserved.
//

#import "OffscreenGWorld.h"

//================ interface OffscreenGWorld(Private) ======================================================

@interface OffscreenGWorld(Private)

- (void) allocGWorldWithRect: (NSRect) rect colorDepth: (short) colorDepth;
- (void) deallocGWorld;

@end

//================ implementation OffscreenGWorld ======================================================

@implementation OffscreenGWorld

- (id) initWithRect: (NSRect) rect colorDepth: (short) colorDepth
{
    self = [super init];

    [self allocGWorldWithRect: rect colorDepth: colorDepth];

    return self;
}

- (id) initWithRect: (NSRect) rect colorDepthFromPort: (CGrafPtr) port
{
    NSParameterAssert( port != NULL );

    self = [super init];

    //get color depth of GWorld to create our offscreen GWorld with the same depth
    short colorDepth = 32;
    PixMapHandle hPixMap = GetPortPixMap( port );
    if ( hPixMap != NULL )
        colorDepth = GetPixDepth( hPixMap );
    
    [self allocGWorldWithRect: rect colorDepth: colorDepth];

    return self;
}

- (id) initCompatibleToPort: (CGrafPtr) port
{
    NSParameterAssert( port != NULL );

    self = [super init];

    //get color depth of GWorld to create our offscreen GWorld with the same depth
    short colorDepth = 32;
    PixMapHandle hPixMap = GetPortPixMap( port );
    if ( hPixMap != NULL )
        colorDepth = GetPixDepth( hPixMap );

    Rect rect;
    GetPortBounds( port, &rect );

    NSRect nsRect;
    CopyQDRectToNSRect( &rect, &nsRect );

    [self allocGWorldWithRect: nsRect colorDepth: colorDepth];

    return self;
}


- (void) dealloc
{
    [self deallocGWorld];

    [super dealloc];
}

- (GWorldPtr) qdPort
{
    return _qdPort;
}

- (void) lockFocus
{
    NSAssert( _pSavedGPort == NULL, @"'OffscreetGWorld.lockFocus' called without prior 'unlockFocus'" );
    
    GetGWorld ( &_pSavedGPort, &_hSavedGDevice );
    
    if ( !LockPixels( GetGWorldPixMap( [self qdPort] ) ) )
        NSAssert( FALSE, @"can't lock offscreen GWorld" );

    SetGWorld( [self qdPort], NULL );
}

- (void) unlockFocus
{
    UnlockPixels( GetGWorldPixMap( [self qdPort] ) );
    
    NSAssert( _pSavedGPort != NULL, @"'OffscreetGWorld.unlockFocus' called without prior 'lockFocus'" );
    
    SetGWorld ( _pSavedGPort, _hSavedGDevice );

    _pSavedGPort = NULL;
    _hSavedGDevice = NULL;
}

- (void) setRect: (NSRect) rect
{
    PixMapHandle hPixMap = GetPortPixMap( [self qdPort] );
    NSAssert( hPixMap != NULL, @"no PixMap for our offscreen GWorld" );
        
    short colorDepth = GetPixDepth( hPixMap );

    [self allocGWorldWithRect: rect colorDepth: colorDepth];
}

- (void) copyContentToCurrentPortFromRect: (NSRect) srcRect toRect: (NSRect) destRect
{
    PixMapHandle hPixMap = GetGWorldPixMap( [self qdPort] );
    NSAssert( hPixMap != NULL, @"no PixMap for our offscreen GWorld" );

    //if our GWorld isn't already locked, lock it now
    BOOL alreadyLocked = ( GetPixelsState( hPixMap ) & pixelsLocked ) != 0;

    if ( !alreadyLocked && !LockPixels( GetGWorldPixMap( [self qdPort] ) ) )
        NSAssert( FALSE, @"can't lock offscreen GWorld" );

    //set source and destination rects
    Rect destQDrect;
    CopyNSRectToQDRect( &destRect, &destQDrect );
    
    Rect srcQDRect;
    CopyNSRectToQDRect( &srcRect, &srcQDRect );

    //get current GrafPort which will be the copy operation's destination
    GrafPtr pCurrentGPort;
    GDHandle hCurrentGDevice;
    GetGWorld ( &pCurrentGPort, &hCurrentGDevice );
    
    //now copy the content to current port
    CopyBits( GetPortBitMapForCopyBits( [self qdPort] ),
              GetPortBitMapForCopyBits( pCurrentGPort ),
              &srcQDRect, &destQDrect,
              srcCopy, NULL);

    //unlock GWorld if it wasn't locked before
    if ( !alreadyLocked )
        UnlockPixels( hPixMap );
}

@end

//================ implementation OffscreenGWorld(Private) ======================================================

@implementation OffscreenGWorld(Private)

- (void) allocGWorldWithRect: (NSRect) rect colorDepth: (short) colorDepth
{
    NSParameterAssert( NSHeight(rect) >= 1 && NSWidth(rect) >= 1 );

    [self deallocGWorld];

    Rect qdRect;
    CopyNSRectToQDRect( &rect, &qdRect );

    if ( NewGWorld( &_qdPort, colorDepth, &qdRect, NULL, NULL, 0 ) != noErr )
        NSAssert( FALSE, @"can't create QuickDraw offscreen GWorld" );
}

- (void) deallocGWorld
{
    if ( _qdPort != NULL )
    {
        DisposeGWorld( _qdPort );
        _qdPort = NULL;
    }
}

@end

#pragma mark ================ helpers ===============

void CopyNSRectToQDRect( const NSRect *srcRect, Rect* destRect )
{
    destRect->top =    (short) roundf( NSMinY( *srcRect ) );
    destRect->left =   (short) roundf( NSMinX( *srcRect ) );
    destRect->right =  (short) roundf( NSMaxX( *srcRect ) );
    destRect->bottom = (short) roundf( NSMaxY( *srcRect ) );
}

void CopyQDRectToNSRect( const Rect* srcRect, NSRect *destRect )
{
    *destRect = NSMakeRect( srcRect->left, srcRect->top,
                            srcRect->right - srcRect->left,
                            srcRect->bottom - srcRect->top );
}
