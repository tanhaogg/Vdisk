//
//  MKServiceManager.h
//  MKNetSaveCard
//
//  Created by tanhao on 11-8-15.
//  Copyright 2011年 http://www.tanhao.me All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MKWebService.h"

@protocol MKServiceManagerDelegate;
@interface MKServiceManager : NSObject<MKWebServiceDelegate>{
    NSMutableArray *delegates;
    NSMutableArray *downloaders;
    NSMutableArray *contexts;
}

+ (id)sharedManager;

- (void)uploadWithURL:(NSURL *)url delegate:(id<MKServiceManagerDelegate>)delegate postDic:(NSDictionary *)dic context:(id)context;
- (void)downloadWithURL:(NSURL *)url delegate:(id<MKServiceManagerDelegate>)delegate context:(id)context;
- (void)cancelForDelegate:(id<MKServiceManagerDelegate>)delegate;

//synchronous
- (NSData *)uploadWithURL:(NSURL *)url postDic:(NSDictionary *)dic;
- (NSData *)downloadWithURL:(NSURL *)url;

@end


@protocol MKServiceManagerDelegate<NSObject>

- (void)serviceFinish:(MKServiceManager *)webService didReceiveData:(NSData *)data context:(id)context;
- (void)servicFail:(MKServiceManager *)webService didFailWithError:(NSError *)error context:(id)context;

@end