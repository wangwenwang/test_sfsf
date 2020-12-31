//
//  NSString+Base64.h
//  tms-ios
//
//  Created by 滕睿(Ray Teng)-航空运力平台项目 on 2020/9/17.
//  Copyright © 2020 wangziting. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (Base64)

+ (NSString *)base64StringFromData:(NSData *)data length:(NSUInteger)length;

@end

NS_ASSUME_NONNULL_END
