//
//  THDataManager.m
//  Vdisk
//
//  Created by Hao Tan on 11-12-31.
//  Copyright (c) 2011年 http://www.tanhao.me All rights reserved.
//

#import "THDataManager.h"


static THDataManager *instance = nil;

@implementation THDataManager

+ (id)sharedManager
{
    if (!instance)
    {
        instance = [[THDataManager alloc] init];
    }
    return instance;
}

- (id)init
{
    self = [super init];
    if (self) 
    {
        id dictionaryObj = [[NSUserDefaults standardUserDefaults] objectForKey:@"dictionary"];
        dictionary = [NSKeyedUnarchiver unarchiveObjectWithData:dictionaryObj];
        if (!dictionary)
            dictionary = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)importWithObject:(id)value forKey:(id)key
{
    if (value)
    {
        [dictionary setObject:value forKey:key];
    }else
    {
        [dictionary removeObjectForKey:key];
    }
    
    id dictionaryObj = [NSKeyedArchiver archivedDataWithRootObject:dictionary];
    [[NSUserDefaults standardUserDefaults] setObject:dictionaryObj forKey:@"dictionary"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (id)exportWithObjectForKey:(id)key
{
    return [dictionary objectForKey:key];
}

@end
