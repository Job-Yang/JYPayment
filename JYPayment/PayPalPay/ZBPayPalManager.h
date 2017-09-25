//
//  ZBPayPalManager.h
//  360zebra
//
//  Created by 杨权 on 2016/11/16.
//  Copyright © 2016年 360zebra. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ZBPayPalManagerDelegate <NSObject>
/**
 payPal完成支付（记得在该方法中校验有效性）
 */
- (void)payPalDidCompletePayment;
/**
 payPal取消支付
 */
- (void)payPalDidCancelPayment;

@end

/**
 * PayPal支付流程
 http://ios.pianshen.com/article/85043058929/;jsessionid=83F95D71503FCF8DA9BDDE0250B209FC
 */
@interface ZBPayPalManager : NSObject

/**
 代理
 */
@property (weak, nonatomic) id<ZBPayPalManagerDelegate> delegate;

/**
 PayPal 预连接
 在支付的VC中的viewWillAppear方法中调用该方法
 */
- (void)payPalPreconnectWithEnvironment;

/**
 使用PayPal支付
 
 @param rechargeAmount 支付的金额
 @param shortDescription 显示在PayPal中的支付标题
 */
- (void)paymentForPayPalWithRechargeAmount:(NSNumber *)rechargeAmount
                          shortDescription:(NSString *)shortDescription;
@end
