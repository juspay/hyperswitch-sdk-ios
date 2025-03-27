#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(HyperswitchNetcetera3ds, NSObject)


RCT_EXTERN_METHOD(initialiseNetceteraSDK: 
                  (NSString *)apiKey:
                  (NSString *)hsSDKEnvironment:
                  (RCTResponseSenderBlock)callback)

RCT_EXTERN_METHOD(generateAReqParams: 
                  (NSString *)messageVersion:
                  (NSString *)directoryServerId:
                  (RCTResponseSenderBlock)callback)

RCT_EXTERN_METHOD(recieveChallengeParamsFromRN:
                  (NSString *)acsSignedContent:
                  (NSString *)acsRefNumber:
                  (NSString *)acsTransactionId:
                  (nullable NSString *)threeDSRequestorAppURL:
                  (NSString *)threeDSServerTransId:
                  (RCTResponseSenderBlock)callback)

RCT_EXTERN_METHOD(generateChallenge: (RCTResponseSenderBlock)callback)

+ (BOOL)requiresMainQueueSetup
{
    return NO;
}

@end
