//
//  VdLoginWndController.m
//  Vdisk
//
//  Created by Hao Tan on 12-1-2.
//  Copyright (c) 2012年 http://tanhao.sinaapp.com/?p=5. All rights reserved.
//

#import "VdLoginWndController.h"
#import "THDataManager.h"
#import "THVdiskManager.h"

@implementation VdLoginWndController

- (id)init
{
    self = [super initWithWindowNibName:@"VdLoginWndController"];
    if (self)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveSignInNotification:) name:kNotification_SignIn object:nil];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setUp
{
    //关于用户
    NSNumber *remenberObj = [[THDataManager sharedManager] exportWithObjectForKey:kDataKey_Remenber];
    if (!remenberObj)
    {
        remenberObj = [NSNumber numberWithBool:YES];
        [[THDataManager sharedManager] importWithObject:remenberObj forKey:kDataKey_Remenber];
    }
    [remenberButton setState:[remenberObj boolValue]?NSOnState:NSOffState];
    if ([remenberObj boolValue])
    {
        NSString *userAccount = [[THDataManager sharedManager] exportWithObjectForKey:kDataKey_Account];
        if (userAccount) [userAccountField setStringValue:userAccount];
        NSString *userPassword = [[THDataManager sharedManager] exportWithObjectForKey:kDataKey_Password];
        if (userPassword) [userPasswordField setStringValue:userPassword];
    }
    //帐号类型
    NSNumber *accountTypeObj = [[THDataManager sharedManager] exportWithObjectForKey:kDataKey_AccountType];
    if (!accountTypeObj)
    {
        accountTypeObj = [NSNumber numberWithInteger:0];
        [[THDataManager sharedManager] importWithObject:accountTypeObj forKey:kDataKey_AccountType];
    }
    [accountTypeButton selectItemAtIndex:[accountTypeObj integerValue]]; 
    
    //自动同步
    NSNumber *autoSynObj = [[THDataManager sharedManager] exportWithObjectForKey:kDataKey_AutoSyn];
    if (!autoSynObj)
    {
        autoSynObj = [NSNumber numberWithBool:YES];
        [[THDataManager sharedManager] importWithObject:autoSynObj forKey:kDataKey_AutoSyn];
    }
    [autoSysButton setState:[autoSynObj boolValue]?NSOnState:NSOffState];
    
    //自动登录
    NSNumber *autoLoginObj = [[THDataManager sharedManager] exportWithObjectForKey:kDataKey_AutoLogin];
    if (!autoLoginObj)
    {
        autoLoginObj = [NSNumber numberWithBool:YES];
        [[THDataManager sharedManager] importWithObject:autoLoginObj forKey:kDataKey_AutoLogin];
    }
    [autoLoginButton setState:[autoLoginObj boolValue]?NSOnState:NSOffState];
    
    //用户路径
    NSString *userPath = [[THDataManager sharedManager] exportWithObjectForKey:kDataKey_UserPath];
    if (!userPath)
    {
        NSArray *paths=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentDirectory=[[paths objectAtIndex:0] stringByAppendingPathComponent:@"Vdisk"];
        userPath = [[NSString alloc] initWithString:documentDirectory];
        if (![[NSFileManager defaultManager] isExecutableFileAtPath:userPath])
        {
            [[NSFileManager defaultManager] createDirectoryAtPath:userPath withIntermediateDirectories:YES attributes:nil error:NULL];
        }
        [[THDataManager sharedManager] importWithObject:userPath forKey:kDataKey_UserPath];
    }
    [userPathControl setURL:[NSURL fileURLWithPath:userPath]];
    userPathControl.delegate = self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    [self setUp];
}

- (void)setAllControllerEnabled:(BOOL)value
{
    [userAccountField setEnabled:value];
    [userPasswordField setEnabled:value];
    [accountTypeButton setEnabled:value];
    [remenberButton setEnabled:value];
    [autoLoginButton setEnabled:value];
    [autoSysButton setEnabled:value];
}

- (void)receiveSignInNotification:(NSNotification *)notify
{
    [self setAllControllerEnabled:YES];
    [stateLabel setHidden:NO];
    [stateLoadingView stopAnimation:nil];
    [stateLoadingView setHidden:YES];
    
    NSDictionary *info = [notify userInfo];
    NSNumber *stateObj = [info objectForKey:kNotificationInfoKey_State];
    NSString *messageStr = [info objectForKey:kNotificationInfoKey_Message];
    [stateLabel setStringValue:messageStr];
    
    if ([stateObj boolValue])
    {
        [stateLabel setTextColor:[NSColor blueColor]];
        
        [self performSelector:@selector(closeClick:) withObject:nil afterDelay:1.0];
    }else
    {
        [stateLabel setTextColor:[NSColor redColor]];
    }
}

- (IBAction)loginClick:(id)sender
{
    NSString *userPath = [[THDataManager sharedManager] exportWithObjectForKey:kDataKey_UserPath];    
    NSURL *clickUrl = [userPathControl URL];
    
    if (![userPath isEqualToString:clickUrl.path])
    {
        //判断权限
        if (![[NSFileManager defaultManager] isWritableFileAtPath:clickUrl.path] 
            && ![[NSFileManager defaultManager] isDeletableFileAtPath:clickUrl.path]
            && ![[NSFileManager defaultManager] isExecutableFileAtPath:clickUrl.path])
        {
            NSAlert *alert = [NSAlert alertWithMessageText:@"提示" defaultButton:@"明白" alternateButton:nil otherButton:nil informativeTextWithFormat:@"你对此目录的权限不足！"];
            [alert runModal];
            return;
        }
        
        //判断是否为空
        NSArray *subPaths = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:clickUrl.path error:NULL];
        if ([subPaths count] > 1)
        {
            NSAlert *alert = [NSAlert alertWithMessageText:@"提示" defaultButton:@"明白" alternateButton:nil otherButton:nil informativeTextWithFormat:@"新设置的目录必须为空！"];
            [alert runModal];
            return;
        }
        
        [[THDataManager sharedManager] importWithObject:@"" forKey:kDataKey_DologID];
        [[THDataManager sharedManager] importWithObject:clickUrl.path forKey:kDataKey_UserPath];
    }
    
    [stateLabel setHidden:YES];
    [stateLoadingView startAnimation:nil];
    [stateLoadingView setHidden:NO];
    
    [[THDataManager sharedManager] importWithObject:userAccountField.stringValue forKey:kDataKey_Account];
    [[THDataManager sharedManager] importWithObject:userPasswordField.stringValue forKey:kDataKey_Password];
    
    [[THVdiskManager sharedManager] signIn];
    [self setAllControllerEnabled:NO];
}

- (IBAction)closeClick:(id)sender
{
    //[self hiddenAllController];
    [NSApp endSheet:self.window];
    [self.window orderOut:nil];
}

- (IBAction)acountTypeClick:(id)sender
{
    NSNumber *accountTypeObj = [NSNumber numberWithInteger:accountTypeButton.indexOfSelectedItem];
    [[THDataManager sharedManager] importWithObject:accountTypeObj forKey:kDataKey_AccountType];
}

- (IBAction)remenberClick:(id)sender
{
    NSNumber *remenberObj = [NSNumber numberWithBool:remenberButton.state==NSOnState?YES:NO];
    [[THDataManager sharedManager] importWithObject:remenberObj forKey:kDataKey_Remenber];
    if ([remenberObj boolValue])
    {
        [[THDataManager sharedManager] importWithObject:userAccountField.stringValue forKey:kDataKey_Account];
        [[THDataManager sharedManager] importWithObject:userPasswordField.stringValue forKey:kDataKey_Password];
    }else
    {
        [[THDataManager sharedManager] importWithObject:nil forKey:kDataKey_Account];
        [[THDataManager sharedManager] importWithObject:nil forKey:kDataKey_Password];
    }
}

- (IBAction)autoLoginClick:(id)sender
{
    NSNumber *autoLoginObj = [NSNumber numberWithBool:autoLoginButton.state==NSOnState?YES:NO];
    [[THDataManager sharedManager] importWithObject:autoLoginObj forKey:kDataKey_AutoLogin];
}

- (IBAction)autoSynClick:(id)sender
{
    NSNumber *autoSynObj = [NSNumber numberWithBool:autoSysButton.state==NSOnState?YES:NO];
    [[THDataManager sharedManager] importWithObject:autoSynObj forKey:kDataKey_AutoSyn];
}

#pragma mark -
#pragma mark NSPathControlDelegate

- (void)pathControl:(NSPathControl *)pathControl willDisplayOpenPanel:(NSOpenPanel *)openPanel
{
    [openPanel setCanChooseFiles:NO];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setCanCreateDirectories:YES];
}

@end
