Pod::Spec.new do |s|
  s.name                      = 'HyperswitchScanCard'
  s.version                   = '0.1.0'
  s.summary                   = 'Hyperswitch SDK'
  s.description               = 'Core of Hyperswitch SDK an open-source payments switch'
  s.homepage                  = 'https://hyperswitch.io/'
  s.author                    = 'Harshit S'
  s.license                   = { type: 'Apache-2.0', file: 'LICENSE' }
  s.platform                  = :ios
  s.ios.deployment_target     = '13.4'
  s.source                    = { :path => "." }
  s.module_name               = 'Hyperswitch'

  s.vendored_frameworks = 'Frameworks/HyperswitchScancard.xcframework'
end