//
//  IOSToVue.h
//  tms-ios
//
//

#import <Foundation/Foundation.h>

@interface IOSToVue : NSObject

/// 告诉Vue设备标识（iOS）
+ (void)TellVueDevice:(nullable WKWebView *)webView andDevice:(nullable NSString *)dev;


/// 让Vue隐藏【导航】按钮，苹果审核不允许导航跳转至其它APP（若当前地址为审核小组的地址将按钮隐藏）
+ (void)TellVueHiddenNav:(nullable WKWebView *)webView;

/// 告诉Vue版本号
+ (void)TellVueVersionShow:(nullable WKWebView *)webView andVersion:(nullable NSString *)version;


/// 告诉Vue当前地址
+ (void)TellVueCurrAddress:(nullable WKWebView *)webView andAddress:(nullable NSString *)address;

@end
