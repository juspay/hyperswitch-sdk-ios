//
//  HyperTurboModule.mm
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

@interface HyperModule : NativeHyperModuleSpecBase <NativeHyperModuleSpec, HyperModuleShim>
@end

@implementation HyperModule {
  HyperModuleImpl *_impl;
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

#pragma mark - HyperModuleShim

- (void)attachImpl:(HyperModuleImpl *)impl
{
  _impl = impl;
}

- (UIView *)viewForRootTag:(NSNumber *)rootTag
{
  return [[_surfacePresenter surfaceForRootTag:rootTag.intValue] view];
}

- (void)emitEventWithName:(NSString *)name payload:(NSDictionary<NSString *, id> *)payload
{
  if (!_eventEmitterCallback) {
    return;
  }
  if ([name isEqualToString:@"confirm"]) {
    [self emitConfirm:payload];
  } else if ([name isEqualToString:@"widget"]) {
    [self emitWidget:payload];
  } else if ([name isEqualToString:@"confirmEC"]) {
    [self emitConfirmEC:payload];
  } else if ([name isEqualToString:@"triggerWidgetAction"]) {
    [self emitTriggerWidgetAction:payload];
  } else if ([name isEqualToString:@"updateIntentInit"]) {
    [self emitUpdateIntentInit:payload];
  } else if ([name isEqualToString:@"updateIntentComplete"]) {
    [self emitUpdateIntentComplete:payload];
  }
}

#pragma mark - NativeHyperModuleSpec

- (void)sendMessageToNative:(NSString *)message
{
  [_impl sendMessageToNative:message];
}

- (void)launchApplePay:(NSString *)requestObj callback:(RCTResponseSenderBlock)callback
{
  [_impl launchApplePay:requestObj callback:callback];
}

- (void)startApplePay:(NSString *)requestObj callback:(RCTResponseSenderBlock)callback
{
  [_impl startApplePay:requestObj callback:callback];
}

- (void)presentApplePay:(NSString *)requestObj callback:(RCTResponseSenderBlock)callback
{
  [_impl presentApplePay:requestObj callback:callback];
}

- (void)launchGPay:(NSString *)requestObj callback:(RCTResponseSenderBlock)callback
{
  [_impl launchGPay:requestObj callback:callback];
}

- (void)exitPaymentsheet:(NSInteger)rootTag result:(NSString *)result reset:(BOOL)reset
{
  [_impl exitPaymentsheet:@(rootTag) result:result reset:reset];
}

- (void)exitPaymentMethodManagement:(NSInteger)rootTag result:(NSString *)result reset:(BOOL)reset
{
  [_impl exitPaymentMethodManagement:@(rootTag) result:result reset:reset];
}

- (void)exitWidgetPaymentsheet:(NSInteger)rootTag result:(NSString *)result reset:(BOOL)reset
{
  [_impl exitWidgetPaymentsheet:@(rootTag) result:result reset:reset];
}

- (void)exitWidget:(NSString *)result widgetType:(NSString *)widgetType
{
  [_impl exitWidget:result widgetType:widgetType];
}

- (void)exitCardForm:(NSString *)result
{
  [_impl exitCardForm:result];
}

- (void)onAddPaymentMethod:(NSString *)data
{
  [_impl onAddPaymentMethod:data];
}

- (void)updateWidgetHeight:(NSInteger)height
{
  [_impl updateWidgetHeight:@(height)];
}

- (void)notifyWidgetPaymentResult:(NSInteger)rootTag result:(NSString *)result
{
  [_impl notifyWidgetPaymentResult:@(rootTag) result:result];
}

- (void)emitPaymentEvent:(NSInteger)rootTag eventType:(NSString *)eventType payload:(NSDictionary *)payload
{
  [_impl emitPaymentEvent:@(rootTag) eventType:eventType payload:payload];
}

- (void)onUpdateIntentEvent:(NSInteger)rootTag eventType:(NSString *)eventType result:(NSString *)result
{
  [_impl onUpdateIntentEvent:@(rootTag) eventType:eventType result:result];
}

- (void)onPaymentConfirmButtonClick:(NSInteger)rootTag
                            payload:(NSString *)payload
                           callback:(RCTResponseSenderBlock)callback
{
  [_impl onPaymentConfirmButtonClick:@(rootTag) payload:payload callback:callback];
}

- (void)openIframeBridge:(NSString *)url timeoutMs:(NSInteger)timeoutMs callback:(RCTResponseSenderBlock)callback
{
  [_impl openIframeBridge:url timeoutMs:@(timeoutMs) callback:callback];
}

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params
{
  return std::make_shared<facebook::react::NativeHyperModuleSpecJSI>(params);
}

@end

#endif // RCT_NEW_ARCH_ENABLED
