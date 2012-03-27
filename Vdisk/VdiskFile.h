//
//  VdiskFile.h
//  Vdisk
//
//  Created by Hao Tan on 11-12-29.
//  Copyright (c) 2011年 http://www.tanhao.me All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VdiskFile : NSObject
{
    BOOL     isDirectory;
    BOOL     isDelete;
    NSString *ID;
    NSString *name;
    NSString *path;
    NSString *fileType;
    NSString *sha1;
    NSString *dologid;
    NSNumber *errorCode; //使用情景1：比如本地文件上传失败，把errorCode记录下来，不会删除此文件
    NSMutableArray  *children;
    NSString *sharedPageLink;
}
@property (nonatomic, assign) BOOL     isDirectory;
@property (nonatomic, assign) BOOL     isDelete;
@property (nonatomic, strong) NSString *ID;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) NSString *fileType;
@property (nonatomic, strong) NSString *sha1;
@property (nonatomic, strong) NSString *dologid;
@property (nonatomic, strong) NSNumber *errorCode;
@property (nonatomic, strong) NSMutableArray  *children;
@property (nonatomic, strong) NSString *sharedPageLink;

@end
