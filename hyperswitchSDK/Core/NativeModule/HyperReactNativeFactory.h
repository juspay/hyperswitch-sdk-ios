//
//  HyperReactNativeFactory.h
//  Hyperswitch
//
//  Loads the SDK's split JavaScript the way the bundler (Re.Pack) lays it out.
//

#import <Foundation/Foundation.h>
#import <React_RCTAppDelegate/RCTReactNativeFactory.h>

NS_ASSUME_NONNULL_BEGIN

/// A React Native factory whose host evaluates the SDK's runtime chunk before the entry bundle.
///
/// `yarn bundle:ios` writes an entry bundle (`hyperswitch.bundle`,
/// `hyperswitch-payment-methods.bundle`) and, next to it, chunk files named
/// `<entry name>.<chunk>.chunk.bundle`:
///
/// - `<entry name>.react-native.chunk.bundle` holds React Native and React. The entry's
///   startup waits for it, so it is evaluated once the runtime exists and before the
///   entry runs. It only registers module factories, so no native module need be ready.
/// - every other chunk (sentry, paypal, netcetera-3ds, scancard, vault, vgs, ...) is
///   loaded on demand by the JS side through Re.Pack's `ScriptManager` module
///   (`src/chunks/ScriptResolver.res`).
///
/// Before either, it describes the layout to the JS resolver
/// (`globalThis.__HYPERSWITCH_SCRIPTS__`): the directory the entry came from (the
/// SDK's resources, or an OTA download) with the files it holds, and the SDK's own
/// resource directory, where any chunk an OTA download lacks is read from.
///
/// A bundle built without splitting has no runtime chunk and loads as before; a
/// bundle served by a development server is left to it.
@interface HyperReactNativeFactory : RCTReactNativeFactory

/// - Parameter resourceDirectory: directory of the SDK's packaged bundles and chunks.
- (instancetype)initWithDelegate:(id<RCTReactNativeFactoryDelegate>)delegate
               resourceDirectory:(nullable NSString *)resourceDirectory;

/// File name of the runtime chunk that belongs to `bundleFileName`.
+ (NSString *)runtimeChunkNameForBundle:(NSString *)bundleFileName;

@end

NS_ASSUME_NONNULL_END
