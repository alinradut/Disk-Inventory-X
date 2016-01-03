//
//  TMVItem.h
//  DiskAccountant
//
//  Created by Tjark Derlien on Tue Sep 30 2003.
//  Copyright (c) 2003 Tjark Derlien. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TMVCushionRenderer.h"

//holds display information about one cell in the treemap
@interface TMVItem : NSObject
{
    id _dataSource;
    id _delegate;
    id _item;
    id _view;
    
    NSRect _rect;
    NSMutableArray *_childRenderers;
    TMVCushionRenderer *_cushionRenderer;
}

- (id) initWithDataSource: (id) dataSource delegate: (id) delegate renderedItem: (id) item treeMapView: (id) view;

- (void) setCushionColor: (NSColor*) color; 

- (void) calcLayout: (NSRect) rect;

- (void) drawGrid;
- (void) drawHighlightFrame;

- (void) drawCushionInBitmap: (NSBitmapImageRep*) bitmap;

- (BOOL) isLeaf;
- (id) item;
- (unsigned long long) weight;

- (NSEnumerator *) childEnumerator;
- (TMVItem*) childAtIndex: (unsigned) index;
- (unsigned) childCount;

- (NSRect) rect;
- (TMVItem *) hitTest: (NSPoint) aPoint;

@end
