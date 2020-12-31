//
//  ViewController.m
//  tms-ios
//
//  Created by wenwang wang on 2018/9/10.
//  Copyright © 2018年 wenwang wang. All rights reserved.
//

#import "ViewController.h"
#import "XHVersion.h"
//#import "ScanCodeViewController.h"
#import "PrintViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "ScanCodeViewController.h"
#import "DIYScanViewController.h"
#import "LBXScanViewStyle.h"
#import "StyleDIY.h"
#import "Global.h"

/***************   扫码组件开始   *************/
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>
/***************   扫码组件结束   *************/


@interface ViewController ()<UIGestureRecognizerDelegate, BMKLocationServiceDelegate, ServiceToolsDelegate, CLLocationManagerDelegate, WKUIDelegate, WKScriptMessageHandler, WKNavigationDelegate> {
    
    // 百度地图定位服务
    BMKLocationService *_locationService;
    
    // 记录用户最近坐标
    CLLocationCoordinate2D _location;
    
    // 第一次上传位置
    BOOL _firstLoc;
}

// 计时器，固定间隔时间上传位置信息
@property (strong, nonatomic) NSTimer *localTimer;

// 网络层
@property (strong, nonatomic) ServiceTools *service;

// 弹出3个定位受权（包括iOS11下始终允许）
@property (strong, nonatomic) CLLocationManager *reqAuth;

// 定位延迟，始终化1，允许定位后为0。 解决iOS11下无法弹出始终允许定位权限(与原生请求定位权限冲突)
@property (assign, nonatomic) unsigned PositioningDelay;

@property (assign, nonatomic) BOOL allowUpdate;

@property (strong, nonatomic) AppDelegate *app;


/***************   扫码组件开始   *************/
// 扫码摄像头视图
@property (strong, nonatomic) UIView *videoView;
// 连续扫码时，中途延时了0.8秒，导致关闭扫码时，0.8秒后自动打开扫码bug。用这个方法解决问题
@property (assign, nonatomic) BOOL is_stop_scan;
/***************   扫码组件结束   *************/

@end

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self addWebView];
    
    UIImageView *imageV = [[UIImageView alloc] init];
    
    NSLog(@"ScreenHeight:%f", ScreenHeight);
    NSString *imageName = @"";
    
    if(ScreenHeight == 480) {
        
        // iPhone4S
        imageName = @"640 × 960";
    }else if(ScreenHeight == 568){
        
        // iPhone5S、iPhoneSE
        imageName = @"640 × 1136";
    }else if(ScreenHeight == 667){
        
        // iPhone6、iPhone6S、iPhone7、iPhone8
        imageName = @"750 × 1334";
    }else if(ScreenHeight == 736){
        
        // iPhone6P、iPhone6SP、iPhone7P、iPhone8P
        imageName = @"1242 × 2208";
    }else if(ScreenHeight == 812){
        
        // iPhoneX、iPhoneXS
        imageName = @"1125 × 2436";
    }else {
        
        // iPhoneXR、iPhoneXSMAX
        imageName = @"1125 × 2436";
        [Tools showAlert:self.view andTitle:@"未知设备" andTime:5];
    }
    
    [imageV setImage:[UIImage imageNamed:imageName]];
    [imageV setFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight)];
    [self.view addSubview:imageV];
    
    [UIView animateWithDuration:0.8 delay:0.8 options:0 animations:^{
        
        [imageV setAlpha:0];
    } completion:^(BOOL finished) {
        
        [imageV removeFromSuperview];
    }];
    
    

    
    
    /***************   扫码组件开始   *************/
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
        
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    self.view.backgroundColor = [UIColor blackColor];
    

    switch (_libraryType) {
        case SLT_Nativa:
            self.title = @"native";
            break;
        case SLT_ZXina:
            self.title = @"ZXing";
            break;
        case SLT_ZBaa:
            self.title = @"ZBar";
            break;
        default:
            break;
    }
    /***************   扫码组件结束   *************/
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
}


- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
}


