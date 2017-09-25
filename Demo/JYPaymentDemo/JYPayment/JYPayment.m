//
//  JYPayment.m
//  JYPaymentDemo
//
//  Created by 杨权 on 2017/9/25.
//  Copyright © 2017年 Job-Yang. All rights reserved.
//

#import "JYPayment.h"

NSString *const kJYPaymentAlipay        = @"JYAlipay";
NSString *const kJYPaymentTypeWeChatPay = @"JYWeChatPay";
NSString *const kJYPaymentTypePayPal    = @"JYPayPal";
NSString *const kJYPaymentTypeApplePay  = @"JYApplePay";

//金额限制100万
#define MAXIMUM_AMOUNT_THRESHOLD 1000000

@implementation JYPayment

+ (void)alipay:(JYOrder *)order
       success:(JYPaymentSuccessBlock)success
       failure:(JYPaymentFailureBlock)failure {
    
    [[self alloc] paymentOrder:order
                        method:kJYPaymentAlipay
                       success:success
                       failure:failure];
}


@end
