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

#import "react/performance/timeline/BoundedConsumableBuffer.h"
#import "react/performance/timeline/PerformanceEntryReporter.h"

FOUNDATION_EXPORT double React_performancetimelineVersionNumber;
FOUNDATION_EXPORT const unsigned char React_performancetimelineVersionString[];

