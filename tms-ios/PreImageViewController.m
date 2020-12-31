//
//  PreImageViewController.m
//  tms-ios
//
//  Created by wangww on 2020/4/18.
//  Copyright © 2020 wangziting. All rights reserved.
//

#import "PreImageViewController.h"

@interface PreImageViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation PreImageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _imageView.image = _imagek;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
