//
//  ZBPaymentHelper.m
//  360zebra
//
//  Created by 杨权 on 2016/11/18.
//  Copyright © 2016年 360zebra. All rights reserved.
//

#import "ZBPaymentHelper.h"

//金额限制100万
#define MAXIMUM_AMOUNT_THRESHOLD 1000000

NSString *const kNotifyPaymentSuccess = @"NotifyPaymentSuccess";
NSString *const kNotifyPaymentFailure = @"NotifyPaymentFailure";

@interface ZBPaymentHelper()<WXApiDelegate, ZBAlipayManagerDelegate, ZBCreditCardPayManagerDelegate, ZBWeChatPayManagerDelegate,  ZBPayPalManagerDelegate, ZBApplePayManagerDelegate>

@property (strong, nonatomic) ZBAlipayManager *alipayManager;
@property (strong, nonatomic) ZBCreditCardPayManager *creditCardPayManager;
@property (strong, nonatomic) ZBWeChatPayManager *wechatPayManager;
@property (strong, nonatomic) ZBPayPalManager *payPalManager;
@property (strong, nonatomic) ZBApplePayManager *applePayManager;

@end

@implementation ZBPaymentHelper

#pragma mark - public methods
+ (instancetype)helper {
    static dispatch_once_t onceToken;
    static ZBPaymentHelper *instance;
    dispatch_once(&onceToken, ^{
        instance = [[ZBPaymentHelper alloc] init];
    });
    return instance;
}

+ (BOOL)handleOpenURL:(NSURL *)url {
    if ([url.host isEqualToString:@"safepay"]) {
        [[ZBPaymentHelper helper] alipayPaymentResult:url];
    }
    [WXApi handleOpenURL:url delegate:[ZBPaymentHelper helper]];
    return YES;
}

- (void)paymentWithPaymentType:(ZBPaymentType)type
                        amount:(CGFloat)amount {
    
    [self paymentWithPaymentType:type
                          amount:amount
                     otherParams:@{}];
}

- (void)paymentWithPaymentType:(ZBPaymentType)type
                        amount:(CGFloat)amount
                   otherParams:(NSDictionary *)otherParams {
    
    [self paymentWithPaymentType:type
                          amount:amount
                  attachedAmount:0.f
                     otherParams:otherParams];
}

- (void)paymentWithPaymentType:(ZBPaymentType)type
                        amount:(CGFloat)amount
                attachedAmount:(CGFloat)attachedAmount
                   otherParams:(NSDictionary *)otherParams {
    
    if (![self isAvailableWithAmount:amount attachedAmount:attachedAmount]) {
        [[ZBRoutable currentVC] showHint:ZBLocalizedString(@"金额不正确", nil)];
        return;
    }
    
    switch (type) {
        case ZBPaymentTypeAlipay: {
            [self.alipayManager paymentForAlipayWithRechargeAmount:amount
                                                       otherParams:otherParams];
            break;
        }
        case ZBPaymentTypeCreditPay: {
            [self.creditCardPayManager paymentForCreditCardPayWithRechargeAmount:amount
                                                                  attachedAmount:attachedAmount
                                                                     otherParams:otherParams];
            break;
        }
        case ZBPaymentTypeWeChatPay: {
            [self.wechatPayManager paymentForAlipayWithRechargeAmount:amount
                                                          otherParams:otherParams];
            break;
        }
        case ZBPaymentTypePayPalPay: {
            NSString *shortDescription = otherParams[@"shortDescription"];
            [self.payPalManager paymentForPayPalWithRechargeAmount:@(amount)
                                                  shortDescription:shortDescription];
            break;
        }
        case ZBPaymentTypeApplePay: {
            [self.applePayManager paymentForApplePayWithRechargeAmount:amount
                                                           otherParams:otherParams];
            break;
        }
        default:
            break;
    }
}

- (void)payPalPreconnectWithEnvironment {
    [self.payPalManager payPalPreconnectWithEnvironment];
}

#pragma mark - alipay Callback
/**
 支付宝回调，此处回调用于从支付宝APP跳回时触发
 
 @param url url
 */
- (void)alipayPaymentResult:(NSURL *)url {
    //跳转支付宝钱包进行支付,此处回调用于从支付宝APP跳回时
    [[AlipaySDK defaultService] processOrderWithPaymentResult:url
                                              standbyCallback:^(NSDictionary *resultDic) {
                                                  NSLog(@"result = %@",resultDic);
                                                  NSString *str = [resultDic objectForKey:@"resultStatus"];
                                                  if (str.intValue == 9000) {
                                                      // 支付成功（订单支付成功）
                                                      [self postNotificationWithPaymentType:ZBPaymentTypeAlipay isSuccess:YES];
                                                  }
                                                  else {
                                                      // 支付不成功（正在处理中，订单支付失败，用户中途取消，网络连接出错）
                                                      [self postNotificationWithPaymentType:ZBPaymentTypeAlipay isSuccess:NO];
                                                  }
                                                  
                                              }];
}

