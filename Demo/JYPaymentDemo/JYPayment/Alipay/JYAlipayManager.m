//
//  JYAlipayManager.m
//  360zebra
//
//  Created by 杨权 on 2016/12/7.
//  Copyright © 2016年 360zebra. All rights reserved.
//

#import "JYAlipayManager.h"

NSString *const kAlipayAppScheme = @"ZEBClient";
//金额限制100万
#define MAXIMUM_AMOUNT_THRESHOLD 1000000

@interface JYAlipayManager()

@property (assign, nonatomic) CGFloat rechargeAmount;
@property (strong, nonatomic) NSDictionary *otherParams;

@end

@implementation JYAlipayManager



- (void)paymentForAlipayWithRechargeAmount:(CGFloat)rechargeAmount
                               otherParams:(NSDictionary *)otherParams {
    
    self.rechargeAmount = rechargeAmount;
    self.otherParams = otherParams;
    
    if (![self isAvailable]) {
        [[JYRoutable currentVC] showHint:JYLocalizedString(@"金额不正确", nil)];
        return;
    }
    //获取支付宝订单签名信息
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
    [[JYRoutable currentVC] showHUDInSelfViewWithHint:JYLocalizedString(@"加载中...", nil)];
    [[[JYHTTPSessionManager manager] POST:kAPIPaymentAlipay
                              parameters:@{
                                           @"sign" : [JYUtils signatureWithParameters:[self resetParameters]] ?: @"",
                                           @"code" : [[self resetParameters] jsonStringEncoded] ?: @"",
                                           }
                                 success:^(NSURLSessionDataTask *task, JYResponseModel *responseModel) {
                                     @strongify(self);
                                     [[JYRoutable currentVC] hideHUD];
                                     if (responseModel.resultCode == RESULT_CODE_SUCCESS) {
                                         NSString *signedString = responseModel.data[@"response"];
                                         if (signedString.length > 0) {
                                             [self payWithSignedString:signedString];
                                         }
                                     }
                                 }
                                 failure:^(NSURLSessionDataTask *task, NSError *error) {
                                     [[JYRoutable currentVC] hideHUD];
                                 }] setOwner:weak_self];
}

- (BOOL)isAvailable {
    if (self.rechargeAmount < 0.01f || self.rechargeAmount > MAXIMUM_AMOUNT_THRESHOLD) {
        return NO;
    }
    return YES;
}

// 拉起支付宝支付
- (void)payWithSignedString:(NSString *)signedString {
    //回调用于H5接收页面的反馈信息
    [[AlipaySDK defaultService] payOrder:signedString
                              fromScheme:kAlipayAppScheme
                                callback:^(NSDictionary *resultDic) {
                                    NSLog(@"reslut = %@",resultDic);
                                    NSString *str = [resultDic objectForKey:@"resultStatus"];
                                    if (str.intValue == 9000) {
                                        // 支付成功（订单支付成功）
                                        if ([self.delegate respondsToSelector:@selector(alipaySuccess)]) {
                                            [self.delegate alipaySuccess];
                                        }
                                    }
                                    else {
                                        // 支付不成功（正在处理中，订单支付失败，用户中途取消，网络连接出错）
                                        if ([self.delegate respondsToSelector:@selector(alipayFailure)]) {
                                            [self.delegate alipayFailure];
                                        }
                                    }
                                }];
}

@end

