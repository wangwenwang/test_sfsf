//
//  PrintimageTopViewController.h
//  tms-ios
//
//  Created by wangww on 2020/3/16.
//  Copyright © 2020 wangziting. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PrintimageTopViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIView *container;

@property (strong, nonatomic) NSString *productNo_s;

@property (strong, nonatomic) NSDictionary *dic;

@property (strong, nonatomic) UIImage *imageLM;

@end

NS_ASSUME_NONNULL_END
