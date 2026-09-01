//
//  HyperVaultModule.mm
//  HyperswitchVault
//
//  Bridge between JS vault field widgets (client-core, New Arch surface)
//  and the native vault pod (VaultStateStore + TokeniseDispatcher).
//
//  Plain RCTBridgeModule — works on both the Old Arch (via the bridge) and
//  the New Arch (via the TurboModule interop, which exposes every
//  RCTBridgeModule as a TurboModule with the same name). No codegen spec
//  is required for three-method, no-return shape — the methods are called
//  from JS with the exact signatures exported below.
//

#import <React/RCTBridgeModule.h>

#if __has_include("HyperswitchVault-Swift.h")
#import "HyperswitchVault-Swift.h"
#else
#import <HyperswitchVault/HyperswitchVault-Swift.h>
#endif

@interface HyperVaultModule : NSObject <RCTBridgeModule>
@end

@implementation HyperVaultModule {
  HyperVaultModuleImpl *_impl;
}

RCT_EXPORT_MODULE(HyperVaultModule)

+ (BOOL)requiresMainQueueSetup
{
  return NO;
}

- (instancetype)init
{
  self = [super init];
  if (self) {
    _impl = [[HyperVaultModuleImpl alloc] init];
  }
  return self;
}

RCT_EXPORT_METHOD(updateFieldState:(nonnull NSNumber *)rootTag
                             state:(nonnull NSString *)state)
{
  [_impl updateFieldState:rootTag state:state];
}

RCT_EXPORT_METHOD(updateVaultFieldStates:(nonnull NSString *)statesJson)
{
  [_impl updateVaultFieldStates:statesJson];
}

RCT_EXPORT_METHOD(returnTokenizedValue:(nonnull NSString *)resultJson)
{
  [_impl returnTokenizedValue:resultJson];
}

@end
