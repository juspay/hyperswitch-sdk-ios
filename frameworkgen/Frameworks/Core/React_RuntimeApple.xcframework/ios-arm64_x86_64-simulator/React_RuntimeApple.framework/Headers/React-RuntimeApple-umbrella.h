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

#import "ReactCommon/ObjCTimerRegistry.h"
#import "ReactCommon/RCTContextContainerHandling.h"
#import "ReactCommon/RCTHermesInstance.h"
#import "ReactCommon/RCTHost+Internal.h"
#import "ReactCommon/RCTHost.h"
#import "ReactCommon/RCTInstance.h"
#import "ReactCommon/RCTJSThreadManager.h"
#import "ReactCommon/RCTLegacyUIManagerConstantsProvider.h"
#import "ReactCommon/RCTPerformanceLoggerUtils.h"

FOUNDATION_EXPORT double React_RuntimeAppleVersionNumber;
FOUNDATION_EXPORT const unsigned char React_RuntimeAppleVersionString[];

