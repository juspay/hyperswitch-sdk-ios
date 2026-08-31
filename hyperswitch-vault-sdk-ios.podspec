version = "0.1.0"

Pod::Spec.new do |s|
  s.name                      = 'hyperswitch-vault-sdk-ios'
  s.version                   = version
  s.summary                   = 'Hyperswitch Vault SDK'
  s.description               = 'Hyperswitch Vault SDK - secure fields + tokenization for iOS, drop-in compatible with VGS Collect'
  s.homepage                  = 'https://hyperswitch.io/'
  s.author                    = 'Harshit S'
  s.license                   = { type: 'Apache-2.0', file: 'LICENSE' }
  s.platform                  = :ios
  s.ios.deployment_target     = '15.1'
  s.swift_version             = '5.0'
  s.source                    = { :git => 'https://github.com/juspay/hyperswitch-sdk-ios.git', :tag => "v#{s.version}"}
  s.module_name               = 'HyperswitchVault'

  s.subspec 'core' do |core|
    core.source_files = 'hyperswitchVault/**/*.{m,mm,h,swift}'
    core.resources = ['hyperswitchVault/Core/Resources/hyperswitch-vault.bundle']
    # Same vendored React Native stack used by hyperswitch-sdk-ios/core.
    core.vendored_frameworks = 'frameworkgen/Frameworks/Core/*.xcframework'
    core.dependency 'hyperswitch-ios-hermes', '0.79.1'
  end

  s.default_subspec = 'core'
end
