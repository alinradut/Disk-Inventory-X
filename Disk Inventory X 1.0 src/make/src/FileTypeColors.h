//
//  FileTypeColors.h
//  Disk Inventory X
//
//  Created by Tjark Derlien on Sun Oct 05 2003.
//  Copyright (c) 2003 Tjark Derlien. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FSItem.h"

@interface FileTypeColors : NSObject {
    NSMutableDictionary *_colors;
    NSMutableArray *_predefinedColors;
}

+ (FileTypeColors*) instance;

- (NSColor *) colorForItem: (FSItem*) item;
- (NSColor *) colorForKind: (NSString*) kind;

- (void) reset;

@end
