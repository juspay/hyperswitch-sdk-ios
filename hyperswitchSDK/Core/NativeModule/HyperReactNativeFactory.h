//
//  HyperReactNativeFactory.h
//  Hyperswitch
//
//  Loads the SDK's split JavaScript the way the bundler (Re.Pack) lays it out.
//

#import <Foundation/Foundation.h>
#import <React_RCTAppDelegate/RCTReactNativeFactory.h>

NS_ASSUME_NONNULL_BEGIN

/// A React Native factory whose host evaluates the SDK's shared initial chunks before the
/// entry bundle.
///
/// `yarn bundle:ios` builds every entry in one compilation and writes, next to each other,
/// one entry bundle per React host (`hyperswitch.bundle`, `hyperswitch-payment-methods.bundle`)
/// and chunk files every entry shares, `hyperswitch.<chunk>.chunk.bundle`:
///
/// - the initial chunks (`+initialChunks`: React Native, and every other package the
///   entries use from the start). The entry's startup waits for them, so they are
///   evaluated once the runtime exists and before the entry runs. They only register
///   module factories, so no native module need be ready.
/// - every other chunk (sentry, vault, vgs, ...) is loaded on demand by the JS side
///   through Re.Pack's `ScriptManager` module (`src/chunks/ScriptResolver.res`).
///
/// Before either, it describes the layout to the JS resolver
/// (`globalThis.__HYPERSWITCH_SCRIPTS__`): the directory the entry came from (the
/// SDK's resources, or an OTA download) with the files it holds, and the SDK's own
/// resource directory, where any chunk an OTA download lacks is read from.
///
/// A bundle served by a development server is left to it.
@interface HyperReactNativeFactory : RCTReactNativeFactory

/// - Parameter resourceDirectory: directory of the SDK's packaged bundles and chunks.
- (instancetype)initWithDelegate:(id<RCTReactNativeFactoryDelegate>)delegate
               resourceDirectory:(nullable NSString *)resourceDirectory;

/// Shared chunks every entry needs before it starts, in load order; see rspack.config.mjs.
@property (class, nonatomic, readonly) NSArray<NSString *> *initialChunks;

/// The files an entry at `bundleURL` needs that are not in the app, joined by ", ": the
/// entry and the initial chunks (which may come from `resourceDirectory` instead). Nil
/// when it can start, or when a development server serves it. A missing bundle must be
/// caught here: React Native ends the app (RCTFatal) when it cannot load one.
+ (nullable NSString *)missingFilesForBundleURL:(nullable NSURL *)bundleURL
                              resourceDirectory:(nullable NSString *)resourceDirectory
    NS_SWIFT_NAME(missingFiles(bundleURL:resourceDirectory:));

@end

NS_ASSUME_NONNULL_END
