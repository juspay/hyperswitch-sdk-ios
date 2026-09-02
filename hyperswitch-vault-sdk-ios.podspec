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
    # Public so the pod's Swift sources can see VaultDependencyProvider() and
    # wire it on the factory delegate.
    core.public_header_files = 'hyperswitchVault/Core/NativeModule/VaultDependencyProvider.h'
    core.resources = ['hyperswitchVault/Core/Resources/hyperswitch-vault.bundle']
    #
    # Same React Native distribution the main HyperswitchSDK workspace uses:
    # the official RN 0.86 pods (React-Core resolving to React-Core-prebuilt
    # + the prebuilt hermes binary that the consuming app links; see the
    # demo target in Podfile). The previous layout vendored a standalone RN
    # 0.79 xcframework stack (frameworkgen/Frameworks/Core) — one RN version
    # per SDK in the same app — removed.
    #
    # Unpinned on purpose: the vault rides on whatever React version the
    # consuming app's RN workspace resolves. RNSVG is the one native field
    # dependency (card brand icons). HyperVaultModule subclasses the codegen
    # NativeHyperVaultModuleSpecBase (typed onVaultTokenise EventEmitter — the
    # vault twin of the main SDK's HyperModule.triggerWidgetAction channel),
    # so the pod links the workspace's generated ReactCodegen pod.
    core.dependency 'React-Core'
    core.dependency 'React-RCTAppDelegate'
    core.dependency 'ReactAppDependencyProvider'
    core.dependency 'ReactCodegen'
    core.dependency 'RNSVG'
  end

  s.default_subspec = 'core'
end
