//
//  PaymentMethodsSwiftInterface.h
//  Hyperswitch Payment Methods
//
//  Swift-interface hook for the payment-method session SDK's ObjC++ sources.
//  This SDK builds in two shapes, each with its own generated Swift header:
//   - sources compiled into an app/module named `hyperswitch` (the sample app)
//   - sources compiled into the standalone `HyperswitchPaymentMethods` pod library
//

#import <PassKit/PassKit.h>
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <React_RCTAppDelegate/RCTDefaultReactNativeFactoryDelegate.h>

#if __has_include(<HyperCore/HyperCore.h>)
#import <HyperCore/HyperCore.h>
#endif

#if __has_include("hyperswitch-Swift.h")
#import "hyperswitch-Swift.h"
#elif __has_include(<hyperswitch/hyperswitch-Swift.h>)
#import <hyperswitch/hyperswitch-Swift.h>
#elif __has_include("HyperswitchPaymentMethods-Swift.h")
#import "HyperswitchPaymentMethods-Swift.h"
#else
#import <HyperswitchPaymentMethods/HyperswitchPaymentMethods-Swift.h>
#endif
