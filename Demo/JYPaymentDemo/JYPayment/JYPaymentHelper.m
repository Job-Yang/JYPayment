//
//  JYPaymentHelper.m
//  360zebra
//
//  Created by 杨权 on 2016/11/18.
//  Copyright © 2016年 360zebra. All rights reserved.
//

#import "JYPaymentHelper.h"

//金额限制100万
#define MAXIMUM_AMOUNT_THRESHOLD 1000000

NSString *const kNotifyPaymentSuccess = @"NotifyPaymentSuccess";
NSString *const kNotifyPaymentFailure = @"NotifyPaymentFailure";

@interface JYPaymentHelper()<WXApiDelegate, JYAlipayManagerDelegate, JYWeChatPayManagerDelegate, JYPayPalManagerDelegate, JYApplePayManagerDelegate>

@property (strong, nonatomic) JYAlipayManager *alipayManager;
@property (strong, nonatomic) JYWeChatPayManager *wechatPayManager;
@property (strong, nonatomic) JYPayPalManager *payPalManager;
@property (strong, nonatomic) JYApplePayManager *applePayManager;

@end

@implementation JYPaymentHelper

#pragma mark - public methods
+ (instancetype)helper {
    static dispatch_once_t onceToken;
    static JYPaymentHelper *instance;
    dispatch_once(&onceToken, ^{
        instance = [[JYPaymentHelper alloc] init];
    });
    return instance;
}

+ (BOOL)handleOpenURL:(NSURL *)url {
    if ([url.host isEqualToString:@"safepay"]) {
        [[JYPaymentHelper helper] alipayPaymentResult:url];
    }
    [WXApi handleOpenURL:url delegate:[JYPaymentHelper helper]];
    return YES;
}

- (void)paymentWithPaymentType:(JYPaymentType)type
                        amount:(CGFloat)amount {
    
    [self paymentWithPaymentType:type
                          amount:amount
                     otherParams:@{}];
}

- (void)paymentWithPaymentType:(JYPaymentType)type
                        amount:(CGFloat)amount
                   otherParams:(NSDictionary *)otherParams {
    
    [self paymentWithPaymentType:type
                          amount:amount
                  attachedAmount:0.f
                     otherParams:otherParams];
}

- (void)paymentWithPaymentType:(JYPaymentType)type
                        amount:(CGFloat)amount
                attachedAmount:(CGFloat)attachedAmount
                   otherParams:(NSDictionary *)otherParams {
    
    if (![self isAvailableWithAmount:amount attachedAmount:attachedAmount]) {
        [[JYRoutable currentVC] showHint:JYLocalizedString(@"金额不正确", nil)];
        return;
    }
    
    switch (type) {
        case JYPaymentTypeAlipay: {
            [self.alipayManager paymentForAlipayWithRechargeAmount:amount
                                                       otherParams:otherParams];
            break;
        }
        case JYPaymentTypeWeChatPay: {
            [self.wechatPayManager paymentForAlipayWithRechargeAmount:amount
                                                          otherParams:otherParams];
            break;
        }
        case JYPaymentTypePayPalPay: {
            NSString *shortDescription = otherParams[@"shortDescription"];
            [self.payPalManager paymentForPayPalWithRechargeAmount:@(amount)
                                                  shortDescription:shortDescription];
            break;
        }
        case JYPaymentTypeApplePay: {
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
                                                      [self postNotificationWithPaymentType:JYPaymentTypeAlipay isSuccess:YES];
                                                  }
                                                  else {
                                                      // 支付不成功（正在处理中，订单支付失败，用户中途取消，网络连接出错）
                                                      [self postNotificationWithPaymentType:JYPaymentTypeAlipay isSuccess:NO];
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

#pragma mark - JYAlipayManagerDelegate
- (void)alipaySuccess {
    [self postNotificationWithPaymentType:JYPaymentTypeAlipay isSuccess:YES];
}

- (void)alipayFailure {
    [self postNotificationWithPaymentType:JYPaymentTypeAlipay isSuccess:NO];
}

#pragma mark - JYWeChatPayManagerDelegate
- (void)weChatPaySuccess {
    [self postNotificationWithPaymentType:JYPaymentTypeWeChatPay isSuccess:YES];
}

- (void)weChatPayFailure {
    [self postNotificationWithPaymentType:JYPaymentTypeWeChatPay isSuccess:NO];
}

#pragma mark - JYPayPalManagerDelegate
- (void)payPalDidCompletePayment {
    [self postNotificationWithPaymentType:JYPaymentTypePayPalPay isSuccess:YES];
}

- (void)payPalDidCancelPayment {
    [self postNotificationWithPaymentType:JYPaymentTypePayPalPay isSuccess:NO];
}

#pragma mark - private methods
- (BOOL)isAvailableWithAmount:(CGFloat)amount
               attachedAmount:(CGFloat)attachedAmount {
    
    if (amount < 0.01f || attachedAmount < 0.f || amount > MAXIMUM_AMOUNT_THRESHOLD) {
        return NO;
    }
    return YES;
}

- (void)postNotificationWithPaymentType:(JYPaymentType)type
                              isSuccess:(BOOL)isSuccess {
    NSDictionary *dic = @{
                          @"type": @(type)
                          };
    [[NSNotificationCenter defaultCenter] postNotificationName:isSuccess ? kNotifyPaymentSuccess : kNotifyPaymentFailure
                                                        object:nil
                                                      userInfo:dic];
}

#pragma mark - getter & setter
- (JYAlipayManager *)alipayManager {
    if (!_alipayManager) {
        _alipayManager = [[JYAlipayManager alloc] init];
        _alipayManager.delegate = self;
    }
    return _alipayManager;
}

- (JYWeChatPayManager *)wechatPayManager {
    if (!_wechatPayManager) {
        _wechatPayManager = [[JYWeChatPayManager alloc] init];
        _wechatPayManager.delegate = self;
    }
    return _wechatPayManager;
}

- (JYPayPalManager *)payPalManager {
    if (!_payPalManager) {
        _payPalManager = [[JYPayPalManager alloc] init];
        _payPalManager.delegate = self;
    }
    return _payPalManager;
}


- (JYApplePayManager *)applePayManager {
    if (!_applePayManager) {
        _applePayManager = [[JYApplePayManager alloc] init];
        _applePayManager.delegate = self;
    }
    return _applePayManager;
}

@end
