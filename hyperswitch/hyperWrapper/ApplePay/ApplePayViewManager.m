#import <React/RCTViewManager.h>

@interface RCT_EXTERN_MODULE(ApplePayViewManager, RCTViewManager)

RCT_EXPORT_VIEW_PROPERTY(buttonStyle, NSString)
RCT_EXPORT_VIEW_PROPERTY(buttonType, NSString)
RCT_EXPORT_VIEW_PROPERTY(color, NSString)
RCT_EXPORT_VIEW_PROPERTY(cornerRadius,CGFloat)
RCT_EXPORT_VIEW_PROPERTY(onPaymentResultCallback, RCTDirectEventBlock)

@end
