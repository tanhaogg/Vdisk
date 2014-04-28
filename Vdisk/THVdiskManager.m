//
//  THVdiskManager.m
//  Vdisk
//
//  Created by Hao Tan on 11-12-27.
//  Copyright (c) 2011年 http://www.tanhao.me All rights reserved.
//

#import "THVdiskManager.h"
#import "MKServiceManager.h"
#import "THDataManager.h"
#import "CJSONDeserializer.h"
#include <CommonCrypto/CommonHMAC.h>
#include "FileMD5Hash.h"
#import "Utility.h"
#import "sha1.h"

static THVdiskManager *instance = nil;
static const NSString *appkey    = @"1172890330";
static const NSString *appsecret = @"5dd63167c57e68297222b9d98b5bf427";

#define kRequestContextSignIn        @"get_token"
#define kRequestContextKeepToken     @"keep_token"
#define kRequestContextGetList       @"getlist"
#define kRequestContextGetFileInfo   @"getFileInfo"

@interface VdiskNotification : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSDictionary *info;
+ (id)contextWithName:(NSString *)aName info:(NSDictionary *)info;
@end

@implementation VdiskNotification
@synthesize name;
@synthesize info;

+ (id)contextWithName:(NSString *)aName info:(NSDictionary *)info
{
    __autoreleasing VdiskNotification *context = [[VdiskNotification alloc] init];
    context.name = aName;
    context.info = info;
    return context;
}

@end


@interface THVdiskManager()<MKServiceManagerDelegate>
@end

@implementation THVdiskManager

+ (id)sharedManager
{
    if (!instance)
    {
        instance = [[THVdiskManager alloc] init];
    }
    return instance;
}

- (id)init
{
    self = [super init];
    if (self)
    {
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
    }
    return self;
}

- (void)dealloc
{
    [timer invalidate];
}

#pragma mark -
#pragma mark CustomMethod

- (void)postNotificationWithInfo:(VdiskNotification *)notify
{
    [[NSNotificationCenter defaultCenter] postNotificationName:notify.name object:nil userInfo:notify.info];
}

- (void)signIn
{
    NSString *userAcount = [[THDataManager sharedManager] exportWithObjectForKey:kDataKey_Account];
    NSString *userPassword = [[THDataManager sharedManager] exportWithObjectForKey:kDataKey_Password];
    NSNumber *accountTypeObj = [[THDataManager sharedManager] exportWithObjectForKey:kDataKey_AccountType];
    
    NSString *appTypeStr = nil;
    if ([accountTypeObj integerValue] == 0)
    {
        appTypeStr = @"local";
    }else
    {
        appTypeStr = @"sinat";
    }
    
    time_t   atime = time((time_t*)NULL);
    NSString *timeStr = [NSString stringWithFormat:@"%ld",atime];
    NSString *signStr = [NSString stringWithFormat:@"account=%@&appkey=%@&password=%@&time=%@",userAcount,appkey,userPassword,timeStr];
    
    const char *cKey = [appsecret cStringUsingEncoding:NSUTF8StringEncoding];
    const char *cData = [signStr cStringUsingEncoding:NSUTF8StringEncoding];
    
    unsigned char cHMAC[CC_SHA256_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA256, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    
    //Base64 string
    //NSData *HMAC = [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];
    //NSString *hash = [[NSString alloc] initWithData:HMAC encoding:NSASCIIStringEncoding];
    //NSString *hash = [Utility encodeBase64WithData:HMAC];
    //hash = [HMAC base64EncodedString];
    
    NSMutableString* hash = [NSMutableString   stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++)
    {
        [hash appendFormat:@"%02x", cHMAC[i]];
    }    
    
    NSDictionary *postDic = [NSDictionary dictionaryWithObjectsAndKeys:
                             userAcount,@"account", 
                             appkey,@"appkey",
                             userPassword,@"password",
                             timeStr,@"time",
                             hash,@"signature",
                             appTypeStr,@"app_type",
                             nil];
    NSURL *url = [NSURL URLWithString:@"http://openapi.vdisk.me/?m=auth&a=get_token"];
    [[MKServiceManager sharedManager] uploadWithURL:url delegate:self postDic:postDic context:kRequestContextSignIn];
}

- (void)keepToken
{
    if (userToken)
    {
        NSDictionary *postDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                 userToken,@"token",nil];
        NSURL *url = [NSURL URLWithString:@"http://openapi.vdisk.me/?m=user&a=keep_token"];
        [[MKServiceManager sharedManager] uploadWithURL:url delegate:self postDic:postDic context:kRequestContextKeepToken];
    }else
    {
        [self signIn];
    }
}

- (NSDictionary *)getListByDirId:(NSString *)dirId
{
    if (userToken)
    {
        NSDictionary *postDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                 userToken,@"token",
                                 dirId,@"dir_id",nil];
        NSURL *url = [NSURL URLWithString:@"http://openapi.vdisk.me/?m=dir&a=getlist"];
        NSData *receiveData = [[MKServiceManager sharedManager] uploadWithURL:url postDic:postDic];
        NSDictionary *receiveDic = [[CJSONDeserializer deserializer] deserializeAsDictionary:receiveData error:NULL];
        return receiveDic;
    }
    return nil;
}

