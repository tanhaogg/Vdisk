//
//  MainViewController.m
//  Vdisk
//
//  Created by Hao Tan on 11-12-26.
//  Copyright (c) 2011年 http://www.tanhao.me All rights reserved.
//

#import "MainViewController.h"
#include <CommonCrypto/CommonHMAC.h>
#import "THVdiskManager.h"
#import "THDataManager.h"
#import "VdiskFile.h"
#import "THImageTextCell.h"

@interface MainViewController()
- (void)refreshUI;
@end

@implementation MainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        lwc = [[VdLoginWndController alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveSignInNotification:) name:kNotification_SignIn object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveSynNotification:) name:kNotification_Synchronous object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveSharedNotification:) name:kNotification_Shared object:nil];
        
        items = [[NSMutableArray alloc] init];
        
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        NSString *upImgPath = [bundle pathForResource:@"ImgUp" ofType:@"gif"];
        NSString *downImgPath = [bundle pathForResource:@"ImgDown" ofType:@"gif"];
        NSString *upStopImgPath = [bundle pathForResource:@"ImgUpStop" ofType:@"gif"];
        NSString *downStopImgPath = [bundle pathForResource:@"ImgDownStop" ofType:@"gif"];
        upAnimationImg = [[NSImage alloc] initWithContentsOfFile:upImgPath];
        downAnimationImg = [[NSImage alloc] initWithContentsOfFile:downImgPath];
        upStopImg = [[NSImage alloc] initWithContentsOfFile:upStopImgPath];
        downStopImg = [[NSImage alloc] initWithContentsOfFile:downStopImgPath];
    }
    
    return self;
}

- (void)awakeFromNib
{
    if (statusItem) 
    {
		[[NSStatusBar systemStatusBar] removeStatusItem:statusItem];
		statusItem = nil;
	}
    
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:29.0f];
    [statusItem setImage:[NSImage imageNamed:@"statusbar"]];
	[statusItem setAlternateImage:[NSImage imageNamed:@"statusbar"]];
	[statusItem setMenu:statusMenu];
	[statusItem setHighlightMode:YES];
    [statusItem setToolTip:@"微盘"];
    
    [upImgView setImage:upStopImg];
    [downImgView setImage:downStopImg];
    
    [THVdiskManager sharedManager];
    NSNumber *autoLoginObj = [[THDataManager sharedManager] exportWithObjectForKey:kDataKey_Remenber];
    if ([autoLoginObj boolValue])
    {
        [[THVdiskManager sharedManager] signIn];
    }
    [self refreshUI];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)refreshUI
{
    [refreshButton setHidden:YES];
    [loadingView   setHidden:NO];
    [loadingView   startAnimation:nil];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //refresh UI
        @autoreleasepool 
        {
            NSDictionary *allLocalFileDic = [[THVdiskManager sharedManager] getLocalFileItem];
            NSDictionary *allNetFileDic = [[THDataManager sharedManager] exportWithObjectForKey:kDataKey_FileDic];
            __block NSMutableArray *temItems = [[NSMutableArray alloc] init];
            for (VdiskFile *disk in [allLocalFileDic allValues])
            {
                VdiskFile *netDisk = [allNetFileDic objectForKey:disk.path];
                disk.errorCode = netDisk.errorCode;
                disk.ID = netDisk.ID;
                disk.sharedPageLink = netDisk.sharedPageLink;
                [temItems addObject:disk];
            }
            
            static VdiskFile * (^blocks)(VdiskFile *);
            blocks = ^(VdiskFile *context)
            {
                for (int i=(int)[temItems count]-1;i>=0;i--)
                {
                    @autoreleasepool
                    {
                        VdiskFile *disk = [temItems objectAtIndex:i];
                        NSString *absolutePath = [disk.path stringByDeletingLastPathComponent];
                        NSString *name = [disk.path lastPathComponent];            
                        if ([absolutePath isEqualToString:context.path])
                        {
                            [temItems removeObject:disk];
                            VdiskFile *child = blocks(disk);
                            child.name = name;
                            if (!context.children) 
                            {
                                context.children = [NSMutableArray array];
                            }
                            [context.children addObject:child];
                        }
                        if (i>[temItems count]-1) i = (int)[temItems count]-1;
                    }
                }
                return context; 
            };
            
            NSString *userPath = [[THDataManager sharedManager] exportWithObjectForKey:kDataKey_UserPath];
            VdiskFile *disk = [[VdiskFile alloc] init];
            disk.path = userPath;
            disk = blocks(disk);
            temItems = nil;
            NSArray *children = disk.children;
            
            [items performSelectorOnMainThread:@selector(removeAllObjects) withObject:nil waitUntilDone:NO];
            [items performSelectorOnMainThread:@selector(addObjectsFromArray:) withObject:children waitUntilDone:NO];
            [outlineView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
            
            [refreshButton setHidden:NO];
            [loadingView   setHidden:YES];
            [loadingView   stopAnimation:nil];
        }
    });
}

