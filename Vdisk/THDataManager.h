//
//  THDataManager.h
//  Vdisk
//
//  Created by Hao Tan on 11-12-31.
//  Copyright (c) 2011年 http://www.tanhao.me All rights reserved.
//

#import <Foundation/Foundation.h>

#define kDataKey_DologID    @"dologid"
#define kDataKey_FileDic    @"LatestFileDic"

#define kDataKey_Account        @"user_account"
#define kDataKey_AccountType    @"user_accountType"
#define kDataKey_Password       @"user_password"
#define kDataKey_UserID         @"user_id"
#define kDataKey_UserPath       @"user_path"

#define kDataKey_Remenber   @"user_remenber"
#define kDataKey_AutoSyn    @"user_autoSyn"
#define kDataKey_AutoLogin  @"user_autoLogin"


@interface THDataManager : NSObject
{
    NSMutableDictionary *dictionary;
}

+ (id)sharedManager;

- (void)importWithObject:(id)value forKey:(id)key;
- (id)exportWithObjectForKey:(id)key;

@end
