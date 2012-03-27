//
//  AppDelegate.m
//  Vdisk
//
//  Created by Hao Tan on 11-12-26.
//  Copyright (c) 2011年 http://www.tanhao.me All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

@synthesize window = _window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    mvc = [[MainViewController alloc] initWithNibName:@"MainViewController" bundle:[NSBundle bundleForClass:[self class]]];
    [self.window.contentView addSubview:mvc.view];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag
{	
	if (!flag) 
    {
		[self.window makeKeyAndOrderFront:self];
	}
	return YES;
}

@end
