//
//  TMVCushionRenderer.h
//  Disk Accountant
//
//  Created by Tjark Derlien on Sun Oct 12 2003.
//  Copyright (c) 2003 Tjark Derlien. All rights reserved.
//

#import <Foundation/Foundation.h>

//
// The treemap colors all have the "brightness" BASE_BRIGHTNESS.
// I define brightness as a number from 0 to 3.0.
// RGB(0.5, 1, 0), for example, has a brightness of 2.5.
//
#define BASE_BRIGHTNESS 1.8f

@interface TMVCushionRenderer : NSObject
{
    NSRect _rect;
    NSColor *_color;
    float _surface[4];
}

- (id) init;
- (id) initWithRect: (NSRect) rect;

- (NSRect) rect;
- (void) setRect: (NSRect) rect;

- (NSColor*) color;
- (void) setColor: (NSColor*) newColor;

- (float*) surface;
- (void) setSurface: (const float*) newsurface;

- (void) addRidgeByHeightFactor: (float) heightFactor;

- (void) renderCushionInBitmap: (NSBitmapImageRep*) bitmap;
- (void) renderCushionInBitmapGeneric: (NSBitmapImageRep*) bitmap;
- (void) renderCushionInBitmapPPC603: (NSBitmapImageRep*) bitmap; //PowerPC optimzed version (603+)

+ (void) normalizeColorRed: (float*) red green: (float*) green blue: (float*) blue;
+ (NSColor*) normalizeColor: (NSColor*) color;

@end
