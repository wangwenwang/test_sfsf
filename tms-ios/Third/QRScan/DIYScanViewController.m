//
//  DIYScanViewController.m
//  LBXScanDemo
//
//  Created by lbxia on 2017/6/5.
//  Copyright © 2017年 lbx. All rights reserved.
//

#import "DIYScanViewController.h"
#import "LBXAlertAction.h"


@interface DIYScanViewController ()

@end

@implementation DIYScanViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.cameraInvokeMsg = @"相机启动中";
    
    [self addNotification];
}

#pragma mark -实现类继承该方法，作出对应处理

- (void)scanResultWithArray:(NSArray<LBXScanResult*>*)array
{
    if (!array ||  array.count < 1)
    {
        [self popAlertMsgWithScanResult:nil];
        
        return;
    }
    
    //经测试，可以ZXing同时识别2个二维码，不能同时识别二维码和条形码
    //    for (LBXScanResult *result in array) {
    //
    //        NSLog(@"scanResult:%@",result.strScanned);
    //    }
    
    LBXScanResult *scanResult = array[0];
    
    NSString*strResult = scanResult.strScanned;
    
    self.scanImage = scanResult.imgScanned;
    
    if (!strResult) {
        
        [self popAlertMsgWithScanResult:nil];
        
        return;
    }
    
    //TODO: 这里可以根据需要自行添加震动或播放声音提示相关代码
    //...
    
    [self showNextVCWithScanResult:scanResult];
}

- (void)popAlertMsgWithScanResult:(NSString*)strResult
{
    if (!strResult) {
        
        strResult = @"识别失败";
    }
    
    __weak __typeof(self) weakSelf = self;
    [LBXAlertAction showAlertWithTitle:@"扫码内容" msg:strResult buttonsStatement:@[@"知道了"] chooseBlock:^(NSInteger buttonIdx) {

        [weakSelf reStartDevice];
    }];
}

- (void)showNextVCWithScanResult:(LBXScanResult *)strResult
{
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        NSString *jsStr = [NSString stringWithFormat:@"TellVue_QRScanResult_Ajax('%@')", strResult.strScanned];
        NSLog(@"%@",jsStr);
        [_webView evaluateJavaScript:jsStr completionHandler:^(id _Nullable resp, NSError * _Nullable error) {
            NSLog(@"error = %@ , response = %@",error, resp);
        }];
        
        NSString *path = [[NSBundle mainBundle] pathForResource:@"scan_code_success.wav" ofType:nil];
        if (!path) {
            /// 动态库 path 的获取
            path = [[NSBundle bundleForClass:[self class]] pathForResource:@"scan_code_success.wav" ofType:nil];
        }
        NSURL *fileUrl = [NSURL fileURLWithPath:path];
        SystemSoundID soundID = 0;
        AudioServicesCreateSystemSoundID((__bridge CFURLRef)(fileUrl), &soundID);
        AudioServicesPlaySystemSound(soundID);
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        
        [self dismissViewControllerAnimated:YES completion:nil];
    });
}

#pragma mark - 函数

- (void)dismiss {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - 通知

- (void)addNotification {
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveWebView:) name:kReceive_dismiss_Notification object:nil];
}

- (void)receiveWebView:(NSNotification *)aNotification {
    
    [self dismiss];
}

@end


