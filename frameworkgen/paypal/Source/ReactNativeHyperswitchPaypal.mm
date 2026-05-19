#import <React/RCTBridgeModule.h>
#import <React/RCTViewManager.h>

@interface RCT_EXTERN_MODULE(HyperswitchPaypal, NSObject)

RCT_EXTERN_METHOD(launchPayPal:(NSString *)requestObj
                  callback:(RCTResponseSenderBlock)callback)

@end

@interface RCT_EXTERN_MODULE(PaypalButton, RCTViewManager)

RCT_EXPORT_VIEW_PROPERTY(buttonColor, NSString)
RCT_EXPORT_VIEW_PROPERTY(buttonLabel, NSString)
RCT_EXPORT_VIEW_PROPERTY(borderRadius, double)

@end
