//
//  VaultDependencyProvider.m
//  hyperswitch-vault-sdk-ios
//
//  Registers ONLY the fabric component classes that are actually linked
//  into the hosting binary. The name list mirrors the workspace's generated
//  RCTThirdPartyComponentsProvider.mm — refresh it if RNSVG /
//  react-native-safe-area-context rename their codegen component classes.
//

#import "VaultDependencyProvider.h"

@implementation VaultDependencyProvider

- (NSDictionary<NSString *, Class<RCTComponentViewProtocol>> *)thirdPartyFabricComponents {
    static NSArray<NSString *> *candidateClassNames = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        candidateClassNames = @[
            // main payments SDK — intentionally NOT linked in vault-only hosts
            @"ApplePayButtonComponentView",
            // react-native-safe-area-context
            @"RNCSafeAreaProviderComponentView", @"RNCSafeAreaViewComponentView",
            // react-native-svg (card brand icons + field surfaces)
            @"RNSVGCircle", @"RNSVGClipPath", @"RNSVGDefs", @"RNSVGEllipse",
            @"RNSVGFeBlend", @"RNSVGFeColorMatrix", @"RNSVGFeComposite",
            @"RNSVGFeFlood", @"RNSVGFeGaussianBlur", @"RNSVGFeMerge",
            @"RNSVGFeOffset", @"RNSVGFilter", @"RNSVGForeignObject", @"RNSVGGroup",
            @"RNSVGImage", @"RNSVGLine", @"RNSVGLinearGradient", @"RNSVGMarker",
            @"RNSVGMask", @"RNSVGPath", @"RNSVGPattern", @"RNSVGRadialGradient",
            @"RNSVGRect", @"RNSVGSvgView", @"RNSVGSymbol", @"RNSVGTSpan",
            @"RNSVGText", @"RNSVGTextPath", @"RNSVGUse",
        ];
    });

    Protocol *fabricProtocol = NSProtocolFromString(@"RCTComponentViewProtocol");
    NSMutableDictionary<NSString *, Class<RCTComponentViewProtocol>> *registry = [NSMutableDictionary dictionary];
    for (NSString *name in candidateClassNames) {
        Class cls = NSClassFromString(name);
        if (cls == Nil) { continue; }
        if (fabricProtocol != nil && ![(id)cls conformsToProtocol:fabricProtocol]) { continue; }
        registry[name] = cls;
    }
    return registry;
}

@end
