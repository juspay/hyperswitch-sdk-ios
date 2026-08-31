require Pod::Executable.execute_command('node', ['-p',
  'require.resolve(
    "react-native/scripts/react_native_pods.rb",
    {paths: [process.argv[1]]},
  )', __dir__]).strip

platform :ios, min_ios_version_supported
prepare_react_native_project!

linkage = ENV['USE_FRAMEWORKS']
if linkage != nil
  Pod::UI.puts "Configuring Pod with #{linkage}ally linked Frameworks".green
  use_frameworks! :linkage => linkage.to_sym
end

target 'hyperswitch' do
  config = use_native_modules!
  # pod 'hyperswitch-sdk-ios-authentication/trident', :path => '.'
  pod 'HyperOTA', '0.0.8'
  use_react_native!(
    :path => config[:reactNativePath],
    :hermes_enabled => true,
    :app_path => "#{Pod::Config.instance.installation_root}/.."
  )

  post_install do |installer|
    react_native_post_install(
      installer,
      config[:reactNativePath],
      :mac_catalyst_enabled => false,
      # :ccache_enabled => true
    )
    
    # Fix for Xcode 26.4 build error
    installer.pods_project.targets.each do |target|
      if target.name == 'fmt'
        target.build_configurations.each do |config|
          config.build_settings['CLANG_CXX_LANGUAGE_STANDARD'] = 'c++17'
        end
      end
    end

    # The vault SDK is self-contained: it vendors the complete React Native 0.79
    # stack as xcframeworks (frameworkgen/Frameworks/Core).
    #
    # react_native_post_install (via configure_aggregate_xcconfig) unconditionally
    # appends the React-Core-prebuilt (RN 0.86) VFS overlay to EVERY pod and
    # aggregate target xcconfig. Clang then sees two different RCTDependencyProvider
    # definitions when building the vault SDK and fails with:
    #   error: 'RCTDependencyProvider' has different definitions in different modules
    # Strip the overlay back out of the vault targets' xcconfigs. Also drop the
    # global "${PODS_ROOT}/Headers/Public" include from their header search paths:
    # the vault targets' sources resolve <React-RCTAppDelegate/...> through that
    # directory and would otherwise textually pull the RN 0.86 source-pod headers
    # of the main 'hyperswitch' app into the vendored 0.79 module graph.
    # For the same reason the vault SDK pod target must NOT use header maps:
    # Pods.xcodeproj also contains the main app's React Native 0.86 pods, and
    # Xcode's project header map resolves e.g. RCTDependencyProvider.h to those
    # 0.86 headers, colliding with the vendored 0.79 module of the same name.
    # The vault sources only use framework module imports (-F), so header maps
    # are not needed for them.
    installer.pods_project.targets.each do |target|
      if target.name == 'hyperswitch-vault-sdk-ios'
        target.build_configurations.each do |config|
          config.build_settings['USE_HEADERMAP'] = 'NO'
        end
      end
    end

    vault_configs = ['Pods-hyperswitchVaultDemo', 'hyperswitch-vault-sdk-ios']
    installer.generated_projects.each do |project|
      project.targets.each do |target|
        next unless vault_configs.include?(target.name)
        target.build_configurations.each do |bc|
          next if bc.base_configuration_reference.nil?
          path = bc.base_configuration_reference.real_path
          content = File.read(path)
          stripped = content
            .gsub(/\s*-Xcc\s+-ivfsoverlay\s+-Xcc\s+"[^"]*React-Core-prebuilt\/React-VFS\.yaml"/, '')
            .gsub(/\s*-ivfsoverlay\s+"[^"]*React-Core-prebuilt\/React-VFS\.yaml"/, '')
            .gsub(/\s*"\$\{PODS_ROOT\}\/Headers\/Public(\/(?!hyperswitch-ios-hermes)[^"]*)*"(?=\s|$)/, '')
          File.write(path, stripped) if stripped != content
        end
      end
    end
  end
end

target 'hyperswitchAppClip' do  ## for testing attach local pods ##
  use_frameworks!
  pod 'HyperswitchScanCard', :path =>  "frameworkgen/scanCard"
end

target 'hyperswitchVaultDemo' do  ## native demo app for the vault SDK (ios equivalent of android/vault-demo) ##
  use_frameworks!
  pod 'hyperswitch-vault-sdk-ios', :path => '.'
end