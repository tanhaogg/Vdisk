//
//  THVdiskManager.h
//  Vdisk
//
//  Created by Hao Tan on 11-12-27.
//  Copyright (c) 2011年 http://www.tanhao.me All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VdiskFile.h"

#define kNotification_SignIn          @"Notification_SignIn"
#define kNotification_Synchronous     @"Notification_Synchronous"
#define kNotification_Shared          @"kNotification_Shared"

#define kNotificationInfoKey_State    @"Notification_Key_State"
#define kNotificationInfoKey_Message  @"Notification_Key_Message"
#define kNotificationInfoKey_Content  @"Notification_Key_Content"
#define kNotificationInfoKey_Context  @"Notification_Key_Context"

#define kNotificationInfoValue_SynUp     @"NotificationInfoValue_SynUp"
#define kNotificationInfoValue_SynDown   @"NotificationInfoValue_SynDown"
#define kNotificationInfoValue_SynBegin  @"NotificationInfoValue_SynBegin"
#define kNotificationInfoValue_SynEnd    @"NotificationInfoValue_SynEnd"
#define kNotificationInfoValue_SharedOn  @"NotificationInfoValue_SharedOn"

@interface THVdiskManager : NSObject
{
    NSString *userToken;
    NSString *userDologID;
    NSTimer  *timer;
    
    NSMutableDictionary *tempNetFileDic;
    
    BOOL isDown;
    BOOL isUp;
}

+ (id)sharedManager;

- (void)signIn;
//自动同步
- (void)synchronousFilesAuto;
//向下同步
- (void)synchronousFilesDown;
//向上同步
- (void)synchronousFilesUp;
//分享文件
- (void)sharedFile:(VdiskFile *)file on:(BOOL)isOn;
//得到本地所有的文件
- (NSDictionary *)getLocalFileItem;
@end
