//
//  PrintimageTwoInOneController.h
//  tms-ios
//
//  Created by wangziting on 2020/4/11.
//  Copyright © 2020 wangziting. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PrintimageTwoInOneController : UIViewController

@property (strong, nonatomic) NSString *productNo_s;

@property (strong, nonatomic) NSDictionary *dic;
@property (weak, nonatomic) IBOutlet UIView *container;

@end

NS_ASSUME_NONNULL_END
