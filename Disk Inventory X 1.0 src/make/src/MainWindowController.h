/* MainWindowController */

#import <Cocoa/Cocoa.h>
#import "FileSystemDoc.h"
#import <TreeMapView/TreeMapView.h>
#import "OAToolbarWindowControllerEx.h"
#import <OmniAppKit/OASplitView.h>

@interface MainWindowController : OAToolbarWindowControllerEx
{
    IBOutlet NSDrawer *_kindsDrawer;
    IBOutlet NSDrawer *_selectionListDrawer;
	IBOutlet OASplitView *_splitter;
	IBOutlet NSOutlineView *_filesOutlineView;
	IBOutlet TreeMapView *_treeMapView;
}

+ (FileSystemDoc*) documentForView: (NSView*) view;

+ (void) poofEffectInView: (NSView*)view inRect: (NSRect) rect; //rect in view coords

- (NSDrawer*) kindStatisticsDrawer;
- (NSDrawer*) selectionListDrawer;

- (IBAction) toggleFileKindsDrawer:(id)sender;
- (IBAction) toggleSelectionListDrawer:(id)sender;
- (IBAction) zoomIn:(id)sender;
- (IBAction) zoomOut:(id)sender;
- (IBAction) zoomOutTo:(id)sender;
- (IBAction) showInFinder:(id)sender;
- (IBAction) refresh:(id)sender;
- (IBAction) refreshAll:(id)sender;
- (IBAction) moveToTrash:(id)sender;
- (IBAction) showPackageContents:(id)sender;
- (IBAction) showFreeSpace:(id)sender;
- (IBAction) showOtherSpace:(id)sender;
- (IBAction) selectParentItem:(id)sender;
- (IBAction) changeSplitting:(id)sender;
- (IBAction) showInformationPanel:(id)sender;
- (IBAction) showPhysicalSizes:(id) sender;
- (IBAction) ignoreCreatorCode:(id) sender;

- (IBAction) performRenderBenchmark:(id)sender;
- (IBAction) performLayoutBenchmark:(id)sender;
@end
