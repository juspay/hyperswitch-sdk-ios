//
//  HyperHeadless.m
//  Hyperswitch
//
//  Created by Shivam Shashank on 06/03/24.
//

#import <React/RCTEventEmitter.h>

@interface RCT_EXTERN_MODULE(HyperHeadless, RCTEventEmitter)

RCT_EXTERN_METHOD(initialisePaymentSession: (RCTResponseSenderBlock)rnCallback)
RCT_EXTERN_METHOD(getPaymentSession: (NSDictionary)rnMessage :(NSArray)rnMessage2 :(RCTResponseSenderBlock)rnCallback)
RCT_EXTERN_METHOD(exitHeadless: (NSDictionary)rnMessage)

@end
