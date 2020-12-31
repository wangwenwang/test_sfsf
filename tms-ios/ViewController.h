//
//  ViewController.h
//  tms-ios
//
//  Created by wenwang wang on 2018/9/10.
//  Copyright © 2018年 wenwang wang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ZipArchive.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import "Tools.h"
#import <MapKit/MapKit.h>
#import "ServiceTools.h"
#import "AppDelegate.h"
#import "CheckOrderPathViewController.h"
#import "IOSToVue.h"

/***************   扫码组件开始   *************/
#import <Foundation/Foundation.h>
#import "LBXScanTypes.h"

//UI
#ifdef LBXScan_Define_UI
#import "LBXScanView.h"
#endif


#ifdef LBXScan_Define_Native
#import "LBXScanNative.h" //原生扫码封装
#endif

#ifdef LBXScan_Define_ZXing
#import "ZXingWrapper.h" //ZXing扫码封装
#endif

#ifdef LBXScan_Define_ZBar
#import "ZBarSDK.h"
#import "LBXZBarWrapper.h"//ZBar扫码封装
#endif

typedef NS_ENUM(NSInteger, SCANLIBRARYTYPA) {
    SLT_Nativa,
    SLT_ZXina,
    SLT_ZBaa
};

// @[@"QRCode",@"BarCode93",@"BarCode128",@"BarCodeITF",@"EAN13"];
typedef NS_ENUM(NSInteger, SCANCODETYPA) {
    SCT_QRCoda, //QR二维码
    SCT_BarCode9a,
    SCT_BarCode12a,//支付条形码(支付宝、微信支付条形码)
    SCT_BarCodeITa,//燃气回执联 条形码?
    SCT_BarEAN1a //一般用做商品码
};

/**
 扫码结果delegate,也可通过继承本控制器，override方法scanResultWithArray即可
 */
@protocol fdsViewControllerDelegate <NSObject>
@optional
- (void)scanResultWithArray:(NSArray<LBXScanResult*>*)array;
@end
/***************   扫码组件结束   *************/


@interface ViewController : UIViewController<UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@property (strong, nonatomic) WKWebView *webView;

- (void)addWebView;


/***************   扫码组件开始   *************/
#pragma mark ---- 需要初始化参数 ------
//当前选择的扫码库
@property (nonatomic, assign) SCANLIBRARYTYPA libraryType;

//

/**
 当前选择的识别码制
 - ZXing暂不支持类型选择
 */
@property (nonatomic, assign) SCANCODETYPA scanCodeTypa;



//扫码结果委托，另外一种方案是通过继承本控制器，override方法scanResultWithArray即可
@property (nonatomic, weak) id<fdsViewControllerDelegate> delegate;


/**
 @brief 是否需要扫码图像
 */
@property (nonatomic, assign) BOOL isNeedScanImage;



/**
 @brief  启动区域识别功能，ZBar暂不支持
 */
@property(nonatomic,assign) BOOL isOpenInterestRect;


/**
 相机启动提示,如 相机启动中...
 */
@property (nonatomic, copy) NSString *cameraInvokeMsg;

/**
 *  界面效果参数
 */
#ifdef LBXScan_Define_UI
@property (nonatomic, strong) LBXScanViewStyle *style;
#endif



#pragma mark -----  扫码使用的库对象 -------

#ifdef LBXScan_Define_Native
/**
 @brief  扫码功能封装对象
 */
@property (nonatomic,strong) LBXScanNative* scanObj;

#endif


#ifdef LBXScan_Define_ZXing
/**
 ZXing扫码对象
 */
@property (nonatomic, strong) ZXingWrapper *zxingObj;
#endif



#ifdef LBXScan_Define_ZBar
/**
 ZBar扫码对象
 */
@property (nonatomic, strong) LBXZBarWrapper *zbarObj;

#endif




#pragma mark - 扫码界面效果及提示等
/**
 @brief  扫码区域视图,二维码一般都是框
 */

#ifdef LBXScan_Define_UI
@property (nonatomic,strong) LBXScanView* qRScanView;
#endif



/**
 @brief  扫码存储的当前图片
 */
@property(nonatomic,strong) UIImage* scanImage;


/**
 @brief  闪关灯开启状态记录
 */
@property(nonatomic,assign)BOOL isOpenFlash;





//打开相册
- (void)openLocalPhoto:(BOOL)allowsEditing;

//开关闪光灯
- (void)openOrCloseFlash;

//启动扫描
- (void)reStartDevice;

//关闭扫描
- (void)stopScan;
/***************   扫码组件结束   *************/

@end