#pragma mark - WXApiDelegate
- (void)onResp:(BaseResp *)resp{
    //如果第三方程序向微信发送了sendReq的请求，那么onResp会被回调。sendReq请求调用后，会切到微信终端程序界面
    NSString *strMsg = [NSString stringWithFormat:@"errcode:%d", resp.errCode];
    NSString *strTitle;
    if ([resp isKindOfClass:[PayResp class]]) {
        //支付返回结果，实际支付结果需要去微信服务器端查询
        strTitle = [NSString stringWithFormat:@"支付结果"];
        switch (resp.errCode) {
            case WXSuccess:
                strMsg = @"支付结果：成功！";
                break;
                
            default:
                strMsg = [NSString stringWithFormat:@"支付结果：失败！retcode = %d, retstr = %@", resp.errCode,resp.errStr];
                break;
        }
    }
    //支付成功后回调
    // http://210.22.129.138:8080/link/public/notifywechatcallback
    
    //下边先注释掉，以后会用得上
    //    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:strTitle message:strMsg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    //    [alert show];
}

- (void)onReq:(BaseReq *)req{
    //onReq是微信终端向第三方程序发起请求，要求第三方程序响应。第三方程序响应完后必须调用sendRsp返回。在调用sendRsp返回时，会切回到微信终端程序界面
}

#pragma mark - ZBAlipayManagerDelegate
- (void)alipaySuccess {
    [self postNotificationWithPaymentType:ZBPaymentTypeAlipay isSuccess:YES];
}

- (void)alipayFailure {
    [self postNotificationWithPaymentType:ZBPaymentTypeAlipay isSuccess:NO];
}

#pragma mark - ZBCreditCardPayManagerDelegate
- (void)creditCardPaySuccess {
    [self postNotificationWithPaymentType:ZBPaymentTypeCreditPay isSuccess:YES];
}

- (void)creditCardPayFailure {
    [self postNotificationWithPaymentType:ZBPaymentTypeCreditPay isSuccess:NO];
}

#pragma mark - ZBWeChatPayManagerDelegate
- (void)weChatPaySuccess {
    [self postNotificationWithPaymentType:ZBPaymentTypeWeChatPay isSuccess:YES];
}

- (void)weChatPayFailure {
    [self postNotificationWithPaymentType:ZBPaymentTypeWeChatPay isSuccess:NO];
}

#pragma mark - ZBPayPalManagerDelegate
- (void)payPalDidCompletePayment {
    [self postNotificationWithPaymentType:ZBPaymentTypePayPalPay isSuccess:YES];
}

- (void)payPalDidCancelPayment {
    [self postNotificationWithPaymentType:ZBPaymentTypePayPalPay isSuccess:NO];
}

#pragma mark - private methods
- (BOOL)isAvailableWithAmount:(CGFloat)amount
               attachedAmount:(CGFloat)attachedAmount {
    
    if (amount < 0.01f || attachedAmount < 0.f || amount > MAXIMUM_AMOUNT_THRESHOLD) {
        return NO;
    }
    return YES;
}

- (void)postNotificationWithPaymentType:(ZBPaymentType)type
                              isSuccess:(BOOL)isSuccess {
    NSDictionary *dic = @{
                          @"type": @(type)
                          };
    [[NSNotificationCenter defaultCenter] postNotificationName:isSuccess ? kNotifyPaymentSuccess : kNotifyPaymentFailure
                                                        object:nil
                                                      userInfo:dic];
}

#pragma mark - getter & setter
- (ZBAlipayManager *)alipayManager {
    if (!_alipayManager) {
        _alipayManager = [[ZBAlipayManager alloc] init];
        _alipayManager.delegate = self;
    }
    return _alipayManager;
}

- (ZBCreditCardPayManager *)creditCardPayManager {
    if (!_creditCardPayManager) {
        _creditCardPayManager = [[ZBCreditCardPayManager alloc] init];
        _creditCardPayManager.delegate = self;
    }
    return _creditCardPayManager;
}

- (ZBWeChatPayManager *)wechatPayManager {
    if (!_wechatPayManager) {
        _wechatPayManager = [[ZBWeChatPayManager alloc] init];
        _wechatPayManager.delegate = self;
    }
    return _wechatPayManager;
}

- (ZBPayPalManager *)payPalManager {
    if (!_payPalManager) {
        _payPalManager = [[ZBPayPalManager alloc] init];
        _payPalManager.delegate = self;
    }
    return _payPalManager;
}


- (ZBApplePayManager *)applePayManager {
    if (!_applePayManager) {
        _applePayManager = [[ZBApplePayManager alloc] init];
        _applePayManager.delegate = self;
    }
    return _applePayManager;
}

@end
