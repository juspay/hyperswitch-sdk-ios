//
//  HyperVaultModule.mm
//  HyperswitchVault
//
//  Codegen TurboModule for the vault: JS → native methods forward to the
//  Swift backing (HyperVaultModuleImpl); native → JS goes through the
//  codegen-typed EventEmitter `onVaultTokenise` — the vault twin of the
//  main SDK's HyperModule (triggerWidgetAction / confirmCVC channel).
//
//  Bridgeless-only: the vault runtime is hard-pinned to the new
//  architecture (VaultReactDelegate.newArchEnabled == YES).
//

#import <React/RCTBridgeModule.h>

#if __has_include(<ReactCodegen/HyperswitchClientCoreSpec/HyperswitchClientCoreSpec.h>)
#import <ReactCodegen/HyperswitchClientCoreSpec/HyperswitchClientCoreSpec.h>
#else
#import "HyperswitchClientCoreSpec/HyperswitchClientCoreSpec.h"
#endif

#if __has_include("HyperswitchVault-Swift.h")
#import "HyperswitchVault-Swift.h"
#else
#import <HyperswitchVault/HyperswitchVault-Swift.h>
#endif

@interface HyperVaultModule : NativeHyperVaultModuleSpecBase <NativeHyperVaultModuleSpec, HyperVaultModuleShim>
@end

@implementation HyperVaultModule {
  HyperVaultModuleImpl *_impl;
}

RCT_EXPORT_MODULE()

/*
 * Guarantee a live `_impl` from birth: the Impl's methods only touch
 * singletons (VaultStateStore.shared / TokeniseDispatcher.shared), so this
 * fallback is fully functional for JS → native calls even if the factory
 * path (VaultReactDelegate.getModuleInstanceFromClass:) never attaches the
 * Impl singleton — e.g. an instance created by another runtime scanning
 * this RCT_EXPORT_MODULE'ed class. The pre-turbo bridge module did the
 * same; attachImpl: still swaps in the singleton for the emit wiring.
 */
- (instancetype)init
{
  self = [super init];
  if (self) {
    _impl = [[HyperVaultModuleImpl alloc] init];
  }
  return self;
}

+ (BOOL)requiresMainQueueSetup
{
  return YES;
}

- (dispatch_queue_t)methodQueue
{
  return dispatch_get_main_queue();
}

#pragma mark - HyperVaultModuleShim

- (void)attachImpl:(HyperVaultModuleImpl *)impl
{
  if (impl != nil) {
    _impl = impl;
  }
}

- (void)emitVaultTokeniseEventWithSdkAuthorization:(NSString *)sdkAuthorization
                                        environment:(NSString *)environment
{
  if (!_eventEmitterCallback) {
    return;
  }
  NSMutableDictionary<NSString *, id> *payload = [NSMutableDictionary new];
  if (sdkAuthorization != nil) {
    payload[@"sdkAuthorization"] = sdkAuthorization;
  }
  if (environment != nil) {
    payload[@"environment"] = environment;
  }
  [self emitOnVaultTokenise:payload];
}

#pragma mark - NativeHyperVaultModuleSpec

- (void)updateFieldState:(NSInteger)rootTag state:(NSString *)state
{
  [_impl updateFieldState:@(rootTag) state:state];
}

- (void)updateVaultFieldStates:(NSString *)statesJson
{
  [_impl updateVaultFieldStates:statesJson];
}

- (void)returnTokenizedValue:(NSString *)resultJson
{
  [_impl returnTokenizedValue:resultJson];
}

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params
{
  return std::make_shared<facebook::react::NativeHyperVaultModuleSpecJSI>(params);
}

@end