- (NSDictionary *)getFileInfoByFid:(NSString *)fid
{
    if (userToken)
    {
        NSDictionary *postDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                 userToken,@"token",
                                 fid,@"fid",nil];
        NSURL *url = [NSURL URLWithString:@"http://openapi.vdisk.me/?m=file&a=get_file_info"];
        NSData *receiveData = [[MKServiceManager sharedManager] uploadWithURL:url postDic:postDic];
        NSDictionary *receiveDic = [[CJSONDeserializer deserializer] deserializeAsDictionary:receiveData error:NULL];
        return receiveDic;
    }
    return nil;
}

- (NSDictionary *)getLocalFileItem
{
    NSString *userPath = [[THDataManager sharedManager] exportWithObjectForKey:kDataKey_UserPath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSMutableArray *resultArray = [NSMutableArray array];
    NSArray  *subPaths = [fileManager subpathsAtPath:userPath];
    for (NSString *subPath in subPaths)
    {
        NSString *name = [subPath lastPathComponent];
        if ([name isEqualToString:@".DS_Store"])
        {
            continue;
        }
        NSString *fullPath = [userPath stringByAppendingPathComponent:subPath];
        
        BOOL isDirectory;
        BOOL isExists  = [fileManager fileExistsAtPath:fullPath isDirectory:&isDirectory];
        if (isExists)
        {
            VdiskFile *disk = [[VdiskFile alloc] init];
            disk.isDirectory = isDirectory;
            disk.path = fullPath;
            disk.name = name;
            
            MDItemRef itemRef = MDItemCreate(NULL, (__bridge CFStringRef)disk.path);
            disk.fileType = (__bridge_transfer NSString*)MDItemCopyAttribute(itemRef,kMDItemKind);
            CFRelease(itemRef);
            
            if (!isDirectory)
            {
                NSString *localSha1 = (__bridge_transfer NSString*)FileSha1HashCreateWithPath((__bridge CFStringRef)fullPath, FileHashDefaultChunkSizeForReadingData);
                disk.sha1 = localSha1;
            }
            [resultArray addObject:disk];
        }
    }
    
    
    
    
//    NSMutableArray *resultArray = [NSMutableArray array];
//    // search item
//    NSFileManager *fileManager = [NSFileManager defaultManager];
//    NSArray *subPaths = [fileManager contentsOfDirectoryAtPath:userPath error:nil];
//    NSMutableArray *searchPaths = [NSMutableArray arrayWithArray:subPaths];
//    
//    for (int i=0; i<[searchPaths count]; i++)
//    {
//        NSString *fullPath = [userPath stringByAppendingPathComponent:[searchPaths objectAtIndex:i]];
//        BOOL isDirectory;
//        BOOL isExists  = [fileManager fileExistsAtPath:fullPath isDirectory:&isDirectory];
//        if (isExists)
//        {
//            VdiskFile *disk = [[VdiskFile alloc] init];
//            disk.isDirectory = isDirectory;
//            disk.path = fullPath;
//            if (!isDirectory)
//            {
//                NSString *localSha1 = (__bridge NSString*)FileSha1HashCreateWithPath((__bridge CFStringRef)fullPath, FileHashDefaultChunkSizeForReadingData);
//                disk.sha1 = localSha1;
//            }
//            [resultArray addObject:disk];
//            if (isDirectory)
//            {
//                NSArray *subSearchPaths = [fileManager contentsOfDirectoryAtPath:fullPath error:nil];
//                for (NSString *filePath in subSearchPaths)
//                {
//                    NSString *subFulPath = [[searchPaths objectAtIndex:i] stringByAppendingPathComponent:filePath];
//                    [searchPaths addObject:subFulPath];
//                }
//            }
//        }
//    }
    
    NSMutableDictionary *resultDic = [NSMutableDictionary dictionaryWithCapacity:[resultArray count]];
    for (VdiskFile *disk in resultArray)
    {
        [resultDic setObject:disk forKey:disk.path];
    }
    return resultDic;
}

- (void)receiveVdiskItem:(VdiskFile *)disk
{
    NSString *userPath = [[THDataManager sharedManager] exportWithObjectForKey:kDataKey_UserPath];
    
    NSDictionary *netFileDic =[[THDataManager sharedManager] exportWithObjectForKey:kDataKey_FileDic];
    if (!netFileDic) netFileDic = [NSDictionary dictionary];
    NSMutableDictionary *newNetFileDic = [NSMutableDictionary dictionaryWithDictionary:netFileDic];
    if ([disk.path rangeOfString:userPath].location == NSNotFound)
        disk.path = [userPath stringByAppendingPathComponent:disk.path];
    [newNetFileDic setObject:disk forKey:disk.path];
    
    if (disk.dologid)
    {
        userDologID = disk.dologid;
        //[[THDataManager sharedManager] importWithObject:userDologID forKey:kDataKey_DologID];
    }
    
    [tempNetFileDic setObject:disk forKey:disk.path];
    
    //[[THDataManager sharedManager] importWithObject:newNetFileDic forKey:kDataKey_FileDic];
}

//自动同步
- (void)synchronousFilesAuto
{
    if (isDown || isUp || !userToken) return;
    
    NSString *userPath = [[THDataManager sharedManager] exportWithObjectForKey:kDataKey_UserPath];
    NSString *localDologID = [[THDataManager sharedManager] exportWithObjectForKey:kDataKey_DologID];
    //dologid与网上相同,并且本地目录存在，则需要上传，否则需要下载
    if ([localDologID isEqualToString:userDologID] && [[NSFileManager defaultManager] isExecutableFileAtPath:userPath])
        [self synchronousFilesUp];
    else
        [self synchronousFilesDown];
}

//向下同步
- (void)synchronousFilesDown
{
    if (isDown || isUp || !userToken) return;
    
    static BOOL (^blocks)(VdiskFile *);
    blocks = ^(VdiskFile *context)
    {
        BOOL sucess = YES;
        if(context.isDirectory)
        {
            NSDictionary *receiveDic = [self getListByDirId:context.ID];
            if (!receiveDic) 
                return NO;
            NSNumber *errorCode = [receiveDic objectForKey:@"err_code"];
            NSString *dologidStr = [receiveDic objectForKey:@"dologid"];
            if ([errorCode intValue] == 900) 
            {
                sleep(10);
                return blocks(context);
            }
            if ([errorCode intValue] != 0) 
                return NO;
            NSArray *dirListArr = [[receiveDic objectForKey:@"data"] objectForKey:@"list"];
            for (NSDictionary *dirDic in dirListArr)
            {
                
                NSString *urlStr = [dirDic objectForKey:@"url"];
                NSString *IDStr = [dirDic objectForKey:@"id"];
                NSString *nameStr = [dirDic objectForKey:@"name"];
                 //如果有Url，则表示是文件
                if (urlStr && IDStr)
                {
                    VdiskFile *disk = [[VdiskFile alloc] init];
                    disk.isDirectory = NO;
                    disk.path = context.path;
                    disk.ID = IDStr;
                    sucess &= blocks(disk);
                }
                //否则，如果是文件夹
                else if (nameStr && IDStr)
                {
                    NSString *path = [context.path stringByAppendingPathComponent:nameStr];
                    NSFileManager *fileManager = [NSFileManager defaultManager];
                    if (![fileManager fileExistsAtPath:path])
                        [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:NULL];
                    VdiskFile *disk = [[VdiskFile alloc] init];
                    disk.errorCode = errorCode;
                    disk.dologid = dologidStr;
                    disk.isDirectory = YES;
                    disk.path = path;
                    disk.ID = IDStr;
                    sucess &= blocks(disk);
                    
                    [self performSelectorOnMainThread:@selector(receiveVdiskItem:) withObject:disk waitUntilDone:YES];
                }
            }
        }else
        {
            NSDictionary *receiveDic = [self getFileInfoByFid:context.ID];
            if (!receiveDic) 
                return NO;
            NSNumber *errorCode = [receiveDic objectForKey:@"err_code"];
            if ([errorCode intValue] == 900) 
            {
                sleep(10);
                return blocks(context);
            }
            if ([errorCode intValue] != 0) 
                return NO;
            receiveDic = [receiveDic objectForKey:@"data"];
            NSString *netMd5 = [receiveDic objectForKey:@"md5"];
            NSString *sha1Str = [receiveDic objectForKey:@"sha1"];
            NSString *nameStr = [receiveDic objectForKey:@"name"];
            NSString *downLinkStr = [receiveDic objectForKey:@"s3_url"];
            NSString *dologidStr = [receiveDic objectForKey:@"dologid"];
            NSString *path = [context.path stringByAppendingPathComponent:nameStr];
            NSString *localMd5 = (__bridge_transfer NSString*)FileMD5HashCreateWithPath((__bridge CFStringRef)path, FileHashDefaultChunkSizeForReadingData);
            if (nameStr && downLinkStr && ![netMd5 isEqualToString:localMd5])
            {
                NSFileManager *fileManager = [NSFileManager defaultManager];
                if (![fileManager fileExistsAtPath:context.path])
                    [fileManager createDirectoryAtPath:context.path withIntermediateDirectories:YES attributes:nil error:NULL];
                NSData *data = [[MKServiceManager sharedManager] downloadWithURL:[NSURL URLWithString:downLinkStr]];
                NSString *dataMd5 = [Utility md5ForData:data];
                if (![dataMd5 isEqualToString:netMd5]) 
                    return NO;
                if (data) 
                    [data writeToFile:path atomically:YES];
                else 
                    return NO;
            }
            
            VdiskFile *disk = [[VdiskFile alloc] init];
            disk.errorCode = errorCode;
            disk.dologid = dologidStr;
            disk.sha1 = sha1Str;
            disk.isDirectory = NO;
            disk.path = path;
            disk.ID = context.ID;
            [self performSelectorOnMainThread:@selector(receiveVdiskItem:) withObject:disk waitUntilDone:YES];
        }
        return sucess;
    };
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        isDown = YES;
        
        VdiskNotification *notify = [[VdiskNotification alloc] init];
        notify.name = kNotification_Synchronous;
        NSMutableDictionary *info = [NSMutableDictionary dictionaryWithCapacity:2];
        notify.info = info;
        [info setObject:kNotificationInfoValue_SynDown forKey:kNotificationInfoKey_State];
        [info setObject:kNotificationInfoValue_SynBegin forKey:kNotificationInfoKey_Message];
        [self performSelectorOnMainThread:@selector(postNotificationWithInfo:) withObject:notify waitUntilDone:NO];
        
        NSDictionary *localFileDic = [self getLocalFileItem];
        NSDictionary *netFileDic =[[THDataManager sharedManager] exportWithObjectForKey:kDataKey_FileDic];
//        NSMutableDictionary *newNetFileDic = [NSMutableDictionary dictionaryWithDictionary:netFileDic];
//        for (VdiskFile *netDick in [netFileDic allValues])
//        {
//            //把能够恢复的数据先清空(上传失败的元素不能恢复，故不清理)
//            if ([netDick.errorCode intValue] == 0)
//            {
//                [newNetFileDic removeObjectForKey:netDick.path];
//            }
//            //本地已经都不存在了，那也可以清理
//            else if (![[NSFileManager defaultManager] isExecutableFileAtPath:netDick.path])
//            {
//                [newNetFileDic removeObjectForKey:netDick.path];
//            }
//        }
//        //开始向下同步之前，先清理本地对网络信息的保存
//        [[THDataManager sharedManager] importWithObject:newNetFileDic forKey:kDataKey_FileDic];
        
        tempNetFileDic = [[NSMutableDictionary alloc] init];
        for (VdiskFile *netDisk in [netFileDic allValues])
        {
            //本地仍旧存在的，且不能上传成功的文件需要保留
            if ([netDisk.errorCode intValue] != 0 && [[NSFileManager defaultManager] isExecutableFileAtPath:netDisk.path])
            {
                [tempNetFileDic setObject:netDisk forKey:netDisk.path];
            }
        }
        
        NSString *userPath = [[THDataManager sharedManager] exportWithObjectForKey:kDataKey_UserPath];
        
        VdiskFile *disk = [[VdiskFile alloc] init];
        disk.isDirectory = YES;
        disk.path = userPath;
        disk.ID = @"0";
        disk.isDirectory = YES;
        BOOL sucess = blocks(disk);
        if (sucess)
        {
            NSLog(@"sucess");
            //如果本地存在，而网络上不存在了，则应该删除
            for (VdiskFile *localDisk in [localFileDic allValues])
            {
                VdiskFile *netDisk = [tempNetFileDic objectForKey:localDisk.path];
                if (!netDisk)
                {
                    [[NSFileManager defaultManager] removeItemAtPath:localDisk.path error:NULL];
                }
            }
            
            [[THDataManager sharedManager] importWithObject:userDologID forKey:kDataKey_DologID];
            [[THDataManager sharedManager] importWithObject:tempNetFileDic forKey:kDataKey_FileDic];
        }
        
        [info setObject:kNotificationInfoValue_SynEnd forKey:kNotificationInfoKey_Message];
        [self performSelectorOnMainThread:@selector(postNotificationWithInfo:) withObject:notify waitUntilDone:NO];
        
        isDown = NO;
    });
}

