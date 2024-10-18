#import <React/RCTEventEmitter.h>

@interface RCT_EXTERN_MODULE(HyperModule, RCTEventEmitter)

RCT_EXTERN_METHOD(sendMessageToNative: (NSString)rnMessage)
RCT_EXTERN_METHOD(presentPaymentSheet: (NSDictionary) rnMessage :(RCTResponseSenderBlock)rnCallback)
RCT_EXTERN_METHOD(exitPaymentsheet: (nonnull NSNumber *)reactTag :(NSString)rnMessage :(BOOL)reset)
RCT_EXTERN_METHOD(exitPaymentMethodManagement: (nonnull NSNumber *)reactTag :(NSString)rnMessage :(BOOL)reset)
RCT_EXTERN_METHOD(exitCardForm: (NSString)rnMessage)
RCT_EXTERN_METHOD(launchWidgetPaymentSheet: (NSDictionary) rnMessage :(RCTResponseSenderBlock)rnCallback)
RCT_EXTERN_METHOD(onAddPaymentMethod: (NSString)rnMessage)
RCT_EXTERN_METHOD(exitWidgetPaymentsheet: (nonnull NSNumber *)reactTag :(NSString)rnMessage :(BOOL)reset)
RCT_EXTERN_METHOD(launchApplePay: (NSString)rnMessage :(RCTResponseSenderBlock)rnCallback)
RCT_EXTERN_METHOD(startApplePay: (NSString)rnMessage :(RCTResponseSenderBlock)startCallback)
RCT_EXTERN_METHOD(presentApplePay: (NSString)rnMessage :(RCTResponseSenderBlock)presentCallback)

@end

