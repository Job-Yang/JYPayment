//
//  ZBPayPalManager.m
//  360zebra
//
//  Created by 杨权 on 2016/11/16.
//  Copyright © 2016年 360zebra. All rights reserved.
//

#import "ZBPayPalManager.h"
#import "PayPalMobile.h"

@interface ZBPayPalManager()<PayPalPaymentDelegate>

@property (nonatomic, strong, readwrite) PayPalConfiguration *payPalConfiguration;
@property (weak, nonatomic) UIViewController *viewController;

@end

@implementation ZBPayPalManager

#pragma mark - setup methods
- (void)payPalPreconnectWithEnvironment {
    [PayPalMobile preconnectWithEnvironment:PayPalEnvironmentNoNetwork];
}

- (void)paymentForPayPalWithRechargeAmount:(NSNumber *)rechargeAmount
                          shortDescription:(NSString *)shortDescription {
    
    PayPalPayment *payment = [[PayPalPayment alloc] init];
    payment.amount = [[NSDecimalNumber alloc] initWithString:[rechargeAmount stringValue]];
    payment.currencyCode = @"USD";
    payment.shortDescription = shortDescription;
    payment.intent = PayPalPaymentIntentSale;
    //    payment.shippingAddress = address;
    //    payment.paymentDetails = ;
    
    // Check whether payment is processable.
    if (!payment.processable) {
        [self.viewController showHint:ZBLocalizedString(@"充值失败", nil)];
        return;
    }
    
    // Create a PayPalPaymentViewController.
    PayPalPaymentViewController *paymentViewController;
    paymentViewController = [[PayPalPaymentViewController alloc] initWithPayment:payment
                                                                   configuration:self.payPalConfiguration
                                                                        delegate:self];
    // Present the PayPalPaymentViewController.
    [self.viewController presentViewController:paymentViewController animated:YES completion:nil];
}

#pragma mark - requests
- (void *)rechargeWithConfirmation:(NSDictionary *)confirmation
                           success:(void (^)(ZBResponseModel *responseModel))success
                           failure:(void (^)(NSError *error))failure {
    @weakify(self);
    [[[ZBHTTPSessionManager manager] POST:@""
                               parameters:@{
                                            @"sign" : [ZBUtils signatureWithParameters:confirmation] ?: @"",
                                            @"code" : [confirmation jsonStringEncoded] ?: @"",
                                            }
                                  success:^(NSURLSessionDataTask *task, ZBResponseModel *responseModel) {
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


#pragma mark - PayPalPaymentDelegate
- (void)payPalPaymentViewController:(PayPalPaymentViewController *)paymentViewController
                 didCompletePayment:(PayPalPayment *)completedPayment {
    
    [self rechargeWithConfirmation:completedPayment.confirmation
                           success:^(ZBResponseModel *responseModel) {
                               if ([self.delegate respondsToSelector:@selector(payPalDidCompletePayment)]) {
                                   [self.delegate payPalDidCompletePayment];
                                   [self.viewController dismissViewControllerAnimated:YES completion:nil];
                               }
                           }
                           failure:^(NSError *error) {
                               
                           }];
}

- (void)payPalPaymentDidCancel:(PayPalPaymentViewController *)paymentViewController {
    if ([self.delegate respondsToSelector:@selector(payPalDidCancelPayment)]) {
        [self.delegate payPalDidCancelPayment];
    }
    [self.viewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - private methods

#pragma mark - getter & setter
- (PayPalConfiguration *)payPalConfiguration {
    if (!_payPalConfiguration) {
        _payPalConfiguration = [[PayPalConfiguration alloc] init];
        _payPalConfiguration.acceptCreditCards = NO;
        _payPalConfiguration.payPalShippingAddressOption = PayPalShippingAddressOptionPayPal;
    }
    return _payPalConfiguration;
}

- (UIViewController *)viewController {
    if (!_viewController) {
        _viewController = [ZBRoutable currentVC];
    }
    return _viewController;
}
@end
