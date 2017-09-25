//
//  JYAlipayManager.h
//  360zebra
//
//  Created by 杨权 on 2016/12/7.
//  Copyright © 2016年 360zebra. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AlipaySDK/AlipaySDK.h>

@protocol JYAlipayManagerDelegate <NSObject>
/**
 支付宝支付成功
 */
- (void)alipaySuccess;
/**
  支付宝支付失败（即不是成功的剩余状态）
 */
- (void)alipayFailure;

@end

/**
 支付宝支付流程
 https://doc.open.alipay.com/docs/doc.htm?spm=a219a.7629140.0.0.NrfIdA&treeId=59&articleId=103658&docType=1
 */
@interface JYAlipayManager : NSObject

/**
 代理
 */
@property (weak, nonatomic) id<JYAlipayManagerDelegate> delegate;

/**
 支付宝支付
 
 @param rechargeAmount 充值金额
 @param otherParams 其他参数
 */
- (void)paymentForAlipayWithRechargeAmount:(CGFloat)rechargeAmount
                               otherParams:(NSDictionary *)otherParams;

@end
