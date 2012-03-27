//
//  Utility.h
//  TheDealersForum
//
//  Created by Hailong Zhang on 5/3/11.
//  Copyright 2011 Personal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>


@interface Utility : NSObject {

}
+ (NSString *) md5ForString:(NSString *)str;
+ (NSString *) md5ForData:(NSData *)data;
+ (NSString *) doCipher:(NSString *)sTextIn key:(NSString *)sKey context:(CCOperation)encryptOrDecrypt;
+ (NSString *) encryptStr:(NSString *) str key:(NSString *)sKey;
+ (NSString *) decryptStr:(NSString	*) str key:(NSString *)sKey;

#pragma mark Based64
+ (NSString *) encodeBase64WithString:(NSString *)strData;
+ (NSString *) encodeBase64WithData:(NSData *)objData;
+ (NSData   *) decodeBase64WithString:(NSString *)strBase64;

@end