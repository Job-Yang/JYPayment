//
//  JYOrder.h
//  JYPaymentDemo
//
//  Created by 杨权 on 2017/9/25.
//  Copyright © 2017年 Job-Yang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JYOrder : NSObject

@property (strong, nonatomic) NSDecimalNumber *rechargeAmount;
@property (copy  , nonatomic) NSString *shortDescription;
@property (strong, nonatomic) NSDictionary *otherParams;

@end