- (void)receiveSignInNotification:(NSNotification *)notify
{
    NSDictionary *info = [notify userInfo];
    NSNumber *stateObj = [info objectForKey:kNotificationInfoKey_State];
    
    if ([stateObj boolValue])
    {
        [upImgView setHidden:NO];
        [downImgView setHidden:NO];
    }else
    {
        [upImgView setHidden:YES];
        [downImgView setHidden:YES];
    }
}

- (void)receiveSynNotification:(NSNotification *)notify
{
    //[upImgView setAnimates:NO];
    //[downImgView setAnimates:NO];
    
    NSDictionary *info = [notify userInfo];
    NSString *stateStr = [info objectForKey:kNotificationInfoKey_State];
    NSString *messageStr = [info objectForKey:kNotificationInfoKey_Message];
    if ([stateStr isEqualToString:kNotificationInfoValue_SynUp])
    {
        if([messageStr isEqualToString:kNotificationInfoValue_SynBegin])
        {
            [upImgView setImage:upAnimationImg];
        }else
        {
            [upImgView setImage:upStopImg];
            [self refreshUI];
        }
    }
    if ([stateStr isEqualToString:kNotificationInfoValue_SynDown])
    {
        if([messageStr isEqualToString:kNotificationInfoValue_SynBegin])
        {
            [downImgView setImage:downAnimationImg];
        }else
        {
            [downImgView setImage:downStopImg];
            [self refreshUI];
        }
    }
    NSLog(@"%@",stateStr);
    NSLog(@"%@",messageStr);
}

- (void)receiveSharedNotification:(NSNotification *)notify
{
    NSDictionary *info = [notify userInfo];
    NSNumber *stateNumber = [info objectForKey:kNotificationInfoKey_State];
    NSNumber *sharedOnNumber = [info objectForKey:kNotificationInfoValue_SharedOn];
    NSString *messageStr = [info objectForKey:kNotificationInfoKey_Message];
    NSString *contentStr = [info objectForKey:kNotificationInfoKey_Content];
    VdiskFile *currentFile = [info objectForKey:kNotificationInfoKey_Context];
    
    [sharedFileTitleField setStringValue:currentFile.name];
    
    if ([sharedOnNumber boolValue])
    {
        if ([stateNumber intValue] == 0)
        {
            [sharedStateField setStringValue:@"成功分享"];
            [sharedStateField setTextColor:[NSColor blueColor]];
        }else
        {
            [sharedStateField setStringValue:@"无法分享"];
            [sharedStateField setTextColor:[NSColor redColor]];
        }
        
        [sharedMessageField setStringValue:messageStr];
        [sharedDownLinkField setStringValue:contentStr];
        
        [sharedDownLinkField setHidden:NO];
        [sharedDownLinkFieldTitle setHidden:NO];
        [sharedDownLinkFieldButton setHidden:NO];
    }else
    {
        if ([stateNumber intValue] == 0)
        {
            [sharedStateField setStringValue:@"成功取消分享"];
            [sharedStateField setTextColor:[NSColor blueColor]];
        }else
        {
            [sharedStateField setStringValue:@"取消分享失败"];
            [sharedStateField setTextColor:[NSColor redColor]];
        }
        
        [sharedMessageField setStringValue:messageStr];
        [sharedDownLinkField setStringValue:@""];
        
        [sharedDownLinkField setHidden:YES];
        [sharedDownLinkFieldTitle setHidden:YES];
        [sharedDownLinkFieldButton setHidden:YES];
    }
    
    NSDictionary *allNetFileDic = [[THDataManager sharedManager] exportWithObjectForKey:kDataKey_FileDic];
    VdiskFile *netDisk = [allNetFileDic objectForKey:currentFile.path];
    if (netDisk)
    {
        netDisk.sharedPageLink = contentStr;
    }
    [[THDataManager sharedManager] importWithObject:allNetFileDic forKey:kDataKey_FileDic];
    
    [NSApp beginSheet:sharedWindow
       modalForWindow:[self.view window]
        modalDelegate:self
       didEndSelector:nil
          contextInfo:nil];
}

- (void)popAlertView
{
    NSAlert *alert = [NSAlert alertWithMessageText:@"提示" defaultButton:@"明白" alternateButton:nil otherButton:nil informativeTextWithFormat:@"你还未登录！"];
    [alert runModal];
}