//向上同步
- (void)synchronousFilesUp
{
    if (isDown || isUp || !userToken) return;
    
    static VdiskFile* (^blocks)(VdiskFile *);
    blocks = ^(VdiskFile *context)
    {
        if (context.isDirectory)
        {
            //如果需要删除
            if (context.isDelete)
            {
                NSDictionary *postDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                         userToken,@"token",
                                         context.ID,@"dir_id",nil];
                NSURL *url = [NSURL URLWithString:@"http://openapi.vdisk.me/?m=dir&a=delete_dir"];
                NSData *receiveData = [[MKServiceManager sharedManager] uploadWithURL:url postDic:postDic];
                NSDictionary *receiveDic = [[CJSONDeserializer deserializer] deserializeAsDictionary:receiveData error:NULL];
                if (!receiveDic) return (VdiskFile *)nil;
                NSNumber *errorCode = [receiveDic objectForKey:@"err_code"];
                NSString *dologidStr = [receiveDic objectForKey:@"dologid"];
                if ([errorCode intValue] == 0 || [errorCode intValue] == 2)
                {
                    context.dologid = dologidStr;
                    return context;
                }
                else if ([errorCode intValue] == 900)
                {
                    sleep(10);
                    return blocks(context);
                }else
                {
                    return blocks(context);
                }
            }
            
            //先查看本地是否有保存该目录的信息
            NSDictionary *netFileDic =[[THDataManager sharedManager] exportWithObjectForKey:kDataKey_FileDic];
            VdiskFile *netDisk = [netFileDic objectForKey:context.path];
            if (netDisk.ID)
            {
                return netDisk;
            }
            
            NSString *userPath = [[THDataManager sharedManager] exportWithObjectForKey:kDataKey_UserPath];
            //如果本地没有该目录的信息，则到网络查询(通过路径得到目录id)
            NSString *path = [context.path stringByReplacingOccurrencesOfString:userPath withString:@""];
            if ([path length] == 0) path = @"/";
            NSDictionary *postDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                     userToken,@"token",
                                     path,@"path",nil];
            NSURL *url = [NSURL URLWithString:@"http://openapi.vdisk.me/?m=dir&a=get_dirid_with_path"];
            NSData *receiveData = [[MKServiceManager sharedManager] uploadWithURL:url postDic:postDic];
            NSDictionary *receiveDic = [[CJSONDeserializer deserializer] deserializeAsDictionary:receiveData error:NULL];
            if (!receiveDic) return (VdiskFile *)nil;
            NSNumber *errorCode = [receiveDic objectForKey:@"err_code"];
            NSString *dologidStr = [receiveDic objectForKey:@"dologid"];
            receiveDic = [receiveDic objectForKey:@"data"];
            NSString *IDStr = [NSString stringWithFormat:@"%d",[[receiveDic objectForKey:@"id"] intValue]];
            if ([errorCode intValue] == 0)
            {
                VdiskFile *disk = [[VdiskFile alloc] init];
                disk.dologid = dologidStr;
                disk.path = path;
                disk.ID = IDStr;
                disk.name = [path lastPathComponent];
                disk.isDirectory = YES;
                return disk;
            }
            else if ([errorCode intValue] == 900)
            {
                sleep(10);
                return blocks(context);
            }else
            {
                //通过路径得到目录id失败，则需要创建此目录
                NSString *name = [path lastPathComponent];
                NSString *fpath = [path stringByDeletingLastPathComponent];
                VdiskFile *disk = [[VdiskFile alloc] init];
                disk.path = fpath;
                disk.isDirectory = YES;
                VdiskFile *receiveDisk = blocks(disk);
                if (receiveDisk)
                {
                    //创建目录
                    NSDictionary *postDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                             userToken,@"token",
                                             name,@"create_name",
                                             receiveDisk.name,@"parent_name",
                                             receiveDisk.ID,@"parent_id",nil];
                    NSURL *url = [NSURL URLWithString:@"http://openapi.vdisk.me/?m=dir&a=create_dir"];
                    NSData *receiveData = [[MKServiceManager sharedManager] uploadWithURL:url postDic:postDic];
                    NSDictionary *receiveDic = [[CJSONDeserializer deserializer] deserializeAsDictionary:receiveData error:NULL];
                    NSNumber *errorCode = [receiveDic objectForKey:@"err_code"];
                    NSString *dologidStr = [receiveDic objectForKey:@"dologid"];
                    if ([errorCode intValue] == 0 || [errorCode intValue] == 3 || [errorCode intValue] == 601 || [errorCode intValue] == 611)
                    {
                        //0: success
                        //3: create_name characters are not allowed 目录名中使用了非法字符
                        //601: directory full of files and directories 目录已满
                        //611: System directory not support create sub directory 系统目录不支持创建子目录
                        receiveDic = [receiveDic objectForKey:@"data"];
                        NSString *IDStr = [receiveDic objectForKey:@"dir_id"];
                        NSString *nameStr = [receiveDic objectForKey:@"name"];
                        
                        VdiskFile *disk = [[VdiskFile alloc] init];
                        disk.errorCode = errorCode;
                        disk.dologid = dologidStr;
                        disk.path = path;
                        disk.name = nameStr;
                        disk.ID = IDStr;
                        return disk;
                    }
                    else if ([errorCode intValue] == 900)
                    {
                        sleep(10);
                        return blocks(context);
                    }else
                    {
                        //创建目录失败
                        return blocks(context);
                    }
                }
                return blocks(context);
            }
        }else
        {
            //如果需要删除
            if (context.isDelete)
            {
                NSDictionary *postDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                         userToken,@"token",
                                         context.ID,@"fid",nil];
                NSURL *url = [NSURL URLWithString:@"http://openapi.vdisk.me/?m=file&a=delete_file"];
                NSData *receiveData = [[MKServiceManager sharedManager] uploadWithURL:url postDic:postDic];
                NSDictionary *receiveDic = [[CJSONDeserializer deserializer] deserializeAsDictionary:receiveData error:NULL];
                if (!receiveDic) return (VdiskFile *)nil;
                NSNumber *errorCode = [receiveDic objectForKey:@"err_code"];
                if ([errorCode intValue] == 900)
                {
                    sleep(10);
                    return blocks(context);
                }
                NSString *dologidStr = [receiveDic objectForKey:@"dologid"];
                
                VdiskFile *disk = [[VdiskFile alloc] init];
                disk.errorCode = errorCode;
                disk.dologid = dologidStr;
                disk.path = context.path;
                disk.ID = context.ID;
                disk.isDirectory = context.isDirectory;
                return disk;
            }
            
            //上传文件
            NSString *name = [context.path lastPathComponent];
            NSString *fpath = [context.path stringByDeletingLastPathComponent];
            VdiskFile *disk = [[VdiskFile alloc] init];
            disk.path = fpath;
            disk.isDirectory = YES;
            VdiskFile *receiveDisk = blocks(disk);
            if (receiveDisk)
            {
                //无文件上传
                NSString *localSha1 = (__bridge_transfer NSString*)FileSha1HashCreateWithPath((__bridge CFStringRef)context.path, FileHashDefaultChunkSizeForReadingData);
                NSDictionary *postDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                         userToken,@"token",
                                         receiveDisk.ID,@"dir_id",
                                         name,@"file_name",
                                         localSha1,@"sha1",nil];
                NSURL *url = [NSURL URLWithString:@"http://openapi.vdisk.me/?m=file&a=upload_with_sha1"];
                NSData *receiveData = [[MKServiceManager sharedManager] uploadWithURL:url postDic:postDic];
                NSDictionary *receiveDic = [[CJSONDeserializer deserializer] deserializeAsDictionary:receiveData error:NULL];
                if (!receiveDic) return blocks(context);
                NSNumber *errorCode = [receiveDic objectForKey:@"err_code"];
                NSString *dologidStr = [receiveDic objectForKey:@"dologid"];
                if ([errorCode intValue] == 1)
                {
                    //如果因为sha1不存在，则开始有文件上传
                    NSURL *fileUrl = [NSURL fileURLWithPath:context.path];
                    NSDictionary *postDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                             userToken,@"token",
                                             receiveDisk.ID,@"dir_id",
                                             @"yes",@"cover",
                                             fileUrl,@"file",nil];
                    NSURL *url = [NSURL URLWithString:@"http://openapi.vdisk.me/?m=file&a=upload_file"];
                    NSData *receiveData = [[MKServiceManager sharedManager] uploadWithURL:url postDic:postDic];
                    NSDictionary *receiveDic = [[CJSONDeserializer deserializer] deserializeAsDictionary:receiveData error:NULL];
                    if (!receiveDic) return blocks(context);
                    NSNumber *errorCode = [receiveDic objectForKey:@"err_code"];
                    if ([errorCode intValue] == 900)
                    {
                        sleep(10);
                        return blocks(context);
                    }
                    NSString *dologidStr = [receiveDic objectForKey:@"dologid"];

                    receiveDic = [receiveDic objectForKey:@"data"];
                    NSString *IDStr = [receiveDic objectForKey:@"fid"];
                    NSString *nameStr = [receiveDic objectForKey:@"name"];
                    NSString *sha1Str = [receiveDic objectForKey:@"sha1"];
                    
                    VdiskFile *disk = [[VdiskFile alloc] init];
                    disk.errorCode = errorCode;
                    disk.dologid = dologidStr;
                    disk.path = context.path;
                    disk.name = nameStr;
                    disk.sha1 = sha1Str;
                    disk.ID = IDStr;
                    return disk;

                }
                else if ([errorCode intValue] == 900)
                {
                    sleep(10);
                    return blocks(context);
                }else
                {
                    //上传成功或者失败
                    receiveDic = [receiveDic objectForKey:@"data"];
                    NSString *IDStr = [receiveDic objectForKey:@"fid"];
                    NSString *nameStr = [receiveDic objectForKey:@"name"];
                    NSString *sha1Str = [receiveDic objectForKey:@"sha1"];
                    
                    VdiskFile *disk = [[VdiskFile alloc] init];
                    disk.errorCode = errorCode;
                    disk.dologid = dologidStr;
                    disk.path = context.path;
                    disk.name = nameStr;
                    disk.sha1 = sha1Str;
                    disk.ID = IDStr;
                    return disk;
                }
            }
            return blocks(context);
        }

        return context;
    };
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        isUp = YES;
        
        VdiskNotification *notify = [[VdiskNotification alloc] init];
        notify.name = kNotification_Synchronous;
        NSMutableDictionary *info = [NSMutableDictionary dictionaryWithCapacity:2];
        notify.info = info;
        [info setObject:kNotificationInfoValue_SynUp forKey:kNotificationInfoKey_State];
        [info setObject:kNotificationInfoValue_SynBegin forKey:kNotificationInfoKey_Message];
        [self performSelectorOnMainThread:@selector(postNotificationWithInfo:) withObject:notify waitUntilDone:NO];
        
        
        NSDictionary *localFileDic = [self getLocalFileItem];
        NSDictionary *netFileDic =[[THDataManager sharedManager] exportWithObjectForKey:kDataKey_FileDic];
        if (!netFileDic) netFileDic = [NSDictionary dictionary];
        NSMutableDictionary *newNetFileDic = [NSMutableDictionary dictionaryWithDictionary:netFileDic];
        
        //寻找需要上传的元素
        for (VdiskFile *localDisk in [localFileDic allValues])
        {            
            BOOL needUp = NO;
            VdiskFile *netDisk = [netFileDic objectForKey:localDisk.path];
            if (netDisk)
            {
                if (!localDisk.isDirectory)
                {
                    if (![localDisk.sha1 isEqualToString:netDisk.sha1])
                    {
                        needUp = YES;
                    }
                }
            }else
            {
                needUp = YES;
            }
            
            if (needUp)
            {
                localDisk.isDelete = NO;
                VdiskFile *receiveDisk = blocks(localDisk);
                //上传成功
                if (receiveDisk)
                {
                    NSString *userPath = [[THDataManager sharedManager] exportWithObjectForKey:kDataKey_UserPath];
                    
                    if ([receiveDisk.path rangeOfString:userPath].location == NSNotFound)
                        receiveDisk.path = [userPath stringByAppendingPathComponent:receiveDisk.path];
                    [newNetFileDic setObject:receiveDisk forKey:receiveDisk.path];
                    if ([receiveDisk.dologid length] > 0)
                        [[THDataManager sharedManager] importWithObject:receiveDisk.dologid forKey:kDataKey_DologID];
                }
            }
        }
        
        [[THDataManager sharedManager] importWithObject:newNetFileDic forKey:kDataKey_FileDic];
        
        //寻找需要删除的元素
        for (VdiskFile *netDisk in [netFileDic allValues])
        {
            VdiskFile *localDisk = [localFileDic objectForKey:netDisk.path];
            if (!localDisk)
            {
                netDisk.isDelete = YES;
                VdiskFile *receiveDisk = blocks(netDisk);
                //删除成功
                if (receiveDisk)
                {
                    [newNetFileDic removeObjectForKey:netDisk.path];
                    if ([receiveDisk.dologid length] > 0)
                        [[THDataManager sharedManager] importWithObject:receiveDisk.dologid forKey:kDataKey_DologID];
                }
            }
        }
        
        [info setObject:kNotificationInfoValue_SynEnd forKey:kNotificationInfoKey_Message];
        [self performSelectorOnMainThread:@selector(postNotificationWithInfo:) withObject:notify waitUntilDone:NO];
        
        isUp = NO;
    });
}

