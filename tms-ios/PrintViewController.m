//
//  PrintViewController.m
//  tms-ios
//
//  Created by wangww on 2020/3/16.
//  Copyright © 2020 wangziting. All rights reserved.
//

#import "PrintViewController.h"
#import "PrintTableViewCell.h"
#import "Tools.h"
#import "PrintimageTopViewController.h"
#import "PrintimageTwoInOneController.h"
#import "PrintimageTwoOtherController.h"
#import "MBProgressHUD.h"
#import "PreImageViewController.h"
#import "UIImage+fixOrientation.h"
#import <AFNetworking.h>
#import "AESConvertHelper.h"

@interface PrintViewController ()

@property (weak, nonatomic) IBOutlet UITableView *myTableView;

@property (strong, nonatomic) Bluetooth* bluetooth;
@property (strong, nonatomic) CBPeripheral* peripheral;
@property (strong, nonatomic) NSMutableArray* listDevices;
@property (strong, nonatomic) NSMutableString* listDeviceInfo;

@end

@implementation PrintViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.listDeviceInfo = [NSMutableString stringWithString:@""];
    self.listDevices = [NSMutableArray array];
    self.bluetooth = [[Bluetooth alloc]init];
    
    [self connDevice];
}


#pragma mark - 功能函数

- (void)registCell {
    
    [_myTableView registerNib:[UINib nibWithNibName:@"PrintTableViewCell" bundle:nil] forCellReuseIdentifier:@"PrintTableViewCell"];
}

#pragma mark - 事件

- (IBAction)exitOnclick {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (IBAction)connDevice{
    if(_listDevices != nil){
        _listDevices = nil;
        _listDevices = [NSMutableArray array];
        [_myTableView reloadData];
    }
    
    BLOCK_CALLBACK_SCAN_FIND callback = ^( CBPeripheral*peripheral){
        
        if(self.listDevices.count == 0){
            [self.listDevices addObject:peripheral];
        }
        
        // 设备去重
        //        int kk = 0;
        //        for(int i = 0; i < _listDevices.count; i++){
        //
        //            NSString *uuid = [NSString stringWithFormat:@"%@", [[_listDevices objectAtIndex:i] identifier]];
        //            uuid = [uuid substringFromIndex:[uuid length] - 13];
        //
        //            NSString *udx = [NSString stringWithFormat:@"%@", [peripheral identifier]];
        //            udx = [udx substringFromIndex:[udx length] - 13];
        //            if([uuid isEqualToString:udx]){
        //
        //                kk++;
        //            }
        //        }
        //        if(kk == 0){
        [self.listDevices addObject:peripheral];
        [_myTableView reloadData];
        //        }
    };
    
    [self.bluetooth scanStart:callback];
    
    double delayInSeconds = 5.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds* NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self.bluetooth scanStop];
    });
}

- (void)calulateImageFileSize:(UIImage *)image {
    NSData *data = UIImagePNGRepresentation(image);
    if (!data) {
        data = UIImageJPEGRepresentation(image, 1.0);//需要改成0.5才接近原图片大小，原因请看下文
    }
    double dataLength = [data length] * 1.0;
    NSArray *typeArray = @[@"bytes",@"KB",@"MB",@"GB",@"TB",@"PB", @"EB",@"ZB",@"YB"];
    NSInteger index = 0;
    while (dataLength > 1024) {
        dataLength /= 1024.0;
        index ++;
    }
    NSLog(@"image = %.3f %@",dataLength,typeArray[index]);
}

