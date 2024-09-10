#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "BridgeNativeModulePerfLogger.h"
#import "HermesPerfettoDataSource.h"
#import "NativeModulePerfLogger.h"
#import "ReactPerfetto.h"
#import "ReactPerfettoCategories.h"

FOUNDATION_EXPORT double reactperfloggerVersionNumber;
FOUNDATION_EXPORT const unsigned char reactperfloggerVersionString[];

