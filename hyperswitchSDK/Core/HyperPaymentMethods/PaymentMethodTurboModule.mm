//
//  PaymentMethodTurboModule.mm
//  Hyperswitch
//
//  Dedicated TurboModule for the payment-methods session's JS runtime — kept separate from
//  HyperModule so that payment-method events never depend on the main SDK's event bus.
//

#ifdef RCT_NEW_ARCH_ENABLED

#import <React/RCTBridgeModule.h>

#if __has_include(<ReactCodegen/HyperswitchClientCoreSpec/HyperswitchClientCoreSpec.h>)
#import <ReactCodegen/HyperswitchClientCoreSpec/HyperswitchClientCoreSpec.h>
#else
#import "HyperswitchClientCoreSpec/HyperswitchClientCoreSpec.h"
#endif

#import "../NativeModule/HyperSwiftInterface.h"

@interface PaymentMethodModule : NativePaymentMethodModuleSpecBase <NativePaymentMethodModuleSpec, PaymentMethodModuleShim>
@end

@implementation PaymentMethodModule {
  PaymentMethodModuleImpl *_impl;
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

#pragma mark - PaymentMethodModuleShim

- (void)attachImpl:(PaymentMethodModuleImpl *)impl
{
  _impl = impl;
}

- (void)emitEventWithName:(NSString *)name payload:(NSDictionary<NSString *, id> *)payload
{
  if (!_eventEmitterCallback) {
    return;
  }
  if ([name isEqualToString:@"tokenise"]) {
    [self emitTokenise:payload];
  }
}

#pragma mark - NativePaymentMethodModuleSpec

- (void)returnTokenResult:(NSInteger)rootTag result:(NSDictionary *)result
{
  [_impl resolveTokeniseCallbackWithRootTag:rootTag result:result];
}

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params
{
  return std::make_shared<facebook::react::NativePaymentMethodModuleSpecJSI>(params);
}

@end

#endif // RCT_NEW_ARCH_ENABLED
