//
//  HyperHeadlessTurboModule.mm
//  Hyperswitch
//
//  Created by Harshit Srivastava on 01/08/26.
//

#ifdef RCT_NEW_ARCH_ENABLED

#import <React/RCTBridgeModule.h>

#if __has_include(<ReactCodegen/HyperswitchClientCoreSpec/HyperswitchClientCoreSpec.h>)
#import <ReactCodegen/HyperswitchClientCoreSpec/HyperswitchClientCoreSpec.h>
#else
#import "HyperswitchClientCoreSpec/HyperswitchClientCoreSpec.h"
#endif

#import "HyperSwiftInterface.h"

@interface HyperHeadless : NativeHyperHeadlessSpecBase <NativeHyperHeadlessSpec, HyperHeadlessShim>
@end

@implementation HyperHeadless {
  HyperHeadlessImpl *_impl;
}

RCT_EXPORT_MODULE()

+ (BOOL)requiresMainQueueSetup
{
  return YES;
}

- (dispatch_queue_t)methodQueue
{
  return dispatch_get_main_queue();
}

#pragma mark - HyperHeadlessShim

- (void)attachImpl:(HyperHeadlessImpl *)impl
{
  _impl = impl;
}

#pragma mark - NativeHyperHeadlessSpec

- (void)getPaymentSession:(NSString *)sdkAuthorization
        paymentIntentData:(NSDictionary *)paymentIntentData
     defaultPaymentMethod:(NSDictionary *)defaultPaymentMethod
      savedPaymentMethods:(NSArray *)savedPaymentMethods
                 callback:(RCTResponseSenderBlock)callback
{
  [_impl getPaymentSession:sdkAuthorization
         paymentIntentData:paymentIntentData
      defaultPaymentMethod:defaultPaymentMethod
       savedPaymentMethods:savedPaymentMethods
                  callback:callback];
}

- (void)exitHeadless:(NSString *)sdkAuthorization result:(JS::NativeHyperHeadless::PaymentExitResult &)result
{
  [_impl exitHeadless:sdkAuthorization status:result.status() code:result.code() message:result.message()];
}

- (void)completePrefetch:(NSDictionary *)data
{
  [_impl completePrefetch:data];
}

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params
{
  return std::make_shared<facebook::react::NativeHyperHeadlessSpecJSI>(params);
}

@end

#endif // RCT_NEW_ARCH_ENABLED