// webViewDidFinishLoad方法晚于vue的mounted函数 0.3秒左右，不采用
- (void)webViewDidStartLoad:(WKWebView *)webView{
    
    // iOS监听vue的函数
    JSContext *context = [self.webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    context[@"CallAndroidOrIOS"] = ^() {
        NSString * first = @"";
        NSString * second = @"";
        NSString * third = @"";
        NSArray *args = [JSContext currentArguments];
        for (JSValue *jsVal in args) {
            first = jsVal.toString;
            break;
        }
        @try {
            JSValue *jsVal = args[1];
            second = jsVal.toString;
        } @catch (NSException *exception) { }
        @try {
            JSValue *jsVal = args[2];
            third = jsVal.toString;
        } @catch (NSException *exception) { }
        
        // 第一次加载登录页，不执行此函数，所以还写了一个定时器
        if([first isEqualToString:@"登录页面已加载"]) {
            
            // 销毁定时器
            [_localTimer invalidate];
            
            // 发送APP版本号
            [IOSToVue TellVueVersionShow:_webView andVersion:[NSString stringWithFormat:@"版本:%@", [Tools getCFBundleShortVersionString]]];
            
            // 发送设备标识
            [IOSToVue TellVueDevice:_webView andDevice:@"iOS"];
            
            // 停止定位功能、销毁定时器
            [_localTimer invalidate];
//            [_locationService stopUserLocationService];
        }
        // 导航
        else if([first isEqualToString:@"导航"]) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self doNavigationWithEndLocation:second];
            });
        }
        // 查看路线
        else if([first isEqualToString:@"查看路线"]) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self showLocLine:second];
            });
        }
        // 记住帐号密码，开始定位
        else if([first isEqualToString:@"记住帐号密码"]) {
            
            // 启用定时器
            [self startUpdataLocationTimer];
            
            if([Tools isLocationServiceOpen]) {
                
                _PositioningDelay = 0;
            } else {
                
                _PositioningDelay = 1;
            }
            
            // 判断定位权限  延迟检查，因为用户首次选择需要时间
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                
                NSString *enter = [Tools getEnterTheHomePage];
                if([enter isEqualToString:@"YES"]) {
                    sleep(3);
                }else {
                    sleep(10);
                }
                [Tools setEnterTheHomePage:@"YES"];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    if([Tools isLocationServiceOpen]) {
                        NSLog(@"应用拥有定位权限");
                    } else {
                        [Tools skipLocationSettings];
                    }
                });
            });
            
            // 解决iOS11下无法弹出始终允许定位权限(与原生请求定位权限冲突)
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                
                sleep(_PositioningDelay);
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    _app.cellphone = second;
                    
                    _locationService = [[BMKLocationService alloc] init];
                    _locationService.delegate = self;
                    //启动LocationService
                    [_locationService startUserLocationService];
                    //设置定位精度
                    _locationService.desiredAccuracy = kCLLocationAccuracyHundredMeters;
                    //指定最小距离更新(米)，默认：kCLDistanceFilterNone
                    _locationService.distanceFilter = 0;
                    if(SystemVersion > 9.0) {
                        _locationService.allowsBackgroundLocationUpdates = YES;
                    }
                    _locationService.pausesLocationUpdatesAutomatically = NO;
                });
            });
            if(!_service) {
                _service = [[ServiceTools alloc] init];
            }
            _service.delegate = self;
        }
        // 获取当前位置页面已加载，预留接口，防止js获取当前位置出问题
        else if([first isEqualToString:@"获取当前位置页面已加载"]) {
            
//            [IOSToVue TellVueCurrAddress:_webView andAddress:[NSString stringWithFormat:@"坐标:%@", ]];
//            [_service reverseGeo:_app.cellphone andLon:_location.longitude andLat:_location.latitude andWebView:_webView andTimingTrackingOrTellVue:GeoOfTellVue];
        }
        else if([first isEqualToString:@"打印"]){

            // 打印数据
//            NSArray *arrayArgument = [Tools jsonToObject:second];
            
            // 打印数据
            NSString* pArgument1_json = second;
            NSArray *arrayArgument = [Tools jsonToObject:pArgument1_json];
            
            
            // 判断数据里哪个是字典，哪个是数组
            NSDictionary *dic = nil;
            NSArray *array = nil;
            id arr_0 = arrayArgument[0];
            id arr_1 = arrayArgument[1];
            if([arr_0 isKindOfClass:[NSArray class]]){
                array = (NSArray *)arr_0;
            }else if([arr_1 isKindOfClass:[NSArray class]]){
                array = (NSArray *)arr_1;
            }
            if([arr_0 isKindOfClass:[NSDictionary class]]){
                dic = (NSDictionary *)arr_0;
            }else if([arr_1 isKindOfClass:[NSDictionary class]]){
                dic = (NSDictionary *)arr_1;
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                PrintViewController *vc = [[PrintViewController alloc] init];
                vc.arr = array;
                vc.dic = dic;
                [self presentViewController:vc animated:YES completion:nil];
                            
            });
            
        }
        // 检查更新
         else if([first isEqualToString:@"检查版本更新"]) {
                    
                    // 检查更新
                    [XHVersion checkNewVersion];
                    
                    // 2.如果你需要自定义提示框,请使用下面方法
                    [XHVersion checkNewVersionAndCustomAlert:^(XHAppInfo *appInfo) {
                        
                        NSLog(@"新版本信息:\n 版本号 = %@ \n 更新时间 = %@\n 更新日志 = %@ \n 在AppStore中链接 = %@\n AppId = %@ \n bundleId = %@" ,appInfo.version,appInfo.currentVersionReleaseDate,appInfo.releaseNotes,appInfo.trackViewUrl,appInfo.trackId,appInfo.bundleId);
                    } andNoNewVersionBlock:^(XHAppInfo *appInfo) {
                        
        #if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_8_0
                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"已经是最新版本" message:@"" delegate:self cancelButtonTitle:@"确定", nil];
                        [alertView show];
        #endif
                        
        #if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_8_0
                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"已经是最新版本" message:@"" preferredStyle:UIAlertControllerStyleAlert];
                        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        }]];
                        [self presentViewController:alert animated:YES completion:nil];
        #endif
                    }];
                }
        else if([first isEqualToString:@"调用app原生扫描二维码/条码"]) {
            
            [self scanQRCode];
        }
        NSLog(@"js传ios：%@   %@   %@",first, second, third);
    };
}


#pragma mark - 功能函数

// 跳到扫码控制器
- (void)skipScan {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        DIYScanViewController *vc = [DIYScanViewController new];
        vc.style = [StyleDIY weixinStyle];
//        vc.isOpenInterestRect = YES;
        vc.libraryType = 1;
        vc.webView = self.webView;
        vc.scanCodeType = [Global sharedManager].scanCodeType;
        [self presentViewController:vc animated:YES completion:nil];
        
//        ScanCodeViewController *vc = [[ScanCodeViewController alloc] init];
//        vc.webView = self.webView;
//        [self presentViewController:vc animated:YES completion:nil];
    });
}


- (void)scanQRCode {
    
    // 1、 获取摄像设备
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (device) {
        AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        if (status == AVAuthorizationStatusNotDetermined) {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (granted) {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        
                        [self skipScan];
                    });
                    // 用户第一次同意了访问相机权限
                    NSLog(@"用户第一次同意了访问相机权限 - - %@", [NSThread currentThread]);
                    
                } else {
                    // 用户第一次拒绝了访问相机权限
                    NSLog(@"用户第一次拒绝了访问相机权限 - - %@", [NSThread currentThread]);
                }
            }];
        } else if (status == AVAuthorizationStatusAuthorized) {
            
            // 用户允许当前应用访问相机
            [self skipScan];
        } else if (status == AVAuthorizationStatusDenied) {
            
            // 用户拒绝当前应用访问相机
            UIAlertController *alertC = [UIAlertController alertControllerWithTitle:@"温馨提示" message:@"请去-> [设置 - 隐私 - 相机 - wms] 打开访问开关" preferredStyle:(UIAlertControllerStyleAlert)];
            UIAlertAction *alertA = [UIAlertAction actionWithTitle:@"确定" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
                
            }];
            
            [alertC addAction:alertA];
            [self presentViewController:alertC animated:YES completion:nil];
            
        } else if (status == AVAuthorizationStatusRestricted) {
            NSLog(@"因为系统原因, 无法访问相册");
        }
    } else {
        UIAlertController *alertC = [UIAlertController alertControllerWithTitle:@"温馨提示" message:@"未检测到您的摄像头" preferredStyle:(UIAlertControllerStyleAlert)];
        UIAlertAction *alertA = [UIAlertAction actionWithTitle:@"确定" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        
        [alertC addAction:alertA];
        [self presentViewController:alertC animated:YES completion:nil];
    }
}


