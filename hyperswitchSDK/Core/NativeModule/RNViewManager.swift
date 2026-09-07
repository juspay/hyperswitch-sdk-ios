//
//  RNViewManager.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 01/08/26.
//

import Foundation
import React
import ReactAppDependencyProvider
import React_RCTAppDelegate

internal protocol ReactHostManager: AnyObject {
    var hyperModule: HyperModuleImpl { get }
    var headlessModule: HyperHeadlessImpl { get }
    var responseHandler: RNResponseHandler? { get set }
    var rootView: UIView? { get }
}

extension UIView {
    internal var surfaceRootTag: NSNumber? {
        guard let rootView = self as? RCTSurfaceHostingProxyRootView else { return nil }
        return NSNumber(value: rootView.surface.rootTag)
    }

    internal func nearestAncestor(where predicate: (UIView) -> Bool) -> UIView? {
        var current: UIView? = self
        while let view = current {
            if predicate(view) {
                return view
            }
            current = view.superview
        }
        return nil
    }

    internal func nearestAncestor<T>(ofType type: T.Type) -> T? {
        return nearestAncestor(where: { $0 is T }) as? T
    }
}

internal class RNFactoryDelegate: RCTDefaultReactNativeFactoryDelegate {

    internal weak var manager: ReactHostManager?

    @objc(getModuleInstanceFromClass:)
    internal func getModuleInstanceFromClass(_ moduleClass: AnyClass) -> AnyObject? {
        guard let manager = manager else { return nil }
        if let shimType = moduleClass as? (NSObject & HyperModuleShim).Type {
            let shim = shimType.init()
            manager.hyperModule.attach(to: shim)
            return shim
        }
        if let shimType = moduleClass as? (NSObject & HyperHeadlessShim).Type {
            let shim = shimType.init()
            manager.headlessModule.attach(to: shim)
            return shim
        }
        return nil
    }
}

internal class RNViewManagerDelegate: RNFactoryDelegate {

    override func sourceURL(for bridge: RCTBridge) -> URL? {
        return bundleURL()
    }

    override func bundleURL() -> URL? {
        switch Helper.getInfoPlist("HyperswitchSource") {
        case "LocalHosted":
            return RCTBundleURLProvider.sharedSettings().jsBundleURL(forBundleRoot: "index")
        case "LocalBundle":
            return Bundle.main.url(forResource: "hyperswitch", withExtension: "bundle")
        default:
            #if canImport(HyperOTA)
            return OTAServices.shared.getBundleURL()
            #else
            return Bundle(for: RNViewManager.self).url(forResource: "hyperswitch", withExtension: "bundle")
            #endif
        }
    }
}

internal class RNViewManager: NSObject, ReactHostManager {

    internal let hyperModule = HyperModuleImpl()
    internal let headlessModule = HyperHeadlessImpl()
    internal var responseHandler: RNResponseHandler?
    internal private(set) var rootView: UIView?

    private let delegate: RNViewManagerDelegate

    internal lazy var factory: RCTReactNativeFactory = {
        RCTReactNativeFactory(delegate: self.delegate)
    }()

    internal override init() {
        self.delegate = RNViewManagerDelegate()
        super.init()
        self.delegate.dependencyProvider = RCTAppDependencyProvider()
        self.delegate.manager = self
        self.hyperModule.host = self
    }

    internal func presentedViewForModule(_ moduleName: String, initialProperties: [String: Any]?) -> UIView {
        let rootView = factory.rootViewFactory.view(
            withModuleName: moduleName,
            initialProperties: initialProperties
        )
        self.rootView = rootView
        return rootView
    }

    internal func viewForModule(_ moduleName: String, initialProperties: [String: Any]?) -> UIView {
        return factory.rootViewFactory.view(
            withModuleName: moduleName,
            initialProperties: initialProperties
        )
    }

    internal func awaitReady() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                if self.hyperModule.isAttached {
                    continuation.resume()
                } else {
                    self.hyperModule.onAttached = { continuation.resume() }
                }
            }
        }
    }
}
