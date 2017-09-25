//
//  JYWeChatPayManager.h
//  360zebra
//
//  Created by 杨权 on 2016/11/18.
//  Copyright © 2016年 360zebra. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WXApi.h"

@protocol JYWeChatPayManagerDelegate <NSObject>
/**
 微信支付成功
 */
- (void)weChatPaySuccess;
/**
 微信支付失败
 */
- (void)weChatPayFailure;

@end

NSString *const kWechatAppID = @"wxb42951ac9c83badd";

/**
 * 微信支付流程
  https://pay.weixin.qq.com/wiki/doc/api/app/app.php?chapter=8_3
 */
@interface JYWeChatPayManager : NSObject
/**
 代理
 */
@property (weak, nonatomic) id<JYWeChatPayManagerDelegate> delegate;

/**
 支付宝支付
 
 @param rechargeAmount 充值金额
 @param otherParams 其他参数
 */
- (void)paymentForAlipayWithRechargeAmount:(CGFloat)rechargeAmount
                               otherParams:(NSDictionary *)otherParams;

@end