//导航只需要目的地经纬度，endLocation为纬度、经度的数组
-(void)doNavigationWithEndLocation:(NSString *)address {
    
    NSMutableArray *maps = [NSMutableArray array];
    
    //苹果原生地图-苹果原生地图方法和其他不一样
    NSMutableDictionary *iosMapDic = [NSMutableDictionary dictionary];
    iosMapDic[@"title"] = @"苹果地图";
    [maps addObject:iosMapDic];
    
    //高德地图
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"iosamap://"]]) {
        NSMutableDictionary *gaodeMapDic = [NSMutableDictionary dictionary];
        gaodeMapDic[@"title"] = @"高德地图";
        NSString *urlString = [NSString stringWithFormat:@"iosamap://path?sourceApplication=顺行极丰+&sid=BGVIS1&slat=&slon=&sname=&did=BGVIS2&dname=%@&dev=0&t=0", address];
        urlString = [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        gaodeMapDic[@"url"] = urlString;
        [maps addObject:gaodeMapDic];
    }
    
    //百度地图
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"baidumap://"]]) {
        NSMutableDictionary *baiduMapDic = [NSMutableDictionary dictionary];
        baiduMapDic[@"title"] = @"百度地图";
        NSString *urlString = [NSString stringWithFormat:@"baidumap://map/direction?destination=%@&mode=driving&coord_type=gcj02", address];
        urlString = [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        baiduMapDic[@"url"] = urlString;
        [maps addObject:baiduMapDic];
    }
    
    //谷歌地图
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"comgooglemaps://"]]) {
        NSMutableDictionary *googleMapDic = [NSMutableDictionary dictionary];
        googleMapDic[@"title"] = @"谷歌地图";
        NSString *urlString = [[NSString stringWithFormat:@"comgooglemaps://?x-source=%@&x-success=%@&saddr=&daddr=%@&directionsmode=driving",@"导航测试",@"nav123456", address] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        googleMapDic[@"url"] = urlString;
        [maps addObject:googleMapDic];
    }
    
    //选择
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"选择地图" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alert addAction:([UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil])];
    
    NSInteger index = maps.count;
    
    for (int i = 0; i < index; i++) {
        
        NSString * title = maps[i][@"title"];
        
        //苹果原生地图方法
        if (i == 0) {
            
            UIAlertAction * action = [UIAlertAction actionWithTitle:title style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
                // 起点
                MKMapItem *currentLocation = [MKMapItem mapItemForCurrentLocation];
                
                // 终点
                CLGeocoder *geo = [[CLGeocoder alloc] init];
                [geo geocodeAddressString:address completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
                    
                    CLPlacemark *endMark=placemarks.firstObject;
                    MKPlacemark *mkEndMark=[[MKPlacemark alloc]initWithPlacemark:endMark];
                    MKMapItem *endItem=[[MKMapItem alloc]initWithPlacemark:mkEndMark];
                    NSDictionary *dict=@{
                                         MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving,
                                         MKLaunchOptionsMapTypeKey:@(MKMapTypeStandard),
                                         MKLaunchOptionsShowsTrafficKey:@(YES)
                                         };
                    [MKMapItem openMapsWithItems:@[currentLocation,endItem] launchOptions:dict];\
                }];
            }];
            [alert addAction:action];
            
            continue;
        }
        
        
        UIAlertAction * action = [UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            NSString *urlString = maps[i][@"url"];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
        }];
        
        [alert addAction:action];
        
    }
    
    [self presentViewController:alert animated:YES completion:nil];
}


#pragma mark GET方法
- (void)addWebView {
    
    if(_webView == nil) {
        
        // wk代理
        WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
        config.userContentController = [[WKUserContentController alloc] init];
        [config.userContentController addScriptMessageHandler:self name:@"messageSend"];
        config.preferences = [[WKPreferences alloc] init];
        config.preferences.minimumFontSize = 0;
        config.preferences.javaScriptEnabled = YES;
        config.preferences.javaScriptCanOpenWindowsAutomatically = NO;
        
        _webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, kStatusHeight, ScreenWidth, ScreenHeight - kStatusHeight - SafeAreaBottomHeight) configuration:config];
        
        NSString *unzipPath = [Tools getUnzipPath];
        NSLog(@"unzipPath:%@", unzipPath);
        
        NSString *checkFilePath = [unzipPath  stringByAppendingPathComponent:@"dist/index.html"];
        NSFileManager *fileManager = [NSFileManager defaultManager];
                
        //
        //        if ([fileManager fileExistsAtPath:checkFilePath] && [[Tools getLastVersion] isEqualToString:[Tools getCFBundleShortVersionString]]) {
        //
        //            NSLog(@"HTML已存在，无需解压");
        //        } else {
                    
                    NSLog(@"第一次加载，或版本有更新，解压");
                    NSString *zipPath = [[NSBundle mainBundle] pathForResource:@"dist" ofType:@"zip"];
                    NSLog(@"zipPath:%@", zipPath);
                    [SSZipArchive unzipFileAtPath:zipPath toDestination:unzipPath];
        //        }
                
        [Tools setLastVersion];
        
        // 加载URL
        NSString *basePath = [NSString stringWithFormat:@"%@/dist/%@", unzipPath, @""];
        NSURL *baseUrl = [NSURL fileURLWithPath:basePath];
        NSURL *fileUrl = [self fileURLForBuggyWKWebView8WithFileURL:baseUrl];
        
        [_webView loadRequest:[NSURLRequest requestWithURL:fileUrl]];
        
        _webView.UIDelegate = self;
        _webView.navigationDelegate = self;
        [self.view addSubview:_webView];
        
        // 监听_webview 的状态
        [_webView addObserver:self forKeyPath:@"loading" options:NSKeyValueObservingOptionNew context:nil];
        [_webView addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:nil];
        [_webView addObserver:self forKeyPath:@"estimaedProgress" options:NSKeyValueObservingOptionNew context:nil];
        
        // 初始化信息
        _app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        _allowUpdate = YES;
        
        // 长按5秒，开启webview编辑模式
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(longPress:)];
        longPress.delegate = self;
        longPress.minimumPressDuration = 5;
        [_webView addGestureRecognizer:longPress];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kReceive_WebView_Notification object:nil userInfo:@{@"webView":_webView}];
        // 禁用弹簧效果
        for (id subview in _webView.subviews){
            if ([[subview class] isSubclassOfClass: [UIScrollView class]]) {
                ((UIScrollView *)subview).bounces = NO;
            }
        }
        // 取消右侧，下侧滚动条，去处上下滚动边界的黑色背景
        for (UIView *_aView in [_webView subviews]) {
            if ([_aView isKindOfClass:[UIScrollView class]]) {
                [(UIScrollView *)_aView setShowsVerticalScrollIndicator:NO];
                // 右侧的滚动条
                [(UIScrollView *)_aView setShowsHorizontalScrollIndicator:NO];
                // 下侧的滚动条
                for (UIView *_inScrollview in _aView.subviews) {
                    if ([_inScrollview isKindOfClass:[UIImageView class]]) {
                        _inScrollview.hidden = YES;  // 上下滚动出边界时的黑色的图片
                    }
                }
            }
        }
    }
}

