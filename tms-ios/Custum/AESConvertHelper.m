//
//  AESConvertHelper.m
//  tms-ios
//
//  Created by 滕睿(Ray Teng)-航空运力平台项目 on 2020/9/17.
//  Copyright © 2020 wangziting. All rights reserved.
//

#import "AESConvertHelper.h"
#import "NSData+Base64.h"
#import "NSString+Base64.h"
#import "NSData+CommonCrypto.h"

#define AES_KEY @"l5TJHfZrmY38Hf2e2H1h0Q=="

@implementation AESConvertHelper

// 将参数转换为aes
+ (NSString *)convertToAesWithParam:(id)param {
    NSString * paramString;
    if ([param isKindOfClass:[NSDictionary class]]) {
        paramString = [AESConvertHelper convertDicToJsonWithDic:param];
    }
    else if ([param isKindOfClass:[NSString class]]) {
        paramString = param;
    }
    NSLog(@"加密前:%@", paramString);

    // 加密
    CCCryptorStatus status = kCCSuccess;
    NSData* encryptedData = [[paramString dataUsingEncoding:NSUTF8StringEncoding]
                     dataEncryptedUsingAlgorithm:kCCAlgorithmAES128
                     key:AES_KEY
                     initializationVector:NULL   // ECB加密不会用到iv
                             options:kCCOptionPKCS7Padding| kCCOptionECBMode
                     error:&status];
    if (status != kCCSuccess) {
       NSLog(@"加密失败:%d", status);
       return nil;
    }
    NSString *base64EncodedString = [encryptedData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    NSLog(@"加密后参数：%@",base64EncodedString);
    return base64EncodedString;
    
}

// 将参数解密为明文
+ (NSDictionary *)convertAesToParam:(id)hexString {
    
    NSData *encryptedData = [NSData base64DataFromString:hexString];
//    NSData *decryptedData = [encryptedData decryptedAES256DataUsingKey:[[AES_KEY dataUsingEncoding:NSUTF8StringEncoding] SHA256Hash] error:nil];
//    return [[NSString alloc] initWithData:decryptedData encoding:NSUTF8StringEncoding];
    CCCryptorStatus status = kCCSuccess;
    NSData* decryptedData = [encryptedData decryptedDataUsingAlgorithm:kCCAlgorithmAES
                   key:AES_KEY
                   initializationVector:nil   // ECB解密不会用到iv
                  options:(kCCOptionPKCS7Padding|kCCOptionECBMode)
                   error:&status];
    if (status != kCCSuccess) {
       NSLog(@"加密失败:%d", status);
       return nil;
    }
    NSLog(@"解密后参数:%@",[[NSString alloc]initWithData:decryptedData encoding:NSUTF8StringEncoding]);
    NSDictionary *paramDic = [NSJSONSerialization JSONObjectWithData:decryptedData options:0 error:nil];
    return paramDic;
}

// 将字典转换为JSON字符串
+ (NSString *)convertDicToJsonWithDic:(NSDictionary *)dic {
    
    NSError *error = nil;
    NSData *jsonData = nil;
    if (!self) {
        return nil;
    }
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        NSString *keyString = nil;
        NSString *valueString = nil;
        if ([key isKindOfClass:[NSString class]]) {
            keyString = key;
        }else{
            keyString = [NSString stringWithFormat:@"%@",key];
        }

        if ([obj isKindOfClass:[NSString class]]) {
            valueString = obj;
        }else{
            valueString = [NSString stringWithFormat:@"%@",obj];
        }

        [dict setObject:valueString forKey:keyString];
    }];
    jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
    if ([jsonData length] == 0 || error != nil) {
        return nil;
    }
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    NSMutableString *mutStr = [NSMutableString stringWithString:jsonString];

    NSRange range = {0,jsonString.length};

    //去掉字符串中的空格
    [mutStr replaceOccurrencesOfString:@" " withString:@"" options:NSLiteralSearch range:range];

    NSRange range2 = {0,mutStr.length};

    //去掉字符串中的换行符
    [mutStr replaceOccurrencesOfString:@"\n" withString:@"" options:NSLiteralSearch range:range2];
    return jsonString;
    
}


