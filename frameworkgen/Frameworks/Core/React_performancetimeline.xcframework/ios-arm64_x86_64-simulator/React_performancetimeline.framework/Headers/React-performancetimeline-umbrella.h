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

#import "react/performance/timeline/CircularBuffer.h"
#import "react/performance/timeline/PerformanceEntry.h"
#import "react/performance/timeline/PerformanceEntryBuffer.h"
#import "react/performance/timeline/PerformanceEntryCircularBuffer.h"
#import "react/performance/timeline/PerformanceEntryKeyedBuffer.h"
#import "react/performance/timeline/PerformanceEntryReporter.h"
#import "react/performance/timeline/PerformanceObserver.h"
#import "react/performance/timeline/PerformanceObserverRegistry.h"

FOUNDATION_EXPORT double React_performancetimelineVersionNumber;
FOUNDATION_EXPORT const unsigned char React_performancetimelineVersionString[];