- (NSURL *)fileURLForBuggyWKWebView8WithFileURL: (NSURL *)fileURL {
    NSError *error = nil;
    if (!fileURL.fileURL || ![fileURL checkResourceIsReachableAndReturnError:&error]) {
        return nil;
    }
    NSFileManager *fileManager= [NSFileManager defaultManager];
    NSURL *temDirURL = [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:@"www"];
    [fileManager createDirectoryAtURL:temDirURL withIntermediateDirectories:YES attributes:nil error:&error];
     NSURL *htmlDestURL = [temDirURL URLByAppendingPathComponent:fileURL.lastPathComponent];
    [fileManager removeItemAtURL:htmlDestURL error:&error];
    [fileManager copyItemAtURL:fileURL toURL:htmlDestURL error:&error];
    NSURL *finalHtmlDestUrl = [htmlDestURL URLByAppendingPathComponent:@"index.html"];
    return finalHtmlDestUrl;
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"loading"]) {
        NSLog(@"loading");
    }else if ([keyPath isEqualToString:@"title"]){
        self.title = self.webView.title;
    }else if ([keyPath isEqualToString:@"estimaedProgress"]){
//       self.progressView.progress = self.webView.estimatedProgress;
    }
}

#pragma mark - WKScriptMessageHandler
//当js 通过 注入的方法 @“messageSend” 时会调用代理回调。 原生收到的所有信息都通过此方法接收。
-(void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    
    NSLog(@"原生收到了js发送过来的消息 message.body = %@",message.body);
    
    __weak __typeof(self)weakSelf = self;
    
    if([message.name isEqualToString:@"messageSend"]){
        // 第一次加载登录页，不执行此函数，所以还写了一个定时器
        if([message.body[@"a"] isEqualToString:@"登录页面已加载"]) {
            
            // 销毁定时器
            [_localTimer invalidate];
            
            // 发送APP版本号
            [IOSToVue TellVueVersionShow:_webView andVersion:[NSString stringWithFormat:@"版本:%@", [Tools getCFBundleShortVersionString]]];
            
            // 发送设备标识
            [IOSToVue TellVueDevice:_webView andDevice:@"iOS"];
            
            // 停止定位功能、销毁定时器
//            [_localTimer invalidate];
//            [_locationService stopUserLocationService];
        }
        else if([message.body[@"a"] isEqualToString:@"导航"]){
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self doNavigationWithEndLocation:message.body[@"b"]];
            });
        }
        // 查看路线
        else if([message.body[@"a"] isEqualToString:@"查看路线"]){
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self showLocLine:message.body[@"b"]];
            });
        }
        // 记住帐号密码，开始定位
        else if([message.body[@"a"] isEqualToString:@"记住帐号密码"]){
            // 启用定时器
            [self startUpdataLocationTimer];
            
            if([Tools isLocationServiceOpen]) {
                
                _PositioningDelay = 0;
            } else {
                
                _PositioningDelay = 1;
            }
            
            // 判断定位权限  延迟检查，因为用户首次选择需要时间
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                
                NSString *enter = [Tools getEnterTheHomePage];
                if([enter isEqualToString:@"YES"]) {
                    sleep(3);
                }else {
                    sleep(10);
                }
                [Tools setEnterTheHomePage:@"YES"];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    if([Tools isLocationServiceOpen]) {
                        NSLog(@"应用拥有定位权限");
                    } else {
                        [Tools skipLocationSettings];
                    }
                });
            });
            
            // 解决iOS11下无法弹出始终允许定位权限(与原生请求定位权限冲突)
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                
                sleep(_PositioningDelay);
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    _app.cellphone = message.body[@"b"];
                    
                    _locationService = [[BMKLocationService alloc] init];
                    _locationService.delegate = self;
                    //启动LocationService
                    [_locationService startUserLocationService];
                    //设置定位精度
                    _locationService.desiredAccuracy = kCLLocationAccuracyHundredMeters;
                    //指定最小距离更新(米)，默认：kCLDistanceFilterNone
                    _locationService.distanceFilter = 0;
                    if(SystemVersion > 9.0) {
                        _locationService.allowsBackgroundLocationUpdates = YES;
                    }
                    _locationService.pausesLocationUpdatesAutomatically = NO;
                });
            });
            if(!_service) {
                _service = [[ServiceTools alloc] init];
            }
            _service.delegate = self;
        }
        // 查看路线
        else if([message.body[@"a"] isEqualToString:@"打印"]){
            // 打印数据
            //            NSArray *arrayArgument = [Tools jsonToObject:second];
            
            // 打印数据
            NSString* pArgument1_json = message.body[@"b"];
            NSArray *arrayArgument = [Tools jsonToObject:pArgument1_json];
            
            
            // 判断数据里哪个是字典，哪个是数组
            NSDictionary *dic = nil;
            NSArray *array = nil;
            id arr_0 = arrayArgument[0];
            id arr_1 = arrayArgument[1];
            if([arr_0 isKindOfClass:[NSArray class]]){
                array = (NSArray *)arr_0;
            }else if([arr_1 isKindOfClass:[NSArray class]]){
                array = (NSArray *)arr_1;
            }
            if([arr_0 isKindOfClass:[NSDictionary class]]){
                dic = (NSDictionary *)arr_0;
            }else if([arr_1 isKindOfClass:[NSDictionary class]]){
                dic = (NSDictionary *)arr_1;
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                PrintViewController *vc = [[PrintViewController alloc] init];
                vc.arr = array;
                vc.dic = dic;
                [self presentViewController:vc animated:YES completion:nil];
                
            });
        }
        // 检查更新
        else if([message.body[@"a"] isEqualToString:@"检查版本更新"]){
            // 检查更新
            [XHVersion checkNewVersion];
            
            // 2.如果你需要自定义提示框,请使用下面方法
            [XHVersion checkNewVersionAndCustomAlert:^(XHAppInfo *appInfo) {
                
                NSLog(@"新版本信息:\n 版本号 = %@ \n 更新时间 = %@\n 更新日志 = %@ \n 在AppStore中链接 = %@\n AppId = %@ \n bundleId = %@" ,appInfo.version,appInfo.currentVersionReleaseDate,appInfo.releaseNotes,appInfo.trackViewUrl,appInfo.trackId,appInfo.bundleId);
            } andNoNewVersionBlock:^(XHAppInfo *appInfo) {
                
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_8_0
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"已经是最新版本" message:@"" delegate:self cancelButtonTitle:@"确定", nil];
                [alertView show];
#endif
                
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_8_0
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"已经是最新版本" message:@"" preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                }]];
                [self presentViewController:alert animated:YES completion:nil];
