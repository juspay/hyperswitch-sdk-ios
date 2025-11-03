version = "0.1.0"

Pod::Spec.new do |s|
  s.name                      = 'hyperswitch-sdk-ios-authentication'
  s.version                   =  version
  s.summary                   = 'Hyperswitch Authentication SDK'
  s.description               = 'Authentication module for Hyperswitch SDK - handles 3DS authentication flows'
  s.homepage                  = 'https://hyperswitch.io/'
  s.author                    = 'Hyperswitch'
  s.license                   = { type: 'Apache-2.0', file: 'LICENSE' }
  s.platform                  = :ios
  s.ios.deployment_target     = '15.1'
  s.swift_version             = '5.0'
  s.source                    = { :git => 'https://github.com/juspay/hyperswitch-sdk-ios.git', :tag => "v#{s.version}"}
  s.module_name               = 'HyperswitchAuthentication'

  s.subspec 'core' do |core|
    core.source_files = 'hyperswitchSDK/AuthenticationModule/**/*.{m,swift,h}'
    core.dependency 'hyperswitch-sdk-ios-authentication/common'
  end

  s.subspec 'netcetera3ds' do |netcetera3ds|
    netcetera3ds.vendored_frameworks = 'frameworkgen/3ds/Frameworks/Netcetera/*.xcframework'
    netcetera3ds.dependency 'hyperswitch-sdk-ios-authentication/core'
  end

  s.subspec 'trident' do |trident|
    trident.dependency 'hyperswitch-sdk-ios-authentication/core'
    trident.dependency 'Trident3DS', '1.0.5'
  end

  s.subspec 'cardinal' do |cardinal|
    cardinal.dependency 'hyperswitch-sdk-ios-authentication/core'
    cardinal.dependency 'CardinalMobile', '3.0.0-2'
  end

  s.subspec 'common' do |common|
    common.source_files = 'hyperswitchSDK/Shared/*.{m,swift,h}'
  end

  s.default_subspec = 'core', 'common'
end