- (IBAction)synAutoClick:(id)sender
{
    if (upImgView.isHidden || downImgView.isHidden)
    {
        [self popAlertView];
        return;
    }
    
    [[THVdiskManager sharedManager] synchronousFilesAuto];
}

- (IBAction)synUpClick:(id)sender
{
    if (upImgView.isHidden || downImgView.isHidden)
    {
        [self popAlertView];
        return;
    }
    
    [[THVdiskManager sharedManager] synchronousFilesUp];
}

- (IBAction)synDownClick:(id)sender
{
    if (upImgView.isHidden || downImgView.isHidden)
    {
        [self popAlertView];
        return;
    }
    
    [[THVdiskManager sharedManager] synchronousFilesDown];
}

- (IBAction)signInClick:(id)sender
{
    [NSApp beginSheet:[lwc window]
       modalForWindow:[self.view window]
        modalDelegate:self
       didEndSelector:nil
          contextInfo:nil];
    [lwc setUp];
}

- (IBAction)logoClick:(id)sender
{    
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.tanhao.me"]];
}

- (IBAction)refreshClick:(id)sender
{
    [self refreshUI];
}

- (IBAction)openFileClick:(id)sender
{
    NSInteger index = [outlineView clickedRow];
    VdiskFile *disk = [outlineView itemAtRow:index];
    
    NSString *paranetPath = [disk.path stringByDeletingLastPathComponent];
    [[NSWorkspace sharedWorkspace] selectFile:disk.path inFileViewerRootedAtPath:paranetPath];
}

- (IBAction)aboutClick:(id)sender
{
    [NSApp orderFrontStandardAboutPanel:nil];
}

- (IBAction)supportClick:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.tanhao.me"]];
}

- (IBAction)showClick:(id)sender
{
    [NSApp activateIgnoringOtherApps:YES];
    [self.view.window makeKeyAndOrderFront:nil];
    [self.view.window performSelector:@selector(orderFront:) withObject:nil afterDelay:0.1];
}

- (IBAction)quitClick:(id)sender
{
    [NSApp terminate:nil];
}

- (IBAction)sharedCopyClick:(id)sender
{
    if ([[sharedDownLinkField stringValue] length] > 0)
    {
        NSPasteboard *pasteBoard = [NSPasteboard generalPasteboard];
        [pasteBoard clearContents];
        [pasteBoard setString:[sharedDownLinkField stringValue] forType:NSPasteboardTypeString];
    }
}

- (IBAction)sharedCloseClick:(id)sender
{
    [NSApp endSheet:sharedWindow];
    [sharedWindow orderOut:nil];
}

#pragma mark NSOutlineViewDataSource

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if (item == nil)
    {
        NSInteger count = [items count];
        return count;
    }
    else
    {
        NSInteger count = [((VdiskFile *)item).children count];
        return count;
    }
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    if (item == nil)
    {
        return [items objectAtIndex:index];
    }
    else
    {
        return [((VdiskFile *)item).children objectAtIndex:index];
    }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldCollapseItem:(id)item
{
    return YES;
}
// Returns a Boolean value that indicates whether the a given item is expandable
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    VdiskFile *disk = (VdiskFile *)item;
    if (!disk.isDirectory || [[NSWorkspace sharedWorkspace] isFilePackageAtPath:disk.path])
    {
        return NO;
    }
    
    if ([disk.children count] > 0)
    {
        return YES;
    }else
    {
        return NO;
    }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldShowCellExpansionForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    return NO;
}