- (UIImage *)imageResize:(UIImage*)img andResizeTo:(CGSize)newSize {
    CGFloat scale = [[UIScreen mainScreen]scale];
    //UIGraphicsBeginImageContext(newSize);
    UIGraphicsBeginImageContextWithOptions(newSize, NO, scale);
    [img drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}


- (IBAction)printtwokonggang{
    
    NSString *url = [NSString stringWithFormat:@"%@%@", kApi, @"updatePrintCount.do"];

      AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
      manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", @"text/html", @"text/xml", @"text/plain", nil];

       NSString *params = [NSString stringWithFormat:@"{\"omsNo\":\"%@\"}", _dic[@"omsNo"]];
       NSString * aesParamString = [AESConvertHelper convertToAesWithParam:params];
       NSDictionary *parameters = @{@"params" : aesParamString};

       NSLog(@"上传位置点参数：%@", parameters);
      
      NSLog(@"接口%@请求【获取配载单轨迹】参数：%@", url, params);
      
      [manager POST:url parameters:parameters progress:^(NSProgress * _Nonnull uploadProgress) {
          nil;
      } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
          NSLog(@"请求成功---%@", responseObject);
          int States = [responseObject[@"States"] intValue];
          NSLog(@"----------%d", States);
          if(States == 1) {
//              NSDictionary * result = [AESConvertHelper convertAesToParam:responseObject];
          }else {
          }

      } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
          NSLog(@"请求失败---%@", error);
    //           if([_delegate respondsToSelector:@selector(failure:)]) {
    //               [_delegate failure:nil];
    //           }
      }];

    for(int i = 0; i < _arr.count; i++){
        NSLog(@"%@", [NSString stringWithFormat:@"打印开始: %d", i]);
        PrintimageTwoOtherController *vcte = [[PrintimageTwoOtherController alloc] init];
        vcte.productNo_s = _arr[i][@"productNo"];
        vcte.dic = _dic;
        UIView *viewte = vcte.view;
        viewte = vcte.view;
//        [self presentViewController:vcte animated:YES completion:nil];
        
        UIImage *image3te = [Tools tg_makeImageWithView:viewte withSize:viewte.frame.size];
        
        //旋转180
        image3te = [UIImage imageWithCGImage:image3te.CGImage scale:image3te.scale orientation:UIImageOrientationDown];
        
        CGFloat scale = [UIScreen mainScreen].scale;
        CGFloat p_w = 3 / scale * 260.0;
        CGFloat p_h = 3 / scale * 396.0;
        
        // 修改图片像素
        image3te = [self imageResize:image3te andResizeTo:CGSizeMake(p_w, p_h)];
        
        // 修改图片像素
//        image3te = [self imageResize:image3te andResizeTo:CGSizeMake(260, 396)];
        
        [self calulateImageFileSize:image3te];
        
        // 打印预览
        PreImageViewController *vck = [[PreImageViewController alloc] init];
        vck.imagek = image3te;
//        [self presentViewController:vck animated:YES completion:nil];
//        return;
        
        [self.bluetooth DrawBigBitmap:image3te gotopaper:1];
        [self.bluetooth print_status_detect];
//        NSLog(@"打印开始");
        int status=[self.bluetooth print_status_get:12000];
        NSLog(@"打印。。。");
        
        if(status == 1){
            NSLog(@"打印机缺纸");
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                
                usleep(2000);
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [Tools showAlert:self.view andTitle:@"打印机缺纸"];
                });
            });
        }
        if(status == 2){
            NSLog(@"打印机开盖");
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                
                usleep(2000);
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [Tools showAlert:self.view andTitle:@"打印机开盖"];
                });
            });
        }
        if(status == 0){
            NSLog(@"打印机正常");
        }
//        if(status == -1){
//            NSLog(@"打印机异常");
//            //                [Tools showAlert:self.view andTitle:@"打印机异常"];
//            [MBProgressHUD hideHUDForView:self.view animated:YES];
//
//            dispatch_async(dispatch_get_global_queue(0, 0), ^{
//
//                usleep(2000);
//                dispatch_async(dispatch_get_main_queue(), ^{
//
//                    [Tools showAlert:self.view andTitle:@"打印机异常"];
//                });
//            });
//            break;
//        }
        if((status == -1 || status == 0 || status == 1 || status == 2) && i == _arr.count - 1){
            NSLog(@"打印机蓝牙关闭");
            [self.bluetooth close];
            [MBProgressHUD hideHUDForView:self.view animated:YES];
        }
    }
}