#endif
            }];
        }
        else if([message.body[@"a"] isEqualToString:@"调用app原生扫描二维码/条码"]){
            
            [self scanQRCode];
            
//            dispatch_async(dispatch_get_global_queue(0, 0), ^{
//
//                dispatch_async(dispatch_get_main_queue(), ^{
//
//                    [self skipScan];
//                });
            //            });
        }
        else if([message.body[@"a"] isEqualToString:@"调用app原生半屏扫描二维码/条码"]){
            
            [self start_scan];
        }
        else if([message.body[@"a"] isEqualToString:@"离开app原生半屏扫描二维码/条码"]){
            
            [self stop_scan];
        }
        else if([message.body[@"a"] isEqualToString:@"打开或关闭闪光灯"]){
            
            [self openOrCloseFlash];
        }
        else if([message.body[@"a"] isEqualToString:@"拍照完成"]){
            
            // 拍照后，重启扫码功能
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                sleep(2);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self start_scan];
                });
            });
        }
    }
}


#pragma mark - WKUIDelegate
//通过js alert 显示一个警告面板，调用原生会走此方法。
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler
{
    NSLog(@"显示一个JavaScript警告面板, message = %@",message);

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"温馨提示" message:message preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();
    }]];
    
    [self presentViewController:alertController animated:YES completion:nil];
}
//通过 js confirm 显示一个确认面板，调用原生会走此方法。
- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler
{
    NSLog(@"运行JavaScript确认面板， message = %@", message);
    UIAlertController *action = [UIAlertController alertControllerWithTitle:@"温馨提示" message:message preferredStyle:UIAlertControllerStyleAlert];
    [action addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(NO);
    }] ];
    
    [action addAction:[UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(YES);
    }]];
    
    [self presentViewController:action animated:YES completion:nil];

}
//显示输入框
- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(nullable NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable result))completionHandler
{
    
    NSLog(@"显示一个JavaScript文本输入面板, message = %@",prompt);
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:defaultText message:prompt preferredStyle:UIAlertControllerStyleAlert];
    
    [controller addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.textColor = [UIColor redColor];
    }];
    
    [controller addAction:[UIAlertAction actionWithTitle:@"输入信息" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler([[controller.textFields lastObject] text]);
    }]];
    
    [self presentViewController:controller animated:YES completion:nil];
    
}

#pragma mark - WKWebViewDelegate

- (void)webViewDidFinishLoad:(WKWebView *)webView {
    
    [Tools closeWebviewEdit:_webView];
}

-(void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    NSLog(@"加载完成");
}


#pragma mark 长按手势事件
-(void)longPress:(UILongPressGestureRecognizer *)sender{
    
    if (sender.state == UIGestureRecognizerStateBegan) {
        
        NSLog(@"打开编辑模式");
        [Tools openWebviewEdit:_webView];
        
        // 开启编辑模式后30秒将关闭
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            
            usleep(30 * 1000000);
            dispatch_async(dispatch_get_main_queue(), ^{
                
                NSLog(@"关闭编辑模式");
                [Tools closeWebviewEdit:_webView];
            });
        });
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    
    return YES;
}


#pragma mark - 功能函数

// 查看路线
- (void)showLocLine:(NSString *)shipmentId {
    
    CheckOrderPathViewController *vc = [[CheckOrderPathViewController alloc] init];
    vc.orderIDX = shipmentId;
    [self presentViewController:vc animated:YES completion:nil];
}

// 上传位置信息
- (void)updataLocation:(NSTimer *)timer {
    
    CLLocationCoordinate2D _lo = _location;
    if(_lo.latitude != 0 & _lo.longitude != 0)  {
        
        //判断连接状态
        if([Tools isConnectionAvailable]) {
            
            [_service reverseGeo:_app.cellphone andLon:_location.longitude andLat:_location.latitude andWebView:_webView];
        }
    }
}

