require 'json'
require 'fileutils'

module FrameworkGen
  def self.check_prebuilt_react_native!(installer)
    return if installer.pod_targets.any? { |target| target.name == 'React-Core-prebuilt' }

    Pod::UI.warn 'React Native is not using its prebuilt React.xcframework (React-Core-prebuilt). ' \
                 'Check RCT_USE_PREBUILT_RNCORE / RCT_USE_RN_DEP and network access to Maven.'
    exit 1
  end

  # Codegen compiles one list of every package's Fabric components (RCTThirdPartyComponentsProvider)
  # and TurboModule providers (RCTModuleProviders), the app's own included, into the framework
  # that holds React Native. Both name classes by string: a component class that is not linked
  # crashes the app at launch, a module provider logs an error. So every entry must come from a
  # package [linked] into that framework. A package of any other framework registers its
  # components itself, where they are linked (the payments SDK's ApplePayButtonComponentView,
  # the PayPal plugin's PaypalButtonComponentView), and sets codegenConfig.ios.componentProvider
  # to {}. This reads what codegen wrote, so it holds whatever codegen reads to write it.
  def self.check_codegen_providers!(installer, linked)
    generated = File.join(installer.sandbox.root.dirname.to_s, 'build/generated/ios')
    offending = %w[RCTThirdPartyComponentsProvider.mm RCTModuleProviders.mm].flat_map do |name|
      file = Dir.glob(File.join(generated, '**', name)).first
      unless file
        Pod::UI.warn "Codegen's #{name} is not under #{generated}; update FrameworkGen.check_codegen_providers!."
        exit 1
      end
      File.readlines(file).grep(/^\s*@"[^"]+"\s*:/).filter_map do |entry|
        entry.strip unless linked.include?(entry[%r{//\s*(\S+)\s*$}, 1])
      end
    end
    return if offending.empty?

    Pod::UI.warn "Codegen lists classes that the React Native framework does not link:\n  " \
                 "#{offending.join("\n  ")}\nRegister these components from the package itself " \
                 '(+load, [RCTComponentViewFactory registerComponentViewClass:]) and set its ' \
                 'codegenConfig.ios.componentProvider to {}; see frameworkgen/runtime_manifest.rb.'
    exit 1
  end

  # Writes, for each target: the dynamic xcframeworks it links (these ship next to it or are
  # embedded by the app) and the pods it links statically.
  def self.write_runtime_manifest(installer, path)
    root = installer.sandbox.root.dirname
    targets = installer.aggregate_targets.to_h do |aggregate|
      xcframeworks = aggregate.xcframeworks_by_config.fetch('Release', [])
      dynamic = xcframeworks.select { |xcframework| xcframework.build_type.dynamic_framework? }
      linked = aggregate.build_settings('Release').pod_targets_to_link
      [aggregate.target_definition.name, {
        'dynamic_xcframeworks' => dynamic.map { |xcframework|
          { 'name' => xcframework.name, 'path' => xcframework.path.relative_path_from(root).to_s }
        }.uniq.sort_by { |entry| entry['name'] },
        # Pods that compile into a static library (header-only and vendored-binary pods do not).
        'static_pods' => linked.select { |pod| pod.should_build? && !pod.build_as_dynamic? }.map(&:name).sort,
      }]
    end
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, JSON.pretty_generate('targets' => targets) + "\n")
  end
end
