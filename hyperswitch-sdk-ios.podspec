version = "1.0.0"

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
  s.module_name               = 'HyperswitchCore'

  s.subspec 'core' do |core|
    s.source_files = 'hyperswitch/hyperWrapper/**/*.{m,swift,h}'
    s.resources = ["hyperswitch/hyperWrapper/Resources/Codepush.plist", "hyperswitch/hyperWrapper/Resources/hyperswitch.bundle"]
    s.vendored_frameworks = 'frameworkgen/Frameworks/Core/*.xcframework'
  end

  s.subspec 'sentry' do |sentry|
    sentry.vendored_frameworks = 'frameworkgen/Frameworks/Sentry/*.xcframework'
  end

  s.subspec 'scan-card' do |scancard|
    scancard.vendored_frameworks = 'frameworkgen/Frameworks/ScanCard/*.xcframework'
  end

  s.default_subspec = 'core'
  s.dependency 'Hyperswitch-Hermes'
  s.dependency 'KlarnaMobileSDK'
end
