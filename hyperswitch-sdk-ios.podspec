version = "0.1.4"

Pod::Spec.new do |s|
  s.name                      = 'hyperswitch-sdk-ios'
  s.version                   =  version
  s.summary                   = 'Hyperswitch SDK'
  s.description               = 'Core of Hyperswitch SDK an open-source payments switch'
  s.homepage                  = 'https://hyperswitch.io/'
  s.author                    = 'Harshit S'
  s.license                   = { type: 'Apache-2.0', file: 'LICENSE' }
  s.platform                  = :ios
  s.ios.deployment_target     = '13.0'
  s.source                    = { :git => 'https://github.com/juspay/hyperswitch-sdk-ios.git', :tag => "v#{s.version}"}
  s.module_name               = 'Hyperswitch'

  s.subspec 'core' do |core|
    core.source_files = 'hyperswitch/hyperWrapper/**/*.{m,swift,h}'
    core.resources = ['hyperswitch/hyperWrapper/Resources/CodePush.plist', 'hyperswitch/hyperWrapper/Resources/hyperswitch.bundle']
    core.vendored_frameworks = 'frameworkgen/Frameworks/Core/*.xcframework'
  end

  s.subspec 'sentry' do |sentry|
    sentry.vendored_frameworks = 'frameworkgen/Frameworks/Sentry/*.xcframework'
    sentry.dependency 'hyperswitch-sdk-ios/core'
  end

  s.subspec 'scancard' do |scancard|
    scancard.vendored_frameworks = 'frameworkgen/Frameworks/ScanCard/*.xcframework'
    scancard.dependency 'hyperswitch-sdk-ios/core'
  end

  s.subspec 'netcetera3ds' do |netcetera3ds|
    netcetera3ds.source_files = '3ds/Source/**/*.{m,swift,h}'
    netcetera3ds.vendored_frameworks = '3ds/Frameworks/*.xcframework'
    netcetera3ds.dependency 'hyperswitch-sdk-ios/core'
  end

  s.default_subspec = 'core'
  s.dependency 'Hyperswitch-Hermes'
  s.dependency 'KlarnaMobileSDK'
end
