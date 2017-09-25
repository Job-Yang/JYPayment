//
//  JYApplePayManager.m
//  360zebra
//
//  Created by 杨权 on 2016/11/16.
//  Copyright © 2016年 360zebra. All rights reserved.
//

#import "JYApplePayManager.h"
#import <PassKit/PassKit.h>

//金额限制100万
#define MAXIMUM_AMOUNT_THRESHOLD 1000000

@interface JYApplePayManager()<PKPaymentAuthorizationViewControllerDelegate>

@property (assign, nonatomic) CGFloat rechargeAmount;
@property (strong, nonatomic) NSDictionary *otherParams;
@property (strong, nonatomic) PKPaymentRequest *request;
@end

@implementation JYApplePayManager

#pragma mark - setup methods
- (void)paymentForApplePayWithRechargeAmount:(CGFloat)rechargeAmount
                                 otherParams:(NSDictionary *)otherParams {

    self.rechargeAmount = rechargeAmount;
    self.otherParams = otherParams;
    
    if (![self isAvailable]) {
        [[JYRoutable currentVC] showHint:JYLocalizedString(@"金额不正确", nil)];
        return;
    }
    
    [self pay];
}

- (void)pay {
    
    if(![PKPaymentAuthorizationViewController canMakePayments]) {
        [[JYRoutable currentVC] showHint:JYLocalizedString(@"该设备暂不支持Apple Pay", nil)];
        return;
    }
    
    NSDecimalNumber *subtotalAmount = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%f",self.rechargeAmount]];
    PKPaymentSummaryItem *total = [PKPaymentSummaryItem summaryItemWithLabel:JYLocalizedString(@"ZEB充值", nil) amount:subtotalAmount];
    self.request.paymentSummaryItems = @[total];

    PKPaymentAuthorizationViewController *vc = [[PKPaymentAuthorizationViewController alloc] initWithPaymentRequest:self.request];
    vc.delegate = self;
    
    [[JYRoutable currentVC] presentViewController:vc animated:YES completion:nil];
    
}

#pragma mark - requests
- (NSMutableDictionary *)resetParameters {
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    //参数列表
    NSString *amount = [NSString stringWithFormat:@"%.2f", self.rechargeAmount];
    [dic setValue:@([amount floatValue]) forKey:@"amount"];
    [dic setValue:@"USD" forKey:@"currency"];
    [dic addEntriesFromDictionary:self.otherParams];
    return dic;
}

- (void *)rechargeSuccess:(void (^)(JYResponseModel *responseModel))success
                  failure:(void (^)(NSError *error))failure {
    @weakify(self);
    [[[JYHTTPSessionManager manager] POST:@""
                               parameters:@{
                                            @"sign" : [JYUtils signatureWithParameters:[self resetParameters]] ?: @"",
                                            @"code" : [[self resetParameters] jsonStringEncoded] ?: @"",
                                            }
                                  success:^(NSURLSessionDataTask *task, JYResponseModel *responseModel) {
                                      if (responseModel.resultCode == RESULT_CODE_SUCCESS) {
                                          success(responseModel);
                                      }
                                      else {
                                          failure(nil);
                                      }
                                  }
                                  failure:^(NSURLSessionDataTask *task, NSError *error) {
                                      failure(error);
                                      
                                  }] setOwner:weak_self];
}


#pragma mark - PKPaymentAuthorizationViewControllerDelegate
- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                    didSelectPaymentMethod:(PKPaymentMethod *)paymentMethod
                                completion:(void (^)(NSArray<PKPaymentSummaryItem *> * _Nonnull))completion {
    
    NSLog(@"didSelectPaymentMethod");
    completion(self.request.paymentSummaryItems);
}

- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                  didSelectShippingContact:(PKContact *)contact
                                completion:(void (^)(PKPaymentAuthorizationStatus, NSArray<PKShippingMethod *> * _Nonnull, NSArray<PKPaymentSummaryItem *> * _Nonnull))completion {
    
    NSLog(@"didSelectShippingContact");
}

- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                   didSelectShippingMethod:(PKShippingMethod *)shippingMethod
                                completion:(void (^)(PKPaymentAuthorizationStatus, NSArray<PKPaymentSummaryItem *> * _Nonnull))completion {
    NSLog(@"didSelectShippingMethod");
}

- (void)paymentAuthorizationViewControllerWillAuthorizePayment:(PKPaymentAuthorizationViewController *)controller {
    NSLog(@"paymentAuthorizationViewControllerWillAuthorizePayment");
}

- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                       didAuthorizePayment:(PKPayment *)payment
                                completion:(void (^)(PKPaymentAuthorizationStatus))completion {
    
//    [self rechargeSuccess:^(JYResponseModel *responseModel) {
//        completion(PKPaymentAuthorizationStatusSuccess);
//    } failure:^(NSError *error) {
//        completion(PKPaymentAuthorizationStatusFailure);
//    }];
    id paymentData = [NSJSONSerialization JSONObjectWithData:payment.token.paymentData options:NSJSONReadingAllowFragments error:nil];
    NSLog(@"paymentData = %@",paymentData);
    completion(PKPaymentAuthorizationStatusFailure);

}

- (void)paymentAuthorizationViewControllerDidFinish:(PKPaymentAuthorizationViewController *)controller {
    NSLog(@"finish");
    
    [controller dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - private methods
- (BOOL)isAvailable {
    return !(self.rechargeAmount < 0.01f || self.rechargeAmount > MAXIMUM_AMOUNT_THRESHOLD);
}

#pragma mark - getter & setter
- (PKPaymentRequest *)request {
    if (!_request) {
        PKPaymentRequest *request = [[PKPaymentRequest alloc] init];
        request.currencyCode = @"USD";
        request.countryCode = @"US";
        request.merchantIdentifier = @"merchant.com.360zebra.zeb";
        request.merchantCapabilities = PKMerchantCapability3DS | PKMerchantCapabilityEMV | PKMerchantCapabilityCredit | PKMerchantCapabilityDebit;
        request.supportedNetworks = @[PKPaymentNetworkAmex, PKPaymentNetworkChinaUnionPay, PKPaymentNetworkCarteBancaire];
        _request = request;
    }
    return _request;
}

@end
