//
//  VaultDependencyProvider.h
//  hyperswitch-vault-sdk-ios
//
//  Nil-safe replacement for the host workspace's generated
//  RCTAppDependencyProvider. The vault is a standalone library: it is
//  consumed by host apps whose RN codegen registry enumerates EVERY
//  component declared in that workspace (e.g. ApplePayView from the main
//  payments SDK's own codegenConfig). Classes not linked into a vault-only
//  host make NSClassFromString resolve to nil and crash the generated
//  registry's NSDictionary literal on the first entry.
//
//  Implemented in ObjC: the overridden selector's type involves
//  RCTComponentViewProtocol which is not surfaced as a Swift module in the
//  prebuilt React distribution.
//

#import <Foundation/Foundation.h>
#import <ReactAppDependencyProvider/RCTAppDependencyProvider.h>

@protocol RCTComponentViewProtocol;

NS_ASSUME_NONNULL_BEGIN
@interface VaultDependencyProvider : RCTAppDependencyProvider
@end
NS_ASSUME_NONNULL_END
