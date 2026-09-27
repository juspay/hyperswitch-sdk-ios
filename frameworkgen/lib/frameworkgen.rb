# Shared by the frameworkgen steps and the Podfile: where things are, and the two inputs every
# step reads, products.yml (what ships) and build/frameworkgen/runtime.json (what CocoaPods linked).
require 'json'
require 'yaml'
require 'fileutils'
require 'open3'

module FrameworkGen
  IOS = File.expand_path('../..', __dir__)
  BUILD = File.join(IOS, 'build')
  ARCHIVES = File.join(BUILD, 'archives')
  ARTIFACTS = File.join(BUILD, 'artifacts') # every xcframework a release ships
  DIST = File.join(BUILD, 'dist')           # the zips, checksums and reports uploaded to a release
  VENDOR = File.join(BUILD, 'vendor')       # third-party xcframeworks linked through `binaries`
  PLATFORMS = {
    'iphoneos' => 'generic/platform=iOS',
    'iphonesimulator' => 'generic/platform=iOS Simulator',
  }.freeze

  module_function

  def products_config
    @products_config ||= YAML.load_file(File.join(IOS, 'frameworkgen/products.yml'))
  end

  # The frameworks we build.
  def frameworks
    products_config.fetch('frameworks').keys
  end

  # A framework's entry in products.yml.
  def framework(name)
    products_config.fetch('frameworks').fetch(name) || {}
  end

  def products
    products_config.fetch('products')
  end

  def signature_strip_allowlist
    products_config.fetch('signature_strip_allowlist', [])
  end

  # The one framework that holds React Native.
  def react_native_framework
    names = frameworks.select { |name| framework(name)['react_native'] }
    abort "products.yml: one framework must set react_native, not #{names.size}" unless names.size == 1
    names.first
  end

  # [name] and every framework it builds on, dependencies first.
  def closure(name)
    framework(name).fetch('depends', []).flat_map { |dependency| closure(dependency) }.push(name).uniq
  end

  def react_native?(name)
    closure(name).include?(react_native_framework)
  end

  # Our frameworks a product ships: its own and those they build on.
  def product_frameworks(product)
    products.fetch(product).flat_map { |name| closure(name) }.uniq
  end

  # Every xcframework a product ships: its frameworks, then the third-party ones they link.
  def product_contents(product)
    ours = product_frameworks(product)
    ours + (ours.flat_map { |name| dynamic_dependencies(name).keys }.uniq.sort - ours)
  end

  def runtime
    path = File.join(BUILD, 'frameworkgen/runtime.json')
    abort "#{path} is missing: run `frameworkgen/build.sh bootstrap`" unless File.exist?(path)
    @runtime ||= JSON.parse(File.read(path)).fetch('targets')
  end

  # Every third-party dynamic xcframework the pods bring (name => source path).
  def third_party_xcframeworks
    runtime.values.flat_map { |target| target.fetch('dynamic_xcframeworks') }
           .to_h { |entry| [entry['name'], File.expand_path(entry['path'], IOS)] }
  end

  # Third-party dynamic xcframeworks (name => source path) [name] links at runtime: those its
  # pods bring and its `binaries`, which some other framework's pods bring.
  def dynamic_dependencies(name)
    from_pods = runtime.fetch(name, {}).fetch('dynamic_xcframeworks', [])
                       .to_h { |entry| [entry['name'], File.expand_path(entry['path'], IOS)] }
    binaries = framework(name).fetch('binaries', []).to_h do |binary|
      [binary, third_party_xcframeworks.fetch(binary) { abort "#{name}: no pod brings #{binary}.xcframework" }]
    end
    from_pods.merge(binaries)
  end

  # The version all our frameworks carry, from the SDK's own constant.
  def sdk_version
    File.read(File.join(IOS, 'hyperswitchSDK/Shared/Version.swift'))[/static let current = "([^"]+)"/, 1] or
      abort 'SDKVersion.current not found in hyperswitchSDK/Shared/Version.swift'
  end

  def run!(*command, chdir: IOS)
    puts "$ #{command.join(' ')}"
    system(*command, chdir: chdir) or abort "failed: #{command.join(' ')}"
  end

  def capture!(*command)
    out, status = Open3.capture2e(*command)
    abort "failed: #{command.join(' ')}\n#{out}" unless status.success?
    out
  end

  # Copies an xcframework as is (keeping its code signature), or with the signature removed
  # when it is allowlisted in products.yml.
  def copy_xcframework(source, destination_dir)
    name = File.basename(source)
    destination = File.join(destination_dir, name)
    FileUtils.rm_rf(destination)
    FileUtils.mkdir_p(destination_dir)
    run!('ditto', source, destination)
    if signature_strip_allowlist.include?(File.basename(name, '.xcframework'))
      FileUtils.rm_rf(File.join(destination, '_CodeSignature'))
      Dir.glob(File.join(destination, '*/*.framework')).each do |framework|
        run!('codesign', '--remove-signature', framework)
      end
    end
    destination
  end
end