// 开启间隔时间上传位置点计时器
- (void)startUpdataLocationTimer {
    if(_localTimer != nil) {
        [_localTimer invalidate];
        NSLog(@"关闭定时上传位置点信息计时器");
    }
    _localTimer = [NSTimer scheduledTimerWithTimeInterval:10 * 60 target:self selector:@selector(updataLocation:) userInfo:nil repeats:YES];
    NSLog(@"开启定时上传位置点信息计时器");
    _firstLoc = YES;
}

#pragma mark - 百度地图
- (void)didUpdateBMKUserLocation:(BMKUserLocation *)userLocation {
    
    _location = userLocation.location.coordinate;
    _app.currLatlng = userLocation.location.coordinate;
    NSLog(@"位置：%f   %f  ", _location.longitude, _location.latitude);
    
    if(_firstLoc) {
        
        [_service reverseGeo:_app.cellphone andLon:_location.longitude andLat:_location.latitude andWebView:_webView];
        _firstLoc = NO;
    }
}

#pragma mark - WKNavigationDelegate 打电话
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(nonnull WKNavigationAction *)navigationAction decisionHandler:(nonnull void (^)(WKNavigationActionPolicy))decisionHandler{
    NSURL *url = navigationAction.request.URL;
    NSString *scheme = [url scheme];
    UIApplication *app = [UIApplication sharedApplication];
    WKNavigationActionPolicy actionPolicy = WKNavigationActionPolicyAllow;

    if ([scheme isEqualToString:@"tel"]) {
        if ([app canOpenURL:url]) {
            CGFloat version = [[[UIDevice currentDevice]systemVersion]floatValue];
            if (version >= 10.0) {
                /// 大于等于10.0系统使用此openURL方法
                [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
            } else {
                [[UIApplication sharedApplication] openURL:url];
            }
        }
    }
    /* 这句话一定要实现 不然会异常 */
    decisionHandler(actionPolicy);
}



/***************   扫码组件开始   *************/
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.style = [StyleDIY weixinStyle];
    self.libraryType = 1;
    self.scanCodeTypa = [Global sharedManager].scanCodeTypa;
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self drawScanView];
    
    [self requestCameraPemissionWithResult:^(BOOL granted) {
        
        if (granted) {
            
            //不延时，可能会导致界面黑屏并卡住一会
            [self performSelector:@selector(startScan) withObject:nil afterDelay:0.3];
            
        }else{
            
#ifdef LBXScan_Define_UI
            [self.qRScanView stopDeviceReadying];
#endif
            
        }
    }];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        sleep(1);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self stopScan];
        });
    });
}

- (void)start_scan{
    
    _is_stop_scan = NO;
    [self.videoView setAlpha:1];
    [self.qRScanView setAlpha:1];
    [self startScan];
    
}

- (void)stop_scan{
    
    _is_stop_scan = YES;
    [self.videoView setAlpha:0];
    [self.qRScanView setAlpha:0];
    [self stopScan];
    [_scanObj stopScan];
}

//绘制扫描区域
- (void)drawScanView
{
#ifdef LBXScan_Define_UI
    
    if (!_qRScanView)
    {
        int margin_top = 20 + 45;
        if (@available(iOS 11.0,*)) {
            margin_top = self.view.safeAreaInsets.top + 45;
        }
        self.qRScanView = [[LBXScanView alloc]initWithFrame:CGRectMake(0, margin_top, ScreenWidth, 140) style:_style];
        self.qRScanView.alpha = 0;
        [self.view addSubview:_qRScanView];
        [self.qRScanView setAlpha:0];
    }
    
    if (!_cameraInvokeMsg) {
        
//        _cameraInvokeMsg = NSLocalizedString(@"wating...", nil);
    }
    
    [_qRScanView startDeviceReadyingWithText:_cameraInvokeMsg];
#endif
}

- (void)reStartDevice
{
    switch (_libraryType) {
        case SLT_Nativa:
        {
#ifdef LBXScan_Define_Native
            [_scanObj startScan];
#endif
        }
            break;
        case SLT_ZXina:
        {
#ifdef LBXScan_Define_ZXing
            [_zxingObj start];
#endif
        }
            break;
        case SLT_ZBaa:
        {
#ifdef LBXScan_Define_ZBar
            [_zbarObj start];
#endif
        }
            break;
        default:
            break;
    }
    
}