//分享文件
- (void)sharedFile:(VdiskFile *)file on:(BOOL)isOn
{
    __block VdiskFile *currentFile = file;
    if (isOn)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSDictionary *postDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                     userToken,@"token",
                                     currentFile.ID,@"fid",nil];
            NSURL *url = [NSURL URLWithString:@"http://openapi.vdisk.me/?m=file&a=share_file"];
            NSData *receiveData = [[MKServiceManager sharedManager] uploadWithURL:url postDic:postDic];
            NSDictionary *receiveDic = [[CJSONDeserializer deserializer] deserializeAsDictionary:receiveData error:NULL];
            
            if (!receiveDic) return;
            NSNumber *errorCode = [receiveDic objectForKey:@"err_code"]; 
            NSString *errorMessage = [receiveDic objectForKey:@"err_msg"];
            receiveDic = [receiveDic objectForKey:@"data"];
            NSString *downPagelink = [receiveDic objectForKey:@"weibo_url"];
            if (!downPagelink) downPagelink = @"";
            
            currentFile.sharedPageLink = downPagelink;
            
            VdiskNotification *notify = [[VdiskNotification alloc] init];
            notify.name = kNotification_Shared;
            NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                                  errorCode,kNotificationInfoKey_State,
                                  errorMessage,kNotificationInfoKey_Message,
                                  downPagelink,kNotificationInfoKey_Content,
                                  [NSNumber numberWithBool:isOn],kNotificationInfoValue_SharedOn,
                                  currentFile,kNotificationInfoKey_Context,nil];
            notify.info = info;
            [self performSelectorOnMainThread:@selector(postNotificationWithInfo:) withObject:notify waitUntilDone:NO];
        });
    }else
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSDictionary *postDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                     userToken,@"token",
                                     currentFile.ID,@"fid",nil];
            NSURL *url = [NSURL URLWithString:@"http://openapi.vdisk.me/?m=file&a=cancel_share_file"];
            NSData *receiveData = [[MKServiceManager sharedManager] uploadWithURL:url postDic:postDic];
            NSDictionary *receiveDic = [[CJSONDeserializer deserializer] deserializeAsDictionary:receiveData error:NULL];
            
            if (!receiveDic) return;
            NSNumber *errorCode = [receiveDic objectForKey:@"err_code"]; 
            NSString *errorMessage = [receiveDic objectForKey:@"err_msg"];
            
            if ([errorCode intValue] == 0)
            {
                currentFile.sharedPageLink = nil;
            }
            VdiskNotification *notify = [[VdiskNotification alloc] init];
            notify.name = kNotification_Shared;
            NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                                  errorCode,kNotificationInfoKey_State,
                                  errorMessage,kNotificationInfoKey_Message,
                                  [NSNumber numberWithBool:isOn],kNotificationInfoValue_SharedOn,
                                  currentFile,kNotificationInfoKey_Context,nil];
            notify.info = info;
            [self performSelectorOnMainThread:@selector(postNotificationWithInfo:) withObject:notify waitUntilDone:NO];
        });
    }
}

