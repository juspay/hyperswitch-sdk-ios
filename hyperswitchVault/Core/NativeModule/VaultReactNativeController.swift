//
//  VaultReactNativeController.swift
//  HyperswitchVault
//
//  Single shared React Native runtime used by every vault field surface.
//

import Foundation
import React
import React_RCTAppDelegate
#if canImport(ReactAppDependencyProvider)
import ReactAppDependencyProvider
#endif

internal class VaultReactDelegate: RCTDefaultReactNativeFactoryDelegate {

    /// The vault JS bundle is compiled for the Fabric renderer and expects the
    /// bridgeless runtime (`nativeFabricUIManager` must exist). Always-on: the
    /// vault SDK runs on the host workspace's RN distribution (0.86 pods),
    /// the same way the main HyperswitchSDK does; `fabricEnabled` /
    /// `bridgelessEnabled` / `turboModuleEnabled` all forward to this.
    override func newArchEnabled() -> Bool {
        return true
    }

    /// The superclass raises on an unimplemented sourceURL — keep this as
    /// the single path.
    override func sourceURL(for bridge: RCTBridge) -> URL? {
        return bundleURL()
    }

    /// Debug loads the vault JS from Metro (`yarn start`) with main module
    /// "index" (index.js registers "hs-vault") — same flow as Android's
    /// debug builds. Release ships the prebuilt bundle resource packaged in
    /// the HyperswitchVault pod (see hyperswitch-vault-sdk-ios.podspec).
    override func bundleURL() -> URL? {
#if DEBUG
        return RCTBundleURLProvider.sharedSettings().jsBundleURL(forBundleRoot: "index")
#else
        return Bundle(for: VaultReactNativeController.self)
            .url(forResource: "hyperswitch-vault", withExtension: "bundle")
#endif
    }
}

internal final class VaultReactNativeController {

    static let shared = VaultReactNativeController()

    internal let moduleName = "hs-vault"

    /// Event name for tokenise broadcasts; mirrors src/vault/registry.js.
    static let tokeniseEventName = "hsVaultTokenise"

    private let delegate: VaultReactDelegate

    internal lazy var factory: RCTReactNativeFactory = {
        RCTReactNativeFactory(delegate: delegate)
    }()

    private init() {
        delegate = VaultReactDelegate()
        #if canImport(ReactAppDependencyProvider)
        delegate.dependencyProvider = RCTAppDependencyProvider()
        #endif
    }

    /// Creates the surface (root view) of one vault field.
    internal func rootView(initialProperties: [String: Any]?) -> UIView {
        return factory.rootViewFactory.view(
            withModuleName: moduleName,
            initialProperties: initialProperties
        )
    }

    /// Broadcasts an event to every vault JS surface on this runtime.
    internal func emitDeviceEvent(name: String, body: Any? = nil) {
        factory.bridge?.eventDispatcher().sendDeviceEvent(withName: name, body: body)
    }
}

internal extension UIView {
    /// Root tag of the React surface hosted by this view, if any.
    var surfaceRootTag: NSNumber? {
        guard let rootView = self as? RCTSurfaceHostingProxyRootView else { return nil }
        return NSNumber(value: rootView.surface.rootTag)
    }
}
