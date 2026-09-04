//
//  HyperHeadlessTurboModule.mm
//  Hyperswitch
//
//  Created by Harshit Srivastava on 01/08/26.
//

#ifdef RCT_NEW_ARCH_ENABLED

#import <React/RCTBridgeModule.h>
#import <React/RCTFabricSurface.h>
#import <React/RCTSurfacePresenter.h>
#import <React/RCTSurfacePresenterStub.h>
#import <React/RCTSurfaceView.h>

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
  __weak RCTSurfacePresenter *_surfacePresenter;
}

RCT_EXPORT_MODULE()

- (void)setSurfacePresenter:(id<RCTSurfacePresenterStub>)surfacePresenter
{
  _surfacePresenter = (RCTSurfacePresenter *)surfacePresenter;
}

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

- (UIView *)viewForRootTag:(NSNumber *)rootTag
{
  return [[_surfacePresenter surfaceForRootTag:rootTag.intValue] view];
}

#pragma mark - NativeHyperHeadlessSpec

- (void)getPaymentSession:(NSInteger)rootTag
        paymentIntentData:(NSDictionary *)paymentIntentData
     defaultPaymentMethod:(NSDictionary *)defaultPaymentMethod
      savedPaymentMethods:(NSArray *)savedPaymentMethods
                 callback:(RCTResponseSenderBlock)callback
{
  [_impl getPaymentSession:@(rootTag)
         paymentIntentData:paymentIntentData
      defaultPaymentMethod:defaultPaymentMethod
       savedPaymentMethods:savedPaymentMethods
                  callback:callback];
}

- (void)exitHeadless:(NSInteger)rootTag result:(JS::NativeHyperHeadless::PaymentExitResult &)result
{
  [_impl exitHeadless:@(rootTag) status:result.status() code:result.code() message:result.message()];
}

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params
{
  return std::make_shared<facebook::react::NativeHyperHeadlessSpecJSI>(params);
}

@end

#endif // RCT_NEW_ARCH_ENABLED
