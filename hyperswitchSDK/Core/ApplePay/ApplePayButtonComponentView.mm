//
//  ApplePayButtonComponentView.mm
//  Hyperswitch
//
//  Created by Harshit Srivastava on 01/08/26.
//

#import <React/RCTComponentViewFactory.h>
#import <React/RCTConversions.h>
#import <React/RCTViewComponentView.h>

#import <react/renderer/components/HyperswitchClientCoreSpec/ComponentDescriptors.h>
#import <react/renderer/components/HyperswitchClientCoreSpec/EventEmitters.h>
#import <react/renderer/components/HyperswitchClientCoreSpec/Props.h>

#import "HyperReactPrelude.h"
#import "Hyperswitch-Swift.h"

using namespace facebook::react;

@interface ApplePayButtonComponentView : RCTViewComponentView
@end

@implementation ApplePayButtonComponentView {
  HSApplePayView *_view;
  BOOL _initialPropsApplied;
}

// The component registers itself where this class is linked (the payments SDK). client-core's
// codegenConfig.ios.componentProvider is empty on purpose: codegen's list of components is
// compiled into HyperswitchReactNative, which apps also use without the payments SDK.
+ (void)load
{
  [[RCTComponentViewFactory currentComponentViewFactory] registerComponentViewClass:self];
}

+ (ComponentDescriptorProvider)componentDescriptorProvider
{
  return concreteComponentDescriptorProvider<ApplePayViewComponentDescriptor>();
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    static const auto defaultProps = std::make_shared<const ApplePayViewProps>();
    _props = defaultProps;
    _view = [[HSApplePayView alloc] initWithFrame:frame];
    __weak ApplePayButtonComponentView *weakSelf = self;
    _view.onPaymentResult = ^{
      [weakSelf emitPaymentResult];
    };
    self.contentView = _view;
  }
  return self;
}

- (void)prepareForRecycle
{
  [super prepareForRecycle];
  static const auto defaultProps = std::make_shared<const ApplePayViewProps>();
  _props = defaultProps;
  _initialPropsApplied = NO;
}

- (void)emitPaymentResult
{
  if (_eventEmitter) {
    std::static_pointer_cast<const ApplePayViewEventEmitter>(_eventEmitter)
        ->onPaymentResultCallback(ApplePayViewEventEmitter::OnPaymentResultCallback{});
  }
}

- (void)updateProps:(const Props::Shared &)props oldProps:(const Props::Shared &)oldProps
{
  const auto &oldViewProps = *std::static_pointer_cast<const ApplePayViewProps>(_props);
  const auto &newViewProps = *std::static_pointer_cast<const ApplePayViewProps>(props);

  BOOL applyAll = !_initialPropsApplied;
  _initialPropsApplied = YES;

  if (applyAll || oldViewProps.buttonType != newViewProps.buttonType) {
    _view.buttonType = RCTNSStringFromString(newViewProps.buttonType);
  }
  if (applyAll || oldViewProps.buttonStyle != newViewProps.buttonStyle) {
    _view.buttonStyle = RCTNSStringFromString(newViewProps.buttonStyle);
  }
  if (applyAll || oldViewProps.cornerRadius != newViewProps.cornerRadius) {
    _view.cornerRadius = newViewProps.cornerRadius;
  }

  [super updateProps:props oldProps:oldProps];
}

@end
