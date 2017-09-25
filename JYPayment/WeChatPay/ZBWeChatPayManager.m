//
//  ZBWeChatPayManager.m
//  360zebra
//
//  Created by 杨权 on 2016/11/18.
//  Copyright © 2016年 360zebra. All rights reserved.
//

#import "ZBWeChatPayManager.h"

NSString *const kWechatPartnerID = @"2088301345047652";

//金额限制100万
#define MAXIMUM_AMOUNT_THRESHOLD 1000000

@interface ZBWeChatPayManager()

@property (assign, nonatomic) CGFloat rechargeAmount;
@property (strong, nonatomic) NSDictionary *otherParams;

@end

@implementation ZBWeChatPayManager

- (void)paymentForAlipayWithRechargeAmount:(CGFloat)rechargeAmount
                               otherParams:(NSDictionary *)otherParams{
    
    self.rechargeAmount = rechargeAmount;
    self.otherParams = otherParams;
    
    if (![self isAvailable]) {
        [[ZBRoutable currentVC] showHint:ZBLocalizedString(@"金额不正确", nil)];
        return;
    }
    //获取微信订单签名信息
    [self recharge];
}


#pragma mark - requests
- (NSMutableDictionary *)resetParameters {
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    //参数列表
    NSString *amount = [NSString stringWithFormat:@"%.2f", self.rechargeAmount];
    [dic setValue:@([amount floatValue]) forKey:@"amount"];
    [dic setValue:@"USD" forKey:@"currency"];
    [dic addEntriesFromDictionary:self.otherParams];
    return dic;
}


- (void)recharge {
    @weakify(self);
    [[ZBRoutable currentVC] showHUDInSelfViewWithHint:ZBLocalizedString(@"加载中...", nil)];
    [[[ZBHTTPSessionManager manager] POST:kAPIPaymentAlipay
                               parameters:@{
                                            @"sign" : [ZBUtils signatureWithParameters:[self resetParameters]] ?: @"",
                                            @"code" : [[self resetParameters] jsonStringEncoded] ?: @"",
                                            }
                                  success:^(NSURLSessionDataTask *task, ZBResponseModel *responseModel) {
                                      @strongify(self);
                                      [[ZBRoutable currentVC] hideHUD];
                                      if (responseModel.resultCode == RESULT_CODE_SUCCESS) {
                                          NSString *signedString = responseModel.data[@"response"];
                                          if (signedString.length > 0) {
                                              [self payWithSignedString:signedString];
                                          }
                                      }
                                  }
                                  failure:^(NSURLSessionDataTask *task, NSError *error) {
                                      [[ZBRoutable currentVC] hideHUD];
                                  }] setOwner:weak_self];
}

- (BOOL)isAvailable {
    if (self.rechargeAmount < 0.01f || self.rechargeAmount > MAXIMUM_AMOUNT_THRESHOLD) {
        return NO;
    }
    return YES;
}

- (void)payWithSignedString:(NSString *)signedString {
    PayReq *request = [[PayReq alloc] init];
    /** 商家向财付通申请的商家id */
    request.partnerId = kWechatPartnerID;
    /** 预支付订单 */
    request.prepayId= @"82010380001603250865be9c4c063c30";
    /** 商家根据财付通文档填写的数据和签名 */
    request.package = @"Sign=WXPay";
    /** 随机串，防重发 */
    request.nonceStr= @"lUu5qloVJV7rrJlr";
    /** 时间戳，防重发 */
    request.timeStamp = [[NSDate date] timeIntervalSince1970];
    /** 商家根据微信开放平台文档对数据做的签名 */
    request.sign = @"b640c1a4565b476db096f4d34b8a9e71960b0123";
    /*! @brief 发送请求到微信，等待微信返回onResp
     *
     * 函数调用后，会切换到微信的界面。第三方应用程序等待微信返回onResp。微信在异步处理完成后一定会调用onResp。支持以下类型
     * SendAuthReq、SendMessageToWXReq、PayReq等。
     * @param req 具体的发送请求，在调用函数后，请自己释放。
     * @return 成功返回YES，失败返回NO。
     */
    [WXApi sendReq: request];
}

@end
