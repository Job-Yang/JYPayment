//
//  ZBApplePayManager.h
//  360zebra
//
//  Created by 杨权 on 2016/11/16.
//  Copyright © 2016年 360zebra. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ZBApplePayManagerDelegate <NSObject>
/**
 ApplePay完成支付（记得在该方法中校验有效性）
 */
- (void)applePalDidCompletePayment;
/**
 ApplePay取消支付
 */
- (void)applePalFailure;

@end

/**
 * ApplePay支付流程
 https://developer.apple.com/library/content/ApplePay_Guide/index.html#//apple_ref/doc/uid/TP40014764-CH1-SW1
 */
@interface ZBApplePayManager : NSObject

/**
 代理
 */
@property (weak, nonatomic) id<ZBApplePayManagerDelegate> delegate;


/**
 使用ApplePay支付
 
 @param rechargeAmount 充值金额
 @param attachedAmount 其他参数
 */
- (void)paymentForApplePayWithRechargeAmount:(CGFloat)rechargeAmount
                                 otherParams:(NSDictionary *)otherParams;
@end
