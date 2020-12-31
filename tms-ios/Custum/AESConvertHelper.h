//
//  AESConvertHelper.h
//  tms-ios
//
//  Created by 滕睿(Ray Teng)-航空运力平台项目 on 2020/9/17.
//  Copyright © 2020 wangziting. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AESConvertHelper : NSObject

/// 将参数转换为AES加密
+ (NSString *)convertToAesWithParam:(id)param;

/// 将AES参数转换为明文
+ (NSDictionary *)convertAesToParam:(id)hexString;

@end

NS_ASSUME_NONNULL_END