- (IBAction)printtwoother{
    
     NSString *url = [NSString stringWithFormat:@"%@%@", kApi, @"updatePrintCount.do"];

       AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
       manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", @"text/html", @"text/xml", @"text/plain", nil];

        NSString *params = [NSString stringWithFormat:@"{\"omsNo\":\"%@\"}", _dic[@"omsNo"]];
        
        NSString * aesParamString = [AESConvertHelper convertToAesWithParam:params];
        NSDictionary *parameters = @{@"params" : aesParamString};

        NSLog(@"上传位置点参数：%@", parameters);
       
       NSLog(@"接口%@请求【获取配载单轨迹】参数：%@", url, params);
       
       [manager POST:url parameters:parameters progress:^(NSProgress * _Nonnull uploadProgress) {
           nil;
       } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
           NSLog(@"请求成功---%@", responseObject);
           int States = [responseObject[@"States"] intValue];
           NSLog(@"----------%d", States);
           if(States == 1) {
           }else {
           }

       } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
           NSLog(@"请求失败---%@", error);
    //           if([_delegate respondsToSelector:@selector(failure:)]) {
    //               [_delegate failure:nil];
    //           }
       }];

    for(int i = 0; i < _arr.count; i++){
        NSLog(@"%@", [NSString stringWithFormat:@"打印开始: %d", i]);
        PrintimageTwoInOneController *vct = [[PrintimageTwoInOneController alloc] init];
        vct.productNo_s = _arr[i][@"productNo"];
        vct.dic = _dic;
        UIView *viewt = vct.view;
        viewt = vct.container;
//        [self presentViewController:vct animated:YES completion:nil];
        
        UIImage *image3t = [Tools tg_makeImageWithView:viewt withSize:viewt.frame.size];
        
        //旋转180
        image3t = [UIImage imageWithCGImage:image3t.CGImage scale:image3t.scale orientation:UIImageOrientationDown];
        
        CGFloat scale = [UIScreen mainScreen].scale;
        CGFloat p_w = 3 / scale * 260.0;
        CGFloat p_h = 3 / scale * 396.0;
       
        // 修改图片像素
        image3t = [self imageResize:image3t andResizeTo:CGSizeMake(p_w, p_h)];
               
        
//        // 修改图片像素
//        image3t = [self imageResize:image3t andResizeTo:CGSizeMake(260, 396)];
//
        [self calulateImageFileSize:image3t];
        
        // 打印预览
        PreImageViewController *vck = [[PreImageViewController alloc] init];
        vck.imagek = image3t;
//        [self presentViewController:vck animated:YES completion:nil];
        
        [self.bluetooth DrawBigBitmap:image3t gotopaper:1];
        [self.bluetooth print_status_detect];
//        NSLog(@"打印开始");
        int status=[self.bluetooth print_status_get:12000];
        NSLog(@"打印。。。");
        
        if(status == 1){
            NSLog(@"打印机缺纸");
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                
                usleep(2000);
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [Tools showAlert:self.view andTitle:@"打印机缺纸"];
                });
            });
        }
        if(status == 2){
            NSLog(@"打印机开盖");
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                
                usleep(2000);
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [Tools showAlert:self.view andTitle:@"打印机开盖"];
                });
            });
        }
        if(status == 0){
            NSLog(@"打印机正常");
        }
//        if(status == -1){
//            NSLog(@"打印机异常");
//            //                [Tools showAlert:self.view andTitle:@"打印机异常"];
//            [MBProgressHUD hideHUDForView:self.view animated:YES];
//
//            dispatch_async(dispatch_get_global_queue(0, 0), ^{
//
//                usleep(2000);
//                dispatch_async(dispatch_get_main_queue(), ^{
//
//                    [Tools showAlert:self.view andTitle:@"打印机异常"];
//                });
//            });
//            break;
//        }
        if((status == -1 || status == 0 || status == 1 || status == 2) && i == _arr.count - 1){
            NSLog(@"打印机蓝牙关闭");
            [self.bluetooth close];
            [MBProgressHUD hideHUDForView:self.view animated:YES];
        }
    }
}


- (IBAction)printtwoinone{
    
    if(!_arr.count){

        [Tools showAlert:self.view andTitle:@"未找到订单"];
        return;
    }
    
    if(!self.peripheral){

        [Tools showAlert:self.view andTitle:@"请选择打印机"];
        return;
    }

    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [self.bluetooth open:self.peripheral];
    [self.bluetooth flushRead];
    
    if([[NSString stringWithFormat:@"%@",  _dic[@"transitSupplier"]]  isEqual: [NSString stringWithFormat:@"%@",  @"69545"]]){
        NSLog(@"打印空港");
        
        [self printtwokonggang];
        
    }else{
        NSLog(@"打印其他");
        
        [self printtwoother];
    }
}

- (IBAction)print{
    
    if(!_arr.count){
        
        [Tools showAlert:self.view andTitle:@"未找到订单"];
        return;
    }
    
    if(!self.peripheral){
        
        [Tools showAlert:self.view andTitle:@"请选择打印机"];
        return;
    }
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [self.bluetooth open:self.peripheral];
    [self.bluetooth flushRead];
//    --------------------------------------------------------------------
//    __weak __typeof(self)weakSelf = self;
       
       NSString *url = [NSString stringWithFormat:@"%@%@", kApi, @"updatePrintCount.do"];

       AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
       manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", @"text/html", @"text/xml", @"text/plain", nil];
    
        NSString *params = [NSString stringWithFormat:@"{\"omsNo\":\"%@\"}", _dic[@"omsNo"]];
        NSString * aesParamString = [AESConvertHelper convertToAesWithParam:params];
        NSDictionary *parameters = @{@"params" : aesParamString};
    
        NSLog(@"上传位置点参数：%@", parameters);
       
       NSLog(@"接口%@请求【获取配载单轨迹】参数：%@", url, params);
       
       [manager POST:url parameters:parameters progress:^(NSProgress * _Nonnull uploadProgress) {
           nil;
       } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
           NSLog(@"请求成功---%@", responseObject);
           int States = [responseObject[@"States"] intValue];
           NSLog(@"----------%d", States);
           if(States == 1) {
           }else {
           }

       } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
           NSLog(@"请求失败---%@", error);
//           if([_delegate respondsToSelector:@selector(failure:)]) {
//               [_delegate failure:nil];
//           }
       }];
    
