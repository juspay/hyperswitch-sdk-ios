//
//  HyperHeadless.m
//  Hyperswitch
//
//  Created by Shivam Shashank on 06/03/24.
//

#import <React/RCTEventEmitter.h>

@interface RCT_EXTERN_MODULE(HyperHeadless, RCTEventEmitter)

RCT_EXTERN_METHOD(getPaymentSession: (NSString)sdkAuthorization :(NSDictionary)rnMessage :(NSDictionary)rnMessage2 :(NSArray)rnMessage3 :(RCTResponseSenderBlock)rnCallback)
RCT_EXTERN_METHOD(exitHeadless: (NSString)sdkAuthorization :(NSString)rnMessage)
RCT_EXTERN_METHOD(storePrefetchedApiData: (NSDictionary)data)

@end
