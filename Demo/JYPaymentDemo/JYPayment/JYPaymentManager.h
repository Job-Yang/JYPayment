//
//  JYPaymentManager.h
//  JYPaymentDemo
//
//  Created by 杨权 on 2017/9/25.
//  Copyright © 2017年 Job-Yang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JYOrder.h"

typedef void (^JYPaymentSuccessBlock)(NSURLSessionDataTask *task, id responseModel);
typedef void (^JYPaymentFailureBlock)(NSURLSessionDataTask *task, NSError *error);

@protocol JYPaymentProtocol <NSObject>

@required
- (void)paymentOrder:(JYOrder *)order
             success:(JYPaymentSuccessBlock)success
             failure:(JYPaymentFailureBlock)failure;

@optional
- (NSDictionary *)orderAdapter:(JYOrder *)order;
+ (BOOL)handleOpenURL:(NSURL *)url;

@end



@interface JYPaymentManager : NSObject

+ (instancetype)manager;

- (void)paymentOrder:(JYOrder *)order
              method:(NSString *)method
             success:(JYPaymentSuccessBlock)success
             failure:(JYPaymentFailureBlock)failure;

@end
