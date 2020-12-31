//
//  PrintimageTwoInOneController.m
//  tms-ios
//
//  Created by wangziting on 2020/4/11.
//  Copyright © 2020 wangziting. All rights reserved.
//

#import "PrintimageTwoInOneController.h"
#import "Tools.h"

@interface PrintimageTwoInOneController ()

// 货运单号条码
@property (weak, nonatomic) IBOutlet UIImageView *topBarCodeImageView;

// 货运单号 条形码文字
@property (weak, nonatomic) IBOutlet UILabel *aviationMasterNo_label;

// 小联 二维码
@property (weak, nonatomic) IBOutlet UIImageView *QRCodeImageView_2;

// 订单号条码
@property (weak, nonatomic) IBOutlet UIImageView *bottomBarCodeImageView;

// 货运单号
@property (weak, nonatomic) IBOutlet UILabel *aviationMasterNo;

// 件数
@property (weak, nonatomic) IBOutlet UILabel *bsOrderQty;

// 重量
@property (weak, nonatomic) IBOutlet UILabel *bsOrderWt;

// 始发站 至 到达站
@property (weak, nonatomic) IBOutlet UILabel *startEndCity;

// 航空公司 航班号
@property (weak, nonatomic) IBOutlet UILabel *airlineCompany_and_airlineNumber;


/********* 寄方 *********/
// 发货联系人
@property (weak, nonatomic) IBOutlet UILabel *issuePartyContact_2;
// 发货人电话(有值则显示没有则取固话)
@property (weak, nonatomic) IBOutlet UILabel *issuePartyTel_or_issuePartyGuHua_2;
// 发货城市
@property (weak, nonatomic) IBOutlet UILabel *issuePartyCity_2;
// 发货区县 + 发货详细地址
@property (weak, nonatomic) IBOutlet UILabel *issuePartyDistricict_and_issuePartyAddr_2;

/********* 收方 *********/
// 收货联系人
@property (weak, nonatomic) IBOutlet UILabel *receivePartyContactName_2;
// 收货人电话(有值则显示没有则取固话)
@property (weak, nonatomic) IBOutlet UILabel *receivePartyPhone_or_receivePartyGuHua_2;
// 收货城市
@property (weak, nonatomic) IBOutlet UILabel *receivePartyCity_2;
// 收货区县 + 收货地址
@property (weak, nonatomic) IBOutlet UILabel *receicePartyDistricict_and_receivePartyAddr1_2;
// 订单号
@property (weak, nonatomic) IBOutlet UILabel *omsNo;
// 备注
//@property (weak, nonatomic) IBOutlet UILabel *remark_2;
// 件数
@property (weak, nonatomic) IBOutlet UILabel *bsOrderQty_2;
// 重量
@property (weak, nonatomic) IBOutlet UILabel *bsOrderWt_2;
// 标签号
@property (weak, nonatomic) IBOutlet UILabel *productNo_s_label_2;

/********* tsuh号 *********/
@end

@implementation PrintimageTwoInOneController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    _aviationMasterNo.text = _dic[@"aviationMasterNo"];
    _bsOrderQty.text = [NSString stringWithFormat:@"%@", _dic[@"bsOrderQty"]];
    _bsOrderWt.text = [NSString stringWithFormat:@"%@", _dic[@"bsOrderWt"]];
    _startEndCity.text = _dic[@"startEndCity"];
    _airlineCompany_and_airlineNumber.text =
     [NSString stringWithFormat:@"%@  %@", _dic[@"airlineCompany"], _dic[@"airlineNumber"]];
    
    
    /********* 客户联 *********/
    
    _QRCodeImageView_2.image = [Tools createQRWithString:_dic[@"QRCode"] QRSize:_QRCodeImageView_2.frame.size];//小联二维码
    
    _bottomBarCodeImageView.image = [Tools resizeCodeWithString:_productNo_s BCSize:_bottomBarCodeImageView.frame.size];//标签号条形码
    
    _topBarCodeImageView.image = [Tools resizeCodeWithString:_dic[@"aviationMasterNo"] BCSize:_topBarCodeImageView.frame.size];//货运单号条形码
    
    _aviationMasterNo_label.text = _dic[@"aviationMasterNo"];//货运单号 条形码文字
    
    // 寄方
    _issuePartyContact_2.text = _dic[@"issuePartyContact"];
    _issuePartyTel_or_issuePartyGuHua_2.text = [[NSString stringWithFormat:@"%@", _dic[@"issuePartyTel"]] isEqualToString:@""] ? _dic[@"issuePartyGuHua"] : _dic[@"issuePartyTel"];
    _issuePartyCity_2.text = _dic[@"issuePartyCity"];
    _issuePartyDistricict_and_issuePartyAddr_2.text = [NSString stringWithFormat:@"%@  %@", _dic[@"issuePartyDistricict"], _dic[@"issuePartyAddr"]];
    
    // 收方
    _receivePartyContactName_2.text = _dic[@"receivePartyContactName"];
    _receivePartyPhone_or_receivePartyGuHua_2.text = [[NSString stringWithFormat:@"%@", _dic[@"receivePartyPhone"]] isEqualToString:@""] ? _dic[@"receivePartyGuHua"] : _dic[@"receivePartyPhone"];
    _receivePartyCity_2.text = _dic[@"receivePartyCity"];
    _receicePartyDistricict_and_receivePartyAddr1_2.text = [NSString stringWithFormat:@"%@  %@", _dic[@"receicePartyDistricict"], _dic[@"receivePartyAddr1"]];
    _omsNo.text = [NSString stringWithFormat:@"%@", _dic[@"omsNo"]];
//    _remark_2.text = _dic[@"remark"];
        _bsOrderQty_2.text = [NSString stringWithFormat:@"%@", _dic[@"bsOrderQty"]];
        _bsOrderWt_2.text = [NSString stringWithFormat:@"%@", _dic[@"bsOrderWt"]];
    _productNo_s_label_2.text = _productNo_s;
}

@end
