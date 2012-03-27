//
//  MKWebService.h
//  MKNetSaveCard
//
//  Created by tanhao on 11-8-3.
//  Copyright 2011 http://www.tanhao.me All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MKWebServiceDelegate;
@interface MKWebService : NSObject {
	id<MKWebServiceDelegate>   __unsafe_unretained _delegate;
	NSURL                      *_url;
	
	@private
	NSURLConnection            *_con;
	NSMutableData              *_data;
}
@property (nonatomic, unsafe_unretained) id<MKWebServiceDelegate> delegate;
@property (nonatomic, strong)   NSURL  *url;

/***上传***/
- (void)uploadDic:(NSDictionary *)dic;
/***下载***/
- (void)downloadBlob;

//synchronous
- (NSData *)uploadDicImmediately:(NSDictionary *)dic;
- (NSData *)downloadBlobImmediately;

@end

@protocol MKWebServiceDelegate<NSObject>

- (void)webServiceBegin:(MKWebService *)webService;
- (void)webServiceFinish:(MKWebService *)webService didReceiveData:(NSData *)data;
- (void)webServiceFail:(MKWebService *)webService didFailWithError:(NSError *)error;

@end