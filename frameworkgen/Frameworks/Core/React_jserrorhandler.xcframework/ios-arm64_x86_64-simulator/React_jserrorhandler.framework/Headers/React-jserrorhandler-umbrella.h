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

#import "jserrorhandler/JsErrorHandler.h"
#import "jserrorhandler/StackTraceParser.h"

FOUNDATION_EXPORT double React_jserrorhandlerVersionNumber;
FOUNDATION_EXPORT const unsigned char React_jserrorhandlerVersionString[];