#pragma mark -
#pragma mark MKServiceManagerDelegate

- (void)serviceFinish:(MKServiceManager *)webService didReceiveData:(NSData *)data context:(id)context
{
    //id receiveDic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:NULL];
    id receiveDic = [[CJSONDeserializer deserializer] deserializeAsDictionary:data error:NULL];
    NSString *token = [[receiveDic objectForKey:@"data"] objectForKey:@"token"]; 
    if ([token length] > 0) userToken = token; 
    NSString *userIdStr = [[receiveDic objectForKey:@"data"] objectForKey:@"uid"];
    NSString *latestUserId = [[THDataManager sharedManager] exportWithObjectForKey:kDataKey_UserID];
    if ([userIdStr isEqualToString:latestUserId]) 
    {
        userDologID = nil;
        [[THDataManager sharedManager] importWithObject:userDologID forKey:kDataKey_DologID];
        [[THDataManager sharedManager] importWithObject:userIdStr forKey:kDataKey_UserID];
    }
    
    if ([context isEqualToString:kRequestContextSignIn])
    {
        
        VdiskNotification *notify = [[VdiskNotification alloc] init];
        notify.name = kNotification_SignIn;
        NSMutableDictionary *info = [NSMutableDictionary dictionaryWithCapacity:2];
        notify.info = info;
        
        NSNumber *errorCodeStr = [receiveDic objectForKey:@"err_code"];
        NSInteger errorCode = [errorCodeStr integerValue];
        if (errorCodeStr && errorCode == 0)
        {
            //create keep token
            if (!timer) 
            {
                NSDate *nowDate = [NSDate date];
                timer = [[NSTimer alloc] initWithFireDate:nowDate interval:10*60*1.0 target:self selector:@selector(keepToken) userInfo:nil repeats:YES];
                [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
            }
            
            [info setObject:[NSNumber numberWithBool:YES] forKey:kNotificationInfoKey_State];
            [info setObject:@"已连接云端" forKey:kNotificationInfoKey_Message];
        }
        else if (errorCode == 2)
        {
            //用户名无效
            [info setObject:[NSNumber numberWithBool:NO] forKey:kNotificationInfoKey_State];
            [info setObject:@"登录口令无效" forKey:kNotificationInfoKey_Message];
        }
        else if (errorCode == 3)
        {
            //时间无效
            [info setObject:[NSNumber numberWithBool:NO] forKey:kNotificationInfoKey_State];
            [info setObject:@"系统时间无效" forKey:kNotificationInfoKey_Message];
        }
        else
        {
            //未知错误
            [info setObject:[NSNumber numberWithBool:NO] forKey:kNotificationInfoKey_State];
            [info setObject:@"未知错误" forKey:kNotificationInfoKey_Message];
        }
        
        [self postNotificationWithInfo:notify];
    }
    if ([context isEqualToString:kRequestContextKeepToken]) 
    {
        NSNumber *errorCodeStr = [receiveDic objectForKey:@"err_code"];
        NSInteger errorCode = [errorCodeStr integerValue];
        NSString *dologid = [receiveDic objectForKey:@"dologid"];
        if (dologid) userDologID = dologid;
        if (errorCode == 0)
        {
            //如果自动同步开启
            NSNumber *autoSynObj = [[THDataManager sharedManager] exportWithObjectForKey:kDataKey_AutoSyn];
            if ([autoSynObj boolValue])
            {
                [self synchronousFilesAuto];
            }
        }else
        {
            //未知错误
        }
    }
}

- (void)servicFail:(MKServiceManager *)webService didFailWithError:(NSError *)error context:(id)context
{
    userToken = nil;
    if ([context isEqualToString:kRequestContextSignIn])
    {
        VdiskNotification *notify = [[VdiskNotification alloc] init];
        notify.name = kNotification_SignIn;
        NSMutableDictionary *info = [NSMutableDictionary dictionaryWithCapacity:2];
        notify.info = info;
        
        [info setObject:[NSNumber numberWithBool:NO] forKey:kNotificationInfoKey_State];
        [info setObject:@"网络连接超时" forKey:kNotificationInfoKey_Message];
        
        [self postNotificationWithInfo:notify];
    }
    
    if ([context isEqualToString:kRequestContextKeepToken])
    {
        
    }
}

@end
