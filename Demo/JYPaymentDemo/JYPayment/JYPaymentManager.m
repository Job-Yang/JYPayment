//
//  JYPaymentManager.m
//  JYPaymentDemo
//
//  Created by 杨权 on 2017/9/25.
//  Copyright © 2017年 Job-Yang. All rights reserved.
//

#import "JYPaymentManager.h"

@implementation JYPaymentManager

+ (instancetype)manager {
    static dispatch_once_t onceToken;
    static JYPaymentManager *_instance;
    dispatch_once(&onceToken, ^{
        _instance = [[JYPaymentManager alloc] init];
    });
    return _instance;
}

+ (BOOL)handleOpenURL:(NSURL *)url {
    return YES;
}

- (void)paymentOrder:(JYOrder *)order
              method:(NSString *)method
             success:(JYPaymentSuccessBlock)success
             failure:(JYPaymentFailureBlock)failure {
    
    NSParameterAssert(order);
    NSParameterAssert(method);
    
    Class paymentClass = NSClassFromString(method);

    if ([paymentClass conformsToProtocol:@protocol(JYPaymentProtocol)] &&
        [paymentClass respondsToSelector:@selector(paymentOrder:success:failure:)]) {
        [[paymentClass alloc] paymentOrder:order success:success failure:failure];
    }
}

@end
