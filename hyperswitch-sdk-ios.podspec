version = "0.2.7"

Pod::Spec.new do |s|
  s.name                      = 'hyperswitch-sdk-ios'
  s.version                   =  version
  s.summary                   = 'Hyperswitch SDK'
  s.description               = 'Core of Hyperswitch SDK an open-source payments switch'
  s.homepage                  = 'https://hyperswitch.io/'
  s.author                    = 'Harshit S'
  s.license                   = { type: 'Apache-2.0', file: 'LICENSE' }
  s.platform                  = :ios
  s.ios.deployment_target     = '13.4'
  s.swift_version             = '5.0'
  s.source                    = { :git => 'https://github.com/juspay/hyperswitch-sdk-ios.git', :tag => "v#{s.version}"}
  s.module_name               = 'Hyperswitch'

  s.subspec 'core' do |core|
    core.source_files = 'hyperswitchSDK/Core/**/*.{m,swift,h}'
    core.resources = ['hyperswitchSDK/Core/Resources/HyperOTA.plist', 'hyperswitchSDK/Core/Resources/hyperswitch.bundle']
    core.vendored_frameworks = 'frameworkgen/Frameworks/Core/*.xcframework'
    core.dependency 'hyperswitch-sdk-ios/common'
    core.dependency 'hyperswitch-ios-hermes', '0.79.1'
    core.dependency 'KlarnaMobileSDK'
    core.dependency 'HyperOTA', '0.0.4'
  end

  s.subspec 'sentry' do |sentry|
    sentry.vendored_frameworks = 'frameworkgen/Frameworks/Sentry/*.xcframework'
    sentry.dependency 'hyperswitch-sdk-ios/core'
  end

  s.subspec 'scancard' do |scancard|
    scancard.source_files = 'frameworkgen/scanCard/Source/**/*.{m,swift,h}'
    scancard.vendored_frameworks = 'frameworkgen/scanCard/Frameworks/*.xcframework'
    scancard.dependency 'hyperswitch-sdk-ios/core'
  end

  s.subspec 'netcetera3ds' do |netcetera3ds|
    netcetera3ds.source_files = 'frameworkgen/3ds/Source/**/*.{m,swift,h}'
    netcetera3ds.vendored_frameworks = 'frameworkgen/3ds/Frameworks/*.xcframework'
    netcetera3ds.dependency 'hyperswitch-sdk-ios/core'
  end

  s.subspec 'lite' do |lite|
    lite.source_files = 'hyperswitchSDK/CoreLite/*.{m,swift,h}'
    lite.dependency 'hyperswitch-sdk-ios/common'
  end

  s.subspec 'lite+scancard' do |lite_scancard|
    lite_scancard.vendored_frameworks = 'frameworkgen/scanCard/Frameworks/*.xcframework'
    lite_scancard.dependency 'hyperswitch-sdk-ios/lite'
  end

  s.subspec 'common' do |common|
    common.source_files = 'hyperswitchSDK/Shared/*.{m,swift,h}'
  end

  s.default_subspec = 'core', 'common'
end
