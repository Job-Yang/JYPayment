//
//  ZBPaymentHelper.h
//  360zebra
//
//  Created by 杨权 on 2016/11/18.
//  Copyright © 2016年 360zebra. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZBAlipayManager.h"
#import "ZBCreditCardPayManager.h"
#import "ZBWeChatPayManager.h"
#import "ZBPayPalManager.h"
#import "ZBApplePayManager.h"
#import "ZBBraintreeManager.h"

typedef NS_ENUM(NSInteger, ZBPaymentType) {
    //支付宝支付
    ZBPaymentTypeAlipay    = 0,
    //银行卡支付
    ZBPaymentTypeCreditPay = 1,
    //微信支付
    ZBPaymentTypeWeChatPay = 2,
    //PayPal支付
    ZBPaymentTypePayPalPay = 3,
    //ApplePa支付
    ZBPaymentTypeApplePay  = 4,
};

FOUNDATION_EXPORT NSString *const kNotifyPaymentSuccess;
FOUNDATION_EXPORT NSString *const kNotifyPaymentFailure;

@interface ZBPaymentHelper : NSObject
/**
 单例

 @return 单例对象
 */
+ (instancetype)helper;

/**
 设置微信和支付回调（交给本支付类来处理）

 @param url url
 @return 处理结果
 */
+ (BOOL)handleOpenURL:(NSURL *)url;

/**
 拉起支付
 
 @param type   支付方式
 @param amount 充值金额
 */
- (void)paymentWithPaymentType:(ZBPaymentType)type
                        amount:(CGFloat)amount;

/**
 拉起支付
 
 @param type        支付方式
 @param amount      充值金额
 @param otherParams 其他参数

 */
- (void)paymentWithPaymentType:(ZBPaymentType)type
                        amount:(CGFloat)amount
                   otherParams:(NSDictionary *)otherParams;

/**
 拉起支付
 
 @param type           支付方式
 @param amount         充值金额
 @param attachedAmount 附加金额（活动赠送或其他）
 @param otherParams    其他参数
 */
- (void)paymentWithPaymentType:(ZBPaymentType)type
                        amount:(CGFloat)amount
                attachedAmount:(CGFloat)attachedAmount
                   otherParams:(NSDictionary *)otherParams;

/**
 PayPal建立预支付
 */
- (void)payPalPreconnectWithEnvironment;


@end
