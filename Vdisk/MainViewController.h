//
//  MainViewController.h
//  Vdisk
//
//  Created by Hao Tan on 11-12-26.
//  Copyright (c) 2011年 http://www.tanhao.me All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VdLoginWndController.h"

@interface MainViewController : NSViewController<NSOutlineViewDelegate,NSOutlineViewDataSource,NSMenuDelegate>
{
    VdLoginWndController *lwc;
    
    NSImage *upAnimationImg;
    NSImage *downAnimationImg;
    NSImage *upStopImg;
    NSImage *downStopImg;
    
    NSMutableArray *items;
    
    IBOutlet NSImageView *upImgView;
    IBOutlet NSImageView *downImgView;
    
    IBOutlet NSOutlineView *outlineView;
    IBOutlet NSTableColumn *iconColumn;
    IBOutlet NSTableColumn *nameColumn;
    IBOutlet NSTableColumn *typeColumn;
    IBOutlet NSTableColumn *stateColumn;
    
    IBOutlet NSButton             *refreshButton;
    IBOutlet NSProgressIndicator  *loadingView;
    
    NSStatusItem       *statusItem;
    IBOutlet NSMenu    *statusMenu;
    
    //shared window
    IBOutlet NSWindow         *sharedWindow;
    IBOutlet NSTextField      *sharedFileTitleField;
    IBOutlet NSTextField      *sharedStateField;
    IBOutlet NSTextField      *sharedMessageField;
    IBOutlet NSTextField      *sharedDownLinkField;
    IBOutlet NSTextField      *sharedDownLinkFieldTitle;
    IBOutlet NSButton         *sharedDownLinkFieldButton;
}

- (IBAction)synAutoClick:(id)sender;
- (IBAction)synUpClick:(id)sender;
- (IBAction)synDownClick:(id)sender;
- (IBAction)signInClick:(id)sender;

- (IBAction)logoClick:(id)sender;
- (IBAction)refreshClick:(id)sender;
- (IBAction)openFileClick:(id)sender;

- (IBAction)aboutClick:(id)sender;
- (IBAction)supportClick:(id)sender;
- (IBAction)showClick:(id)sender;
- (IBAction)quitClick:(id)sender;

- (IBAction)sharedCopyClick:(id)sender;
- (IBAction)sharedCloseClick:(id)sender;

@end