//启动设备
- (void)startScan
{
    if(!_videoView){
        int margin_top = 20 + 45;
        if (@available(iOS 11.0,*)) {
            margin_top = self.view.safeAreaInsets.top + 45;
        }
        _videoView = [[UIView alloc]initWithFrame:CGRectMake(0, margin_top, ScreenWidth, 140)];
        _videoView.alpha = 0;
    }
    _videoView.backgroundColor = [UIColor clearColor];
    [self.view insertSubview:_videoView atIndex:1];
    __weak __typeof(self) weakSelf = self;
    
    switch (_libraryType) {
        case SLT_Nativa:
        {

            
#ifdef LBXScan_Define_Native
            
            if (!_scanObj )
            {
                CGRect cropRect = CGRectZero;
                
                if (_isOpenInterestRect) {
                    
                    //设置只识别框内区域
                    cropRect = [LBXScanView getScanRectWithPreView:self.view style:_style];
                }

                NSString *strCode = AVMetadataObjectTypeQRCode;
                if (_scanCodeTypa != SCT_BarCodeITa ) {
                    
                    strCode = [self nativeCodeWithType:_scanCodeTypa];
                }
                
                //AVMetadataObjectTypeITF14Code 扫码效果不行,另外只能输入一个码制，虽然接口是可以输入多个码制
                self.scanObj = [[LBXScanNative alloc]initWithPreView:_videoView ObjectType:@[strCode] cropRect:cropRect success:^(NSArray<LBXScanResult *> *array) {
                    
                    [weakSelf scanResultWithArray:array];
                }];
                [_scanObj setNeedCaptureImage:_isNeedScanImage];
            }
            [_scanObj startScan];
#endif

        }
            break;
        case SLT_ZXina:
        {

#ifdef LBXScan_Define_ZXing
            if (!_zxingObj) {
                
                __weak __typeof(self) weakSelf = self;
                self.zxingObj = [[ZXingWrapper alloc]initWithPreView:_videoView block:^(ZXBarcodeFormat barcodeFormat, NSString *str, UIImage *scanImg) {
                    
                    LBXScanResult *result = [[LBXScanResult alloc]init];
                    result.strScanned = str;
                    result.imgScanned = scanImg;
                    result.strBarCodeType = [weakSelf convertZXBarcodeFormat:barcodeFormat];
                    
                    [weakSelf scanResultWithArray:@[result]];
                    
                }];
                
                if (_isOpenInterestRect) {
                    
                    //设置只识别框内区域
                    CGRect cropRect = [LBXScanView getZXingScanRectWithPreView:_videoView style:_style];
                                        
                     [_zxingObj setScanRect:cropRect];
                }
            }
            [_zxingObj start];
#endif
        }
            break;
        case SLT_ZBaa:
        {
#ifdef LBXScan_Define_ZBar
            if (!_zbarObj) {
                
                self.zbarObj = [[LBXZBarWrapper alloc]initWithPreView:videoView barCodeType:[self zbarTypeWithScanType:_scanCodeTypa] block:^(NSArray<LBXZbarResult *> *result) {
                    
                    //测试，只使用扫码结果第一项
                    LBXZbarResult *firstObj = result[0];
                    
                    LBXScanResult *scanResult = [[LBXScanResult alloc]init];
                    scanResult.strScanned = firstObj.strScanned;
                    scanResult.imgScanned = firstObj.imgScanned;
                    scanResult.strBarCodeType = [LBXZBarWrapper convertFormat2String:firstObj.format];
                    
                    [weakSelf scanResultWithArray:@[scanResult]];
                }];
            }
            [_zbarObj start];
#endif
        }
            break;
        default:
            break;
    }
    
#ifdef LBXScan_Define_UI
    [_qRScanView stopDeviceReadying];
    [_qRScanView startScanAnimation];
#endif
    
    self.view.backgroundColor = [UIColor clearColor];
}

#ifdef LBXScan_Define_ZBar
- (zbar_symbol_type_t)zbarTypeWithScanType:(SCANCODETYPA)type
{
    //test only ZBAR_I25 effective,why
    return ZBAR_I25;
    
//    switch (type) {
//        case SCT_QRCode:
//            return ZBAR_QRCODE;
//            break;
//        case SCT_BarCode93:
//            return ZBAR_CODE93;
//            break;
//        case SCT_BarCode128:
//            return ZBAR_CODE128;
//            break;
//        case SCT_BarEAN13:
//            return ZBAR_EAN13;
//            break;
//
//        default:
//            break;
//    }
//
//    return (zbar_symbol_type_t)type;
}
#endif

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
 
    [self stopScan];
    
#ifdef LBXScan_Define_UI
    [_qRScanView stopScanAnimation];
#endif
}

- (void)stopScan
{
    switch (_libraryType) {
        case SLT_Nativa:
        {
#ifdef LBXScan_Define_Native
            [_scanObj stopScan];
#endif
        }
            break;
        case SLT_ZXina:
        {
#ifdef LBXScan_Define_ZXing
            [_zxingObj stop];
#endif
        }
            break;
        case SLT_ZBaa:
        {
#ifdef LBXScan_Define_ZBar
            [_zbarObj stop];
#endif
        }
            break;
        default:
            break;
    }

}

#pragma mark -扫码结果处理

- (void)scanResultWithArray:(NSArray<LBXScanResult*>*)array
{
//    //设置了委托的处理
//    if (_delegate && array && array.count > 0) {
//        [_delegate scanResultWithArray:array];
//    }
    
    //经测试，可以ZXing同时识别2个二维码，不能同时识别二维码和条形码
    //    for (LBXScanResult *result in array) {
    //
    //        NSLog(@"scanResult:%@",result.strScanned);
    //    }
    
    LBXScanResult *scanResult = array[0];
    NSString *strResult = scanResult.strScanned;
    NSString *jsStr = [NSString stringWithFormat:@"TellVue_QRScanResult_Ajax('%@')", strResult];
    NSLog(@"%@", jsStr);
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"scan_code_success.wav" ofType:nil];
    if (!path) {
        /// 动态库 path 的获取
        path = [[NSBundle bundleForClass:[self class]] pathForResource:@"scan_code_success.wav" ofType:nil];
    }
    NSURL *fileUrl = [NSURL fileURLWithPath:path];
    SystemSoundID soundID = 0;
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)(fileUrl), &soundID);
    // 声音
    AudioServicesPlaySystemSound(soundID);
    // 振动
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    
    [_webView evaluateJavaScript:jsStr completionHandler:^(id _Nullable resp, NSError * _Nullable error) {
        NSLog(@"error = %@ , response = %@",error, resp);
    }];
//    self.scanImage = scanResult.imgScanned;
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        usleep(800000);
        dispatch_async(dispatch_get_main_queue(), ^{
            if(!_is_stop_scan){
                [self reStartDevice];
            }
        });
    });
}



//开关闪光灯
- (void)openOrCloseFlash
{
    
    switch (_libraryType) {
        case SLT_Nativa:
        {
#ifdef LBXScan_Define_Native
            [_scanObj changeTorch];
#endif
        }
            break;
        case SLT_ZXina:
        {
#ifdef LBXScan_Define_ZXing
            [_zxingObj openOrCloseTorch];
#endif
        }
            break;
        case SLT_ZBaa:
        {
#ifdef LBXScan_Define_ZBar
            [_zbarObj openOrCloseFlash];
#endif
        }
            break;
        default:
            break;
    }
    self.isOpenFlash =!self.isOpenFlash;
}


#pragma mark --打开相册并识别图片

/*!
 *  打开本地照片，选择图片识别
 */
- (void)openLocalPhoto:(BOOL)allowsEditing
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    picker.delegate = self;
   
    //部分机型有问题
    picker.allowsEditing = allowsEditing;
    
    
    [self presentViewController:picker animated:YES completion:nil];
}



//当选择一张图片后进入这里

