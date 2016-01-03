/* FilesOutlineViewController */

#import <Cocoa/Cocoa.h>
#import "FileSystemDoc.h"
#import "ImageAndTextCell.h"
#import "FileSizeFormatter.h"

@interface FilesOutlineViewController : NSObject
{
    IBOutlet FileSystemDoc *_document;
    IBOutlet NSOutlineView *_outlineView;
    IBOutlet NSMenu *_contextMenu;
}

- (FileSystemDoc*) document;

- (FSItem*) rootItem;

@end
