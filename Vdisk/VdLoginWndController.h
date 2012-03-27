//
//  VdLoginWndController.h
//  Vdisk
//
//  Created by Hao Tan on 12-1-2.
//  Copyright (c) 2012年 http://tanhao.sinaapp.com/?p=5. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface VdLoginWndController : NSWindowController<NSPathControlDelegate>
{
    IBOutlet NSTextField          *userAccountField;
    IBOutlet NSSecureTextField    *userPasswordField;
    IBOutlet NSPathControl        *userPathControl;
    IBOutlet NSPopUpButton        *accountTypeButton;
    IBOutlet NSButton             *remenberButton;
    IBOutlet NSButton             *autoLoginButton;
    IBOutlet NSButton             *autoSysButton;
    
    IBOutlet NSProgressIndicator  *stateLoadingView;
    IBOutlet NSTextField          *stateLabel;
}

- (void)setUp;

- (IBAction)loginClick:(id)sender;
- (IBAction)closeClick:(id)sender;

- (IBAction)acountTypeClick:(id)sender;
- (IBAction)remenberClick:(id)sender;
- (IBAction)autoLoginClick:(id)sender;
- (IBAction)autoSynClick:(id)sender;

@end
