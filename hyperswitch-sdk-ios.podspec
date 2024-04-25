Pod::Spec.new do |s|
  s.name                      = 'hyperswitch-sdk-ios'
  s.version                   = '1.0.0'
  s.summary                   = 'Hyperswitch SDK'
  s.description               = 'Core of Hyperswitch SDK an open-source payments switch'
  s.homepage                  = 'https://hyperswitch.io/'
  s.author                    = 'Harshit S'
  s.license                   = { type: 'Apache-2.0', file: 'LICENSE' }
  s.platforms                 = { ios: '13.0' }
  s.source                    = { :git => 'https://github.com/juspay/hyperswitch-sdk-ios.git', :tag => "v#{s.version}"}
  s.source_files              = "hyperswitch/hyperWrapper/**/*.{m,swift,h}"
  s.resources                 = "hyperswitch/hyperWrapper/Resources/hyperswitch.bundle"
  s.vendored_frameworks       = 'frameworkgen/Frameworks/**/*.xcframework'
  s.module_name               = 'Hyperswitch'

  s.dependency 'Hyperswitch-Hermes'
end
