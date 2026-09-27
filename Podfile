ENV['RCT_NEW_ARCH_ENABLED'] = '1'

require Pod::Executable.execute_command('node', ['-p',
  'require.resolve(
    "react-native/scripts/react_native_pods.rb",
    {paths: [process.argv[1]]},
  )', __dir__]).strip
require_relative 'frameworkgen/lib/frameworkgen'
require_relative 'frameworkgen/runtime_manifest'

platform :ios, min_ios_version_supported
prepare_react_native_project!
project 'Hyperswitch.xcodeproj'

REACT_NATIVE = FrameworkGen.react_native_framework
npm_of = ->(framework) { FrameworkGen.framework(framework).fetch('npm', []) }
pods_of = ->(framework) { FrameworkGen.framework(framework).fetch('pods', {}) }
on_react_native, without_react_native = FrameworkGen.frameworks.partition { |framework| FrameworkGen.react_native?(framework) }

# The full autolinking config: codegen reads it (build/generated/autolinking/autolinking.json),
# so every package's specs are generated whichever framework links the package.
AUTOLINKING = list_native_modules!($default_command)

owned = FrameworkGen.frameworks.flat_map(&npm_of)
found = AUTOLINKING[:ios_packages].map { |package| package[:name] }
unless (found - owned).empty? && (owned - found).empty?
  Pod::UI.warn "frameworkgen/products.yml and autolinking disagree: " \
               "unassigned #{found - owned}, not autolinked #{owned - found}"
  exit 1
end
unless without_react_native.flat_map(&npm_of).empty?
  Pod::UI.warn 'frameworkgen/products.yml assigns React Native packages to frameworks that do not run on React Native'
  exit 1
end

# Declares, in the current target, the pods of the given React Native packages.
def link_packages!(names)
  link_native_modules!(AUTOLINKING.merge(ios_packages: AUTOLINKING[:ios_packages].select { |p| names.include?(p[:name]) }))
end

# Declares [dependencies] (as declared in another target) in the current target.
def declare_pods!(dependencies)
  dependencies.each do |dependency|
    if dependency.external_source
      pod dependency.name, dependency.external_source.dup
    else
      pod dependency.name, *dependency.requirement.as_list
    end
  end
end

target REACT_NATIVE do
  config = link_packages!(npm_of.(REACT_NATIVE))
  declared = current_target_definition.dependencies.map(&:name)
  use_react_native!(
    :path => config[:reactNativePath],
    :hermes_enabled => true,
    :app_path => "#{Pod::Config.instance.installation_root}/.."
  )
  react_native = current_target_definition.dependencies.reject { |dependency| declared.include?(dependency.name) }

  # Each nested target declares React Native's pods as the React Native framework does, so a
  # pod they both use (React-Core with its subspecs, ...) resolves to the one pod target it
  # links rather than a variant of its own. Only the pods a nested target adds are linked into it.
  nested = lambda do |name, &block|
    target name do
      inherit! :search_paths
      declare_pods!(react_native)
      instance_eval(&block)
    end
  end

  (on_react_native - [REACT_NATIVE]).each do |framework|
    nested.(framework) do
      link_packages!(npm_of.(framework))
      pods_of.(framework).each { |name, requirement| pod name, requirement }
    end
  end

  # The demo app links the framework targets it embeds (see project.yml) and, like any React
  # Native app, the React Native plugins it autolinks.
  nested.('HyperswitchDemo') do
    link_packages!(owned - npm_of.(REACT_NATIVE))
  end
end

without_react_native.reject { |framework| pods_of.(framework).empty? }.each do |framework|
  target framework do
    pods_of.(framework).each { |name, requirement| pod name, requirement }
  end
end

post_install do |installer|
  react_native_post_install(installer, AUTOLINKING[:react_native_path], :mac_catalyst_enabled => false)

  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # Library evolution is for our frameworks' public Swift API only. CocoaPods copies the
      # frameworks' BUILD_LIBRARY_FOR_DISTRIBUTION=YES onto the pods they link.
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'NO'
      # Xcode 26.4+ cannot build fmt as C++20.
      config.build_settings['CLANG_CXX_LANGUAGE_STANDARD'] = 'c++17' if target.name == 'fmt'
    end
  end

  FrameworkGen.check_prebuilt_react_native!(installer)
  FrameworkGen.check_codegen_providers!(installer, npm_of.(REACT_NATIVE))
  FrameworkGen.write_runtime_manifest(installer, File.join(__dir__, 'build/frameworkgen/runtime.json'))
end
