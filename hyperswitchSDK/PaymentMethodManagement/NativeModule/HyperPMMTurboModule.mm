//
//  HyperPMMTurboModule.mm
//  Hyperswitch
//
//  Bridges the PMM realm's TurboModule (`HyperPMMModule`) to the Swift implementation.
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

@interface HyperPMMModule
    : NativeHyperPMMModuleSpecBase <NativeHyperPMMModuleSpec, PaymentMethodManagementModuleShim>
@end

@implementation HyperPMMModule {
  PaymentMethodManagementModuleImpl *_impl;
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

#pragma mark - PaymentMethodManagementModuleShim

- (void)attachImpl:(PaymentMethodManagementModuleImpl *)impl
{
  _impl = impl;
}

- (id)surfaceForRootTag:(NSNumber *)rootTag
{
  return [_surfacePresenter surfaceForRootTag:rootTag.intValue];
}

- (void)emitEventWithName:(NSString *)name payload:(NSDictionary<NSString *, id> *)payload
{
  if (!_eventEmitterCallback) {
    return;
  }
  if ([name isEqualToString:@"triggerWidgetAction"]) {
    [self emitTriggerWidgetAction:payload];
  }
}

#pragma mark - NativeHyperPMMModuleSpec

- (void)exitPaymentMethodManagement:(NSInteger)rootTag result:(NSString *)result reset:(BOOL)reset
{
  [_impl exitPaymentMethodManagement:@(rootTag) result:result ?: @"{}" reset:reset];
}

// The spec declares `result` as the generated struct, not an NSDictionary: the
// bridge hands us a `PaymentExitResult&` on the stack. Declaring it as an
// NSDictionary here makes ARC retain a C++ struct as if it were an ObjC object —
// a hard crash (the payments HyperTurboModule maps it the same way).
- (void)notifyWidgetPaymentResult:(NSInteger)rootTag result:(JS::NativeHyperPMMModule::PaymentExitResult &)result
{
  [_impl notifyWidgetPaymentResult:@(rootTag) status:result.status() code:result.code() message:result.message()];
}

- (void)emitPaymentEvent:(NSInteger)rootTag eventType:(NSString *)eventType payload:(NSDictionary *)payload
{
  [_impl emitPaymentEvent:@(rootTag) eventType:eventType payload:payload ?: @{}];
}

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params
{
  return std::make_shared<facebook::react::NativeHyperPMMModuleSpecJSI>(params);
}

@end

#endif
