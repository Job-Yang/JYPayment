//
//  JYPayment.h
//  JYPaymentDemo
//
//  Created by 杨权 on 2017/9/25.
//  Copyright © 2017年 Job-Yang. All rights reserved.
//

#import "JYPaymentManager.h"

FOUNDATION_EXPORT NSString *const kJYPaymentAlipay;
FOUNDATION_EXPORT NSString *const kJYPaymentTypeWeChatPay;
FOUNDATION_EXPORT NSString *const kJYPaymentTypePayPal;
FOUNDATION_EXPORT NSString *const kJYPaymentTypeApplePay;

@interface JYPayment : JYPaymentManager

+ (void)alipay:(JYOrder *)order
       success:(JYPaymentSuccessBlock)success
       failure:(JYPaymentFailureBlock)failure;

@end