//AES加密解密#import <CommonCrypto/CommonCrypto.h>#import <CommonCrypto/CommonDigest.h>//AES128位加密 base64编码 注：kCCKeySizeAES128点进去可以更换256位加密
-(NSString *)AES128Encrypt:(NSString *)plainText key:(NSString *)key
{
    char keyPtr[kCCKeySizeAES128+1];//
    memset(keyPtr, 0, sizeof(keyPtr));
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    
    NSData* data = [plainText dataUsingEncoding:NSUTF8StringEncoding];
    NSUInteger dataLength = [data length];
    
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    size_t numBytesEncrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt,
                                          kCCAlgorithmAES128,
                                          kCCOptionPKCS7Padding|kCCOptionECBMode,
                                          keyPtr,
                                          kCCBlockSizeAES128,
                                          NULL,
                                          [data bytes],
                                          dataLength,
                                          buffer,
                                          bufferSize,
                                          &numBytesEncrypted);
    if (cryptStatus == kCCSuccess) {
        NSData *resultData = [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted];
        
        NSString *stringBase64 = [resultData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed]; // base64格式的字符串
        return stringBase64;
        
    }
    free(buffer);
    return nil;
}

//解密
-(NSString *)AES128Decrypt:(NSString *)encryptText key:(NSString *)key
{
    char keyPtr[kCCKeySizeAES128 + 1];
    memset(keyPtr, 0, sizeof(keyPtr));
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    
    NSData *data = [[NSData alloc] initWithBase64EncodedString:encryptText options:NSDataBase64DecodingIgnoreUnknownCharacters];//base64解码
    
    NSUInteger dataLength = [data length];
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    
    size_t numBytesCrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt,
                                          kCCAlgorithmAES128,
                                          kCCOptionPKCS7Padding|kCCOptionECBMode,
                                          keyPtr,
                                          kCCBlockSizeAES128,
                                          NULL,
                                          [data bytes],
                                          dataLength,
                                          buffer,
                                          bufferSize,
                                          &numBytesCrypted);
    if (cryptStatus == kCCSuccess) {
        NSData *resultData = [NSData dataWithBytesNoCopy:buffer length:numBytesCrypted];
        
        return [[NSString alloc] initWithData:resultData encoding:NSUTF8StringEncoding];
    }
    free(buffer);
    return nil;
}

-(NSData *)aes_encryptData:(NSData *)inputData  withKey:(NSString *)key
{
    NSLog(@"inputData AES %@",inputData);
    char keyPtr[kCCKeySizeAES256+1];
    bzero(keyPtr, sizeof(keyPtr));
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    NSUInteger dataLength = [inputData length];
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    size_t numBytesEncrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmAES128,
                                          kCCOptionPKCS7Padding,
                                          keyPtr, kCCKeySizeAES128,
                                          NULL,
                                          [inputData bytes], dataLength,
                                          buffer, bufferSize,
                                          &numBytesEncrypted);
    if (cryptStatus == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted];
    }
    free(buffer);
    return nil;
}
+ (NSString *)encryptAES:(NSString *)content key:(NSString *)key {

    NSData *contentData = [content dataUsingEncoding:NSUTF8StringEncoding];
    NSUInteger dataLength = contentData.length;
    
    // 为结束符'\0' +1
    char keyPtr[kCCKeySizeAES128 + 1];
    memset(keyPtr, 0, sizeof(keyPtr));
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    
    // 密文长度 <= 明文长度 + BlockSize
    size_t encryptSize = dataLength + kCCBlockSizeAES128;
    void *encryptedBytes = malloc(encryptSize);
    size_t actualOutSize = 0;
    
    NSData *initVector =  NULL;
    
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt,
                                          kCCAlgorithmAES,
                                          kCCOptionPKCS7Padding,  // 系统默认使用 CBC，然后指明使用 PKCS7Padding
                                          keyPtr,
                                          kCCKeySizeAES128,
                                          initVector.bytes,
                                          contentData.bytes,
                                          dataLength,
                                          encryptedBytes,
                                          encryptSize,
                                          &actualOutSize);
    
    if (cryptStatus == kCCSuccess) {
        // 对加密后的数据进行 base64 编码
        return [[NSData dataWithBytesNoCopy:encryptedBytes length:actualOutSize] base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    }
    free(encryptedBytes);
    return nil;
}

@end
