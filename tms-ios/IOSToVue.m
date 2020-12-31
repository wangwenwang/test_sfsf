//
//  IOSToVue.m
//  tms-ios
//
//  Created by wenwang wang on 2018/11/9.
//  Copyright © 2018年 wenwang wang. All rights reserved.
//

#import "IOSToVue.h"

@implementation IOSToVue

+ (void)TellVueMsg:(nullable WKWebView *)webView andJsStr:(nullable NSString *)jsStr {
    
    NSLog(@"%@",jsStr);
    dispatch_async(dispatch_get_main_queue(), ^{
        [webView evaluateJavaScript:jsStr completionHandler:^(id _Nullable resp, NSError * _Nullable error) {
            NSLog(@"error = %@ , response = %@",error, resp);
        }];
    });
}

+ (void)TellVueHiddenNav:(nullable WKWebView *)webView {
    
    NSString *jsStr = [NSString stringWithFormat:@"HiddenNav('')"];
    [IOSToVue TellVueMsg:webView andJsStr:jsStr];
}

+ (void)TellVueDevice:(nullable WKWebView *)webView andDevice:(nullable NSString *)dev {
    
    NSString *jsStr = [NSString stringWithFormat:@"Device_Ajax('%@')",dev];
    [IOSToVue TellVueMsg:webView andJsStr:jsStr];
}

+ (void)TellVueVersionShow:(nullable WKWebView *)webView andVersion:(nullable NSString *)version {
    
    NSString *jsStr = [NSString stringWithFormat:@"VersionShow('%@')",version];
    [IOSToVue TellVueMsg:webView andJsStr:jsStr];
}

+ (void)TellVueCurrAddress:(nullable WKWebView *)webView andAddress:(nullable NSString *)address {
    
    NSString *jsStr = [NSString stringWithFormat:@"CurrAddress('%@')",address];
    [IOSToVue TellVueMsg:webView andJsStr:jsStr];
}

@end
