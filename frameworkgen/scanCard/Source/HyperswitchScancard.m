#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(HyperswitchScancard, NSObject)

RCT_EXTERN_METHOD(launchScanCard: (NSString)rnMessage :(RCTResponseSenderBlock)rnCallback)

+ (BOOL)requiresMainQueueSetup
{
    return NO;
}

@end
