version = "0.5.4"

# JavaScript written by `yarn bundle:ios` (scripts/bundle.mjs): one entry bundle per React
# host and `hyperswitch.<chunk>.chunk.bundle` files the hosts share. Each subspec ships the
# files its feature loads; see rspack.config.mjs for what each chunk holds.
resources_dir = 'hyperswitchSDK/Core/Resources'
chunk = ->(name) { "#{resources_dir}/hyperswitch.#{name}.chunk.bundle" }
# The chunk of an optional package exists only when the package was installed when the
# JavaScript was bundled; an absent one is left out rather than failing the spec.
built_chunk = ->(name) { Dir.glob(chunk.(name), base: __dir__) }

Pod::Spec.new do |s|
  s.name                      = 'hyperswitch-sdk-ios'
  s.version                   =  version
  s.summary                   = 'Hyperswitch SDK'
  s.description               = 'Core of Hyperswitch SDK an open-source payments switch'
  s.homepage                  = 'https://hyperswitch.io/'
  s.author                    = 'Harshit S'
  s.license                   = { type: 'Apache-2.0', file: 'LICENSE' }
  s.platform                  = :ios
  s.ios.deployment_target     = '15.1'
  s.swift_version             = '5.0'
  s.source                    = { :git => 'https://github.com/juspay/hyperswitch-sdk-ios.git', :tag => "v#{s.version}"}
  s.module_name               = 'Hyperswitch'

  s.subspec 'core' do |core|
    core.source_files = 'hyperswitchSDK/Core/**/*.{m,swift,h}', 'hyperswitchSDK/Core/NativeModule/HyperReactNativeFactory.mm'
    # The payments entry, the chunks every host needs before it starts (react-native,
    # vendors), and the ones the payments host loads on demand, with their images.
    core.resources = [
      "#{resources_dir}/HyperOTA.plist",
      "#{resources_dir}/hyperswitch.bundle",
      chunk.('react-native'),
      chunk.('vendors'),
      chunk.('optional-shared'),
      chunk.('location-data'),
      chunk.('vault'),
      chunk.('vgs'),
      "#{resources_dir}/assets",
    ]
    # The chunk files are loaded by Re.Pack's ScriptManager native module
    # (@callstack/repack). Like every autolinked module, it is built into
    # frameworkgen/Frameworks/Core (callstack_repack, JWTDecode, SwiftyRSA).
    core.vendored_frameworks = 'frameworkgen/Frameworks/Core/*.xcframework'
    core.dependency 'hyperswitch-sdk-ios/common'
    core.dependency 'hyperswitch-ios-hermes', '0.79.1'
  end

  s.subspec 'sentry' do |sentry|
    sentry.vendored_frameworks = 'frameworkgen/Frameworks/Sentry/*.xcframework'
    sentry.resources = [chunk.('sentry')]
    sentry.dependency 'hyperswitch-sdk-ios/core'
  end

  s.subspec 'scancard' do |scancard|
    scancard.source_files = 'frameworkgen/scanCard/Source/**/*.{m,swift,h}'
    scancard.vendored_frameworks = 'frameworkgen/scanCard/Frameworks/*.xcframework'
    scancard.resources = built_chunk.('scancard')
    scancard.dependency 'hyperswitch-sdk-ios/core'
  end

  s.subspec 'netcetera3ds' do |netcetera3ds|
    netcetera3ds.source_files = 'frameworkgen/3ds/Source/**/*.{m,swift,h}'
    netcetera3ds.vendored_frameworks = 'frameworkgen/3ds/Frameworks/*.xcframework'
    netcetera3ds.resources = built_chunk.('netcetera-3ds')
    netcetera3ds.dependency 'hyperswitch-sdk-ios/core'
  end

  s.subspec 'airborne' do |airborne|
    airborne.dependency 'HyperOTA', '0.0.8'
    airborne.dependency 'hyperswitch-sdk-ios/core'
  end

  s.subspec 'paypal' do |paypal|
    paypal.source_files = 'frameworkgen/paypal/Source/**/*.{h,m,mm,swift}'
    paypal.dependency "PayPal/CardPayments", "~> 2.0"
    paypal.dependency "PayPal/PaymentButtons", "~> 2.0"
    paypal.dependency "PayPal/PayPalWebPayments", "~> 2.0"
    paypal.resources = built_chunk.('paypal')
    paypal.dependency 'hyperswitch-sdk-ios/core'
  end

  # The Payment Methods SDK: its own React host and entry bundle, over the chunks core ships.
  s.subspec 'paymentmethods' do |paymentmethods|
    paymentmethods.source_files = 'hyperswitchSDK/PaymentMethods/**/*.{m,mm,swift,h}'
    paymentmethods.resources = ["#{resources_dir}/hyperswitch-payment-methods.bundle"]
    paymentmethods.dependency 'hyperswitch-sdk-ios/core'
  end

  s.subspec 'common' do |common|
    common.source_files = 'hyperswitchSDK/Shared/**/*.{m,swift,h}'
  end

  s.default_subspec = 'core', 'common'
end