-(void)imagePickerController:(UIImagePickerController*)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    __block UIImage* image = [info objectForKey:UIImagePickerControllerEditedImage];
    
    if (!image){
        image = [info objectForKey:UIImagePickerControllerOriginalImage];
    }
    
    __weak __typeof(self) weakSelf = self;
        
    switch (_libraryType) {
        case SLT_Nativa:
        {
#ifdef LBXScan_Define_Native
            if ([[[UIDevice currentDevice]systemVersion]floatValue] >= 8.0)
            {
                [LBXScanNative recognizeImage:image success:^(NSArray<LBXScanResult *> *array) {
                    [weakSelf scanResultWithArray:array];
                }];
            }
            else
            {
                [self showError:@"native低于ios8.0系统不支持识别图片条码"];
            }
#endif
        }
            break;
        case SLT_ZXina:
        {
#ifdef LBXScan_Define_ZXing
            
            [ZXingWrapper recognizeImage:image block:^(ZXBarcodeFormat barcodeFormat, NSString *str) {
                
                LBXScanResult *result = [[LBXScanResult alloc]init];
                result.strScanned = str;
                result.imgScanned = image;
                result.strBarCodeType = [self convertZXBarcodeFormat:barcodeFormat];
                
                [weakSelf scanResultWithArray:@[result]];
            }];
#endif
            
        }
            break;
        case SLT_ZBaa:
        {
#ifdef LBXScan_Define_ZBar
            [LBXZBarWrapper recognizeImage:image block:^(NSArray<LBXZbarResult *> *result) {
                
                //测试，只使用扫码结果第一项
                LBXZbarResult *firstObj = result[0];
                
                LBXScanResult *scanResult = [[LBXScanResult alloc]init];
                scanResult.strScanned = firstObj.strScanned;
                scanResult.imgScanned = firstObj.imgScanned;
                scanResult.strBarCodeType = [LBXZBarWrapper convertFormat2String:firstObj.format];
                
                [weakSelf scanResultWithArray:@[scanResult]];
                
            }];
#endif
            
        }
            break;
            
        default:
            break;
    }
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    NSLog(@"cancel");
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}


#ifdef LBXScan_Define_ZXing
- (NSString*)convertZXBarcodeFormat:(ZXBarcodeFormat)barCodeFormat
{
    NSString *strAVMetadataObjectType = nil;
    
    switch (barCodeFormat) {
        case kBarcodeFormatQRCode:
            strAVMetadataObjectType = AVMetadataObjectTypeQRCode;
            break;
        case kBarcodeFormatEan13:
            strAVMetadataObjectType = AVMetadataObjectTypeEAN13Code;
            break;
        case kBarcodeFormatEan8:
            strAVMetadataObjectType = AVMetadataObjectTypeEAN8Code;
            break;
        case kBarcodeFormatPDF417:
            strAVMetadataObjectType = AVMetadataObjectTypePDF417Code;
            break;
        case kBarcodeFormatAztec:
            strAVMetadataObjectType = AVMetadataObjectTypeAztecCode;
            break;
        case kBarcodeFormatCode39:
            strAVMetadataObjectType = AVMetadataObjectTypeCode39Code;
            break;
        case kBarcodeFormatCode93:
            strAVMetadataObjectType = AVMetadataObjectTypeCode93Code;
            break;
        case kBarcodeFormatCode128:
            strAVMetadataObjectType = AVMetadataObjectTypeCode128Code;
            break;
        case kBarcodeFormatDataMatrix:
            strAVMetadataObjectType = AVMetadataObjectTypeDataMatrixCode;
            break;
        case kBarcodeFormatITF:
            strAVMetadataObjectType = AVMetadataObjectTypeITF14Code;
            break;
        case kBarcodeFormatRSS14:
            break;
        case kBarcodeFormatRSSExpanded:
            break;
        case kBarcodeFormatUPCA:
            break;
        case kBarcodeFormatUPCE:
            strAVMetadataObjectType = AVMetadataObjectTypeUPCECode;
            break;
        default:
            break;
    }
    
    
    return strAVMetadataObjectType;
}
#endif


- (NSString*)nativeCodeWithType:(SCANCODETYPA)type
{
    switch (type) {
        case SCT_QRCoda:
            return AVMetadataObjectTypeQRCode;
            break;
        case SCT_BarCode9a:
            return AVMetadataObjectTypeCode93Code;
            break;
        case SCT_BarCode12a:
            return AVMetadataObjectTypeCode128Code;
            break;
        case SCT_BarCodeITa:
            return @"ITF条码:only ZXing支持";
            break;
        case SCT_BarEAN1a:
            return AVMetadataObjectTypeEAN13Code;
            break;

        default:
            return AVMetadataObjectTypeQRCode;
            break;
    }
}

- (void)showError:(NSString*)str
{
    
}

- (void)requestCameraPemissionWithResult:(void(^)( BOOL granted))completion
{
    if ([AVCaptureDevice respondsToSelector:@selector(authorizationStatusForMediaType:)])
    {
        AVAuthorizationStatus permission =
        [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        
        switch (permission) {
            case AVAuthorizationStatusAuthorized:
                completion(YES);
                break;
            case AVAuthorizationStatusDenied:
            case AVAuthorizationStatusRestricted:
                completion(NO);
                break;
            case AVAuthorizationStatusNotDetermined:
            {
                [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo
                                         completionHandler:^(BOOL granted) {
                                             
                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                 if (granted) {
                                                     completion(true);
                                                 } else {
                                                     completion(false);
                                                 }
                                             });
                                             
                                         }];
            }
                break;
                
        }
    }
    
    
}

+ (BOOL)photoPermission
{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0)
    {
        ALAuthorizationStatus author = [ALAssetsLibrary authorizationStatus];
        
        if ( author == ALAuthorizationStatusDenied ) {
            
            return NO;
        }
        return YES;
    }
    
    PHAuthorizationStatus authorStatus = [PHPhotoLibrary authorizationStatus];
    if ( authorStatus == PHAuthorizationStatusDenied ) {
        
        return NO;
    }
    return YES;
}
/***************   扫码组件结束   *************/

@end
