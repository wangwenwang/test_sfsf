//
//  PrintViewController.h
//  tms-ios
//
//  Created by wangww on 2020/3/16.
//  Copyright © 2020 wangziting. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <CoreBluetooth/CoreBluetooth.h>
#import <zicox_ios_sdk/Bluetooth.h>

NS_ASSUME_NONNULL_BEGIN

@interface PrintViewController : UIViewController

// 订单标签号数组
@property (strong, nonatomic) NSArray *arr;

// 订单内容
@property (strong, nonatomic) NSDictionary *dic;

@end

NS_ASSUME_NONNULL_END