// --------------------------------------------------------------------
    
    
    for(int i = 0; i < _arr.count; i++){
        NSLog(@"%@", [NSString stringWithFormat:@"打印开始: %d", i]);
        PrintimageTopViewController *vc = [[PrintimageTopViewController alloc] init];
        vc.productNo_s = _arr[i][@"productNo"];
        vc.dic = _dic;
        UIView *view = vc.view;
        view = vc.container;
//        [self presentViewController:vc animated:YES completion:nil];
        
        UIImage *image3 = [Tools tg_makeImageWithView:view withSize:view.frame.size];
        
        // 旋转180
        image3 = [UIImage imageWithCGImage:image3.CGImage scale:image3.scale orientation:UIImageOrientationDown];
        
        
        CGFloat scale = [UIScreen mainScreen].scale;
        CGFloat p_w = 3 / scale * 260.0;
        CGFloat p_h = 3 / scale * 396.0;
      
        // 修改图片像素
        image3 = [self imageResize:image3 andResizeTo:CGSizeMake(p_w, p_h)];
              
        // 修改图片像素
//        image3 = [self imageResize:image3 andResizeTo:CGSizeMake(260, 396)];
//
        [self calulateImageFileSize:image3];
        NSLog(@"%f, %f", image3.size.width, image3.size.height);
        
        // 打印预览
        PreImageViewController *vck = [[PreImageViewController alloc] init];
        vck.imagek = image3;
//        [self presentViewController:vck animated:YES completion:nil];
//        return;
        
        [self.bluetooth DrawBigBitmap:image3 gotopaper:1];
        [self.bluetooth print_status_detect];
//        NSLog(@"打印开始");
        int status=[self.bluetooth print_status_get:12000];
        NSLog(@"打印。。。");
        if(status == 1){
            NSLog(@"打印机缺纸");
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                
                usleep(2000);
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [Tools showAlert:self.view andTitle:@"打印机缺纸"];
                });
            });
        }
        if(status == 2){
            NSLog(@"打印机开盖");
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                
                usleep(2000);
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [Tools showAlert:self.view andTitle:@"打印机开盖"];
                });
            });
        }
        if(status == 0){
            NSLog(@"打印机正常");
        }
//        if(status == -1){
//            NSLog(@"打印机异常");
//            //                [Tools showAlert:self.view andTitle:@"打印机异常"];
//            [MBProgressHUD hideHUDForView:self.view animated:YES];
//
//            dispatch_async(dispatch_get_global_queue(0, 0), ^{
//
//                usleep(2000);
//                dispatch_async(dispatch_get_main_queue(), ^{
//
//                    [Tools showAlert:self.view andTitle:@"打印机异常"];
//                });
//            });
//            break;
//        }
        if((status == -1 || status == 0 || status == 1 || status == 2) && i == _arr.count - 1){
            NSLog(@"打印机蓝牙关闭");
            [self.bluetooth close];
            [MBProgressHUD hideHUDForView:self.view animated:YES];
        }
    }
    //    dispatch_async(dispatch_get_global_queue(0, 0), ^{
    //
    //        usleep(5000000);
    //        dispatch_async(dispatch_get_main_queue(), ^{
    //
    //            [self.bluetooth close];
    //        });
    //    });
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return self.listDevices.count;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return 50;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static  NSString  *CellIdentiferId = @"PrintTableViewCellid";
    PrintTableViewCell  *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentiferId];
    if (cell == nil) {
        
        NSArray *nibs = [[NSBundle mainBundle]loadNibNamed:@"PrintTableViewCell" owner:nil options:nil];
        cell = [nibs lastObject];
        cell.backgroundColor = [UIColor clearColor];
        
        // name
        cell.nameLabel.text = [[_listDevices objectAtIndex:indexPath.row] name];
        // uuid
        NSString* uuid = [NSString stringWithFormat:@"%@", [[_listDevices objectAtIndex:indexPath.row] identifier]];
        uuid = [uuid substringFromIndex:[uuid length] - 13];
        cell.uuidLabel.text = uuid;
    }
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    self.peripheral =[_listDevices objectAtIndex:indexPath.row];
}

@end
