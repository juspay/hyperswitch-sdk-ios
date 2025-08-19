//
//  HyperHeadless.m
//  Hyperswitch
//
//  Created by Shivam Shashank on 06/03/24.
//

#import <React/RCTEventEmitter.h>

@interface RCT_EXTERN_MODULE(HyperHeadless, RCTEventEmitter)

RCT_EXTERN_METHOD(initialisePaymentSession: (RCTResponseSenderBlock)rnCallback)
RCT_EXTERN_METHOD(initialiseAuthSession: (RCTResponseSenderBlock)rnCallback)
RCT_EXTERN_METHOD(getPaymentSession: (NSDictionary)rnMessage :(NSDictionary)rnMessage2 :(NSArray)rnMessage3 :(RCTResponseSenderBlock)rnCallback)
RCT_EXTERN_METHOD(exitHeadless: (NSString)rnMessage)
RCT_EXTERN_METHOD(initThreeDs: (NSDictionary)threeDsData)
RCT_EXTERN_METHOD(generateAReqParams: (NSDictionary)aReqData)
RCT_EXTERN_METHOD(sendMessageToNative: (NSString)rnMessage)

@end
