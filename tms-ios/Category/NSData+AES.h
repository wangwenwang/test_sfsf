//
//  NSData+AES.h
//  tms-ios
//
//  Created by 滕睿(Ray Teng)-航空运力平台项目 on 2020/9/16.
//  Copyright © 2020 wangziting. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSData (AES)

- (NSData *)AES256EncryptWithKey:(NSData *)key;   //加密
 
- (NSData *)AES256DecryptWithKey:(NSData *)key;   //解密
 
- (NSString *)newStringInBase64FromData;            //追加64编码
 
+ (NSString*)base64encode:(NSString*)str;           //同上64编码
 
+(NSData*)stringToByte:(NSString*)string;
 
+(NSString*)byteToString:(NSData*)data;

@end

NS_ASSUME_NONNULL_END
