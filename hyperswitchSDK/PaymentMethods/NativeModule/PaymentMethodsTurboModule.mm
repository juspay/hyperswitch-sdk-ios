//
//  PaymentMethodsTurboModule.mm
//  Hyperswitch
//
//  Created by Harshit Srivastava on 21/09/26.
//

#ifdef RCT_NEW_ARCH_ENABLED

#import <React/RCTBridgeModule.h>
#import <React/RCTSurfacePresenter.h>
#import <React/RCTSurfacePresenterStub.h>

#if __has_include(<ReactCodegen/HyperswitchClientCoreSpec/HyperswitchClientCoreSpec.h>)
#import <ReactCodegen/HyperswitchClientCoreSpec/HyperswitchClientCoreSpec.h>
#else
#import "HyperswitchClientCoreSpec/HyperswitchClientCoreSpec.h"
#endif

#import "../../Core/NativeModule/HyperSwiftInterface.h"

@interface HyperPaymentMethodsModule
    : NativeHyperPaymentMethodsSpecBase <NativeHyperPaymentMethodsSpec, PaymentMethodsModuleShim>
@end

@implementation HyperPaymentMethodsModule {
  PaymentMethodsModuleImpl *_impl;
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

#pragma mark - PaymentMethodsModuleShim

- (void)attachImpl:(PaymentMethodsModuleImpl *)impl
{
  _impl = impl;
}

- (id)surfaceForRootTag:(NSNumber *)rootTag
{
  return [_surfacePresenter surfaceForRootTag:rootTag.intValue];
}

- (void)emitCommand:(NSDictionary<NSString *, id> *)payload
{
  if (!_eventEmitterCallback) {
    return;
  }
  [self emitOnCommand:payload];
}

#pragma mark - NativeHyperPaymentMethodsSpec

- (void)emitFieldEvent:(NSInteger)rootTag eventName:(NSString *)eventName payload:(NSDictionary *)payload
{
  [_impl emitFieldEvent:@(rootTag) eventName:eventName payload:payload ?: @{}];
}

- (void)emitFormEvent:(NSInteger)rootTag eventName:(NSString *)eventName payload:(NSDictionary *)payload
{
  [_impl emitFormEvent:@(rootTag) eventName:eventName payload:payload ?: @{}];
}

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params
{
  return std::make_shared<facebook::react::NativeHyperPaymentMethodsSpecJSI>(params);
}

@end

#endif
