//
//  AppDelegate.h
//  Vdisk
//
//  Created by Hao Tan on 11-12-26.
//  Copyright (c) 2011年 http://www.tanhao.me All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MainViewController.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>
{
    MainViewController *mvc;
}

@property (assign) IBOutlet NSWindow *window;

@end
