//
//  JYAlipay.m
//  JYPaymentDemo
//
//  Created by 杨权 on 2017/9/25.
//  Copyright © 2017年 Job-Yang. All rights reserved.
//

#import "JYAlipay.h"
#import "JYPaymentManager.h"
#import <AlipaySDK/AlipaySDK.h>

NSString *const kAlipayAppScheme = @"ZEBClient";

@interface JYAlipay()<JYPaymentProtocol>
@property (strong, nonatomic) JYOrder *order;
@end

@implementation JYAlipay

+ (BOOL)handleOpenURL:(NSURL *)url {
    if ([url.host isEqualToString:@"safepay"]) {
        [self alipayPaymentResult:url];
    }
    return YES;
}


- (void)paymentOrder:(JYOrder *)order
             success:(JYPaymentSuccessBlock)success
             failure:(JYPaymentFailureBlock)failure {
    self.order = order;
    //获取支付宝订单签名信息
    [self signature];
}

- (NSDictionary *)orderAdapter:(JYOrder *)order {
    
}

- (void)signature {
    [[AFHTTPSessionManager manager] POST:@""
                               parameters:@{
                                            @"sign" : [JYUtils signatureWithParameters:[self resetParameters]] ?: @"",
                                            @"code" : [[self resetParameters] jsonStringEncoded] ?: @"",
                                            }
                                  success:^(NSURLSessionDataTask *task, JYResponseModel *responseModel) {
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
                                  }];
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
                                    }
                                    else {
                                        // 支付不成功（正在处理中，订单支付失败，用户中途取消，网络连接出错）
                                    }
                                }];
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
                                                  }
                                                  else {
                                                      // 支付不成功（正在处理中，订单支付失败，用户中途取消，网络连接出错）
                                                  }
                                                  
                                              }];
}


@end
