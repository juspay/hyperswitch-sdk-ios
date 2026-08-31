//
//  HyperVaultModule.mm
//  HyperswitchVault
//
//  ObjC shim exporting the JS -> native `HyperVaultModule` bridge.
//

#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(HyperVaultModule, NSObject)

RCT_EXTERN_METHOD(updateFieldState:(nonnull NSNumber *)rootTag state:(nonnull NSString *)state)

RCT_EXTERN_METHOD(updateVaultFieldStates:(nonnull NSString *)statesJson)

RCT_EXTERN_METHOD(submitTokeniseResult:(nonnull NSNumber *)requestId resultJson:(nonnull NSString *)resultJson)

@end
