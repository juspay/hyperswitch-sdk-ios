version = "0.5.4"

Pod::Spec.new do |s|
  s.name                      = 'hyperswitch-payment-methods-sdk-ios'
  s.version                   =  version
  s.summary                   = 'Hyperswitch Payment Method Session SDK'
  s.description               = 'Payment-method session SDK for Hyperswitch: card-form input widgets with their own dedicated React Native runtime, ships as a library separate from the main Hyperswitch SDK.'
  s.homepage                  = 'https://hyperswitch.io/'
  s.author                    = 'Harshit S'
  s.license                   = { type: 'Apache-2.0', file: 'LICENSE' }
  s.platform                  = :ios
  s.ios.deployment_target     = '15.1'
  s.swift_version             = '5.0'
  s.source                    = { :git => 'https://github.com/juspay/hyperswitch-sdk-ios.git', :tag => "v#{s.version}"}
  s.module_name               = 'HyperswitchPaymentMethods'

  s.source_files              = 'hyperswitchSDK/Core/HyperPaymentMethods/**/*.{m,mm,swift,h}'
  s.resources                 = ['hyperswitchSDK/Core/Resources/hyperswitch-payment-methods.bundle']

  s.dependency 'hyperswitch-sdk-ios/common'
  s.dependency 'hyperswitch-ios-hermes', '0.79.1'
end