/* NOTE: this method is optional for the View Based OutlineView.
 */
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    VdiskFile *disk = (VdiskFile *)item;
    if (tableColumn == nameColumn)
    {
        return [disk name];
    }
    if (tableColumn == typeColumn)
    {
        return [disk fileType];
    }
    if (tableColumn == stateColumn)
    {
        if (disk.errorCode && [disk.errorCode intValue] == 0)
        {
            BOOL sucess = YES;
            NSMutableArray *allChildren = [NSMutableArray arrayWithArray:disk.children];
            for (int i=0; i<[allChildren count]; i++)
            {
                VdiskFile *childDisk = [allChildren objectAtIndex:i];
                if ([childDisk.children count] != 0)
                {
                    [allChildren addObjectsFromArray:childDisk.children];
                }
                
                if (!childDisk.errorCode || [childDisk.errorCode intValue] != 0)
                {
                    sucess = NO;
                    break;
                }
            }
            
            if (sucess)
            {
                NSDictionary *attributes = [NSDictionary dictionaryWithObject:[NSColor blueColor] forKey:NSForegroundColorAttributeName];
                NSAttributedString *resultString = [[NSAttributedString alloc] initWithString:@"已同步" attributes:attributes];
                return resultString;
            }else
            {
                NSDictionary *attributes = [NSDictionary dictionaryWithObject:[NSColor orangeColor] forKey:NSForegroundColorAttributeName];
                NSAttributedString *resultString = [[NSAttributedString alloc] initWithString:@"已同步" attributes:attributes];
                return resultString;
            }
        }else
        {
            NSDictionary *attributes = [NSDictionary dictionaryWithObject:[NSColor redColor] forKey:NSForegroundColorAttributeName];
            NSAttributedString *resultString = [[NSAttributedString alloc] initWithString:@"未同步" attributes:attributes];
            return resultString;
        }
    }
    return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    return NO;
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    VdiskFile *disk = (VdiskFile *)item;
    if (tableColumn == nameColumn)
    {
        NSImage *iconImg = [[NSWorkspace sharedWorkspace] iconForFile:disk.path];
        [iconImg setSize:NSMakeSize(15, 15)];
        //[(McImageTextCell*)cell setImage:iconImg];
        //[(McImageTextCell*)cell setTitle:disk.name];
        [(THImageTextCell*)cell setImage:iconImg];
        [(THImageTextCell*)cell setTitle:disk.name];
    }
}

#pragma mark -
#pragma mark NSOutlineViewDelegate

- (BOOL)selectionShouldChangeInOutlineView:(NSOutlineView *)outlineView
{
    return YES;
}

//- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
//{
//    if ([item isMemberOfClass:[McBaseNode class]])
//    {
//        return NO;
//    }
//    
//    if ([delegate respondsToSelector:@selector(categoryView:clickPath:ofItem:)])
//    {
//        [delegate categoryView:self clickPath:[(McChildNode *)item indexPath] ofItem:item];
//    }
//    return YES;
//}

#pragma mark -
#pragma mark NSMenuDelegate

- (void)menuWillOpen:(NSMenu *)menu
{
    NSMenuItem *sharedItem = [menu itemWithTag:110];
    if (!sharedItem)
    {
        sharedItem = [[NSMenuItem alloc] initWithTitle:@"分享文件" action:@selector(sharedClick:) keyEquivalent:@""];
        [sharedItem setTarget:self];
        [sharedItem setTag:110];
        [menu addItem:sharedItem];
    }
    NSMenuItem *sharedCopyItem = [menu itemWithTag:111];
    if (!sharedCopyItem)
    {
        sharedCopyItem = [[NSMenuItem alloc] initWithTitle:@"拷贝分享地址" action:@selector(copyLinkClick:) keyEquivalent:@""];
        [sharedCopyItem setTarget:self];
        [sharedCopyItem setTag:111];
        [menu addItem:sharedCopyItem];
    }
    
    for (NSMenuItem *item in [menu itemArray])
        [item setHidden:YES];
    NSInteger index = [outlineView clickedRow];
    if (index == -1) return;
    for (NSMenuItem *item in [menu itemArray])
        [item setHidden:NO];
    
    VdiskFile *disk = [outlineView itemAtRow:index];
    if (disk.isDirectory || !(disk.errorCode && [disk.errorCode intValue]==0) ) 
    {
        [sharedItem setHidden:YES];
    }
    
    if ([disk.sharedPageLink length] > 0)
    {
        [sharedItem setTitle:@"取消分享"];
        [sharedCopyItem setHidden:NO];
    }else
    {
        [sharedItem setTitle:@"分享文件"];
        [sharedCopyItem setHidden:YES];
    }
}

- (void)sharedClick:(id)sender
{
    NSMenuItem *sharedItem = (NSMenuItem *)sender;
    BOOL on = NO;
    if ([sharedItem.title isEqualToString:@"分享文件"])
    {
        on = YES;
    }else
    {
        on = NO;
    }
    
    NSInteger index = [outlineView clickedRow];
    if (index == -1) return;    
    VdiskFile *disk = [outlineView itemAtRow:index];
    [[THVdiskManager sharedManager] sharedFile:disk on:on];
}

- (void)copyLinkClick:(id)sender
{
    NSInteger index = [outlineView clickedRow];
    if (index == -1) return;    
    VdiskFile *disk = [outlineView itemAtRow:index];
    if ([disk.sharedPageLink length] > 0)
    {
        NSPasteboard *pasteBoard = [NSPasteboard generalPasteboard];
        [pasteBoard clearContents];
        [pasteBoard setString:disk.sharedPageLink forType:NSPasteboardTypeString];
    }
}

@end
