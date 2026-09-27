# Checks the staged artifacts (build/artifacts) before they are packaged. Each failure names
# the artifact and what is wrong; any failure fails the step.
require_relative 'frameworkgen'
include FrameworkGen

FAILURES = []
def fail!(message)
  FAILURES << message
end

xcframeworks = Dir.glob(File.join(ARTIFACTS, '*.xcframework')).to_h { |path| [File.basename(path, '.xcframework'), path] }
ours = frameworks

IOS_SLICES = %w[ios-arm64 ios-arm64_x86_64-simulator].freeze

# The framework binary of each iOS slice of an xcframework: { slice => path }. (Meta's also
# carry Mac Catalyst, tvOS and visionOS slices, which iOS apps never use.)
def slices(xcframework)
  IOS_SLICES.to_h { |slice| [slice, Dir.glob(File.join(xcframework, slice, '*.framework')).first] }
            .compact.transform_values { |framework| File.join(framework, File.basename(framework, '.framework')) }
end

def macho_lines(*command)
  capture!(*command).lines.map(&:strip)
end

# What each product ships: its frameworks, those they build on, the third-party ones they link.
product_sets = products.keys.to_h { |product| [product, product_contents(product)] }

xcframeworks.each do |name, path|
  fail!("#{name}: no device or simulator slice") unless IOS_SLICES.all? { |slice| slices(path).key?(slice) }
end

# 1. No Objective-C class is defined by two binaries: the runtime would pick one at random.
IOS_SLICES.each do |slice|
  owners = Hash.new { |hash, key| hash[key] = [] }
  xcframeworks.each do |name, path|
    binary = slices(path)[slice] or next
    macho_lines('nm', '-gU', '-arch', 'arm64', binary).each do |line|
      klass = line[/_OBJC_CLASS_\$_(\S+)/, 1] or next
      owners[klass] << name unless klass.start_with?('PodsDummy_')
    end
  end
  owners.each { |klass, names| fail!("#{slice}: class #{klass} is defined in #{names.uniq.join(' and ')}") if names.uniq.size > 1 }
end

# 2. The Swift interfaces merchants compile against (public, and private, which a compiler
#    prefers when present) import only system modules and our own frameworks, and name nothing
#    internal: merchants compile without React Native or any vendor SDK. Only a module of our
#    own Swift package reads the package interface.
allowed_imports = ours + %w[Foundation Swift UIKit SwiftUI PassKit WebKit Combine _Concurrency _StringProcessing _SwiftConcurrencyShims]
ours.each do |framework|
  Dir.glob(File.join(xcframeworks.fetch(framework), '*/*.framework/Modules/*.swiftmodule/*.swiftinterface')).each do |interface|
    next if interface.end_with?('.package.swiftinterface')

    text = File.read(interface)
    aliases = text[/swift-module-flags:.*$/].to_s.scan(/-module-alias (\S+)=(\S+)/).to_h
    text.scan(/^(?:@\w+ )*import (\S+)$/).flatten.map { |mod| aliases.fetch(mod, mod) }.uniq.each do |mod|
      fail!("#{framework}: public interface imports #{mod}") unless allowed_imports.include?(mod)
    end
    fail!("#{framework}: public interface mentions @_spi") if text.include?('@_spi')
    fail!("#{framework}: public interface mentions React types") if text.match?(/\bRCT[A-Z]/)
  end
end

# 3. Every binary loads only what its product ships, by @rpath, and system libraries.
xcframeworks.each do |name, path|
  containing = product_sets.select { |_, set| set.include?(name) }.values
  next if containing.empty? && !ours.include?(name)

  slices(path).each do |slice, binary|
    macho_lines('otool', '-L', '-arch', 'arm64', binary).each do |line|
      next if line.end_with?(':') # the binary's own header line

      dylib = line.split(' (').first
      # The OS provides the Swift runtime that older binaries (ThreeDS_SDK) load by @rpath.
      next if dylib.start_with?('/System/', '/usr/lib/', '@rpath/libswift')

      unless dylib.start_with?('@rpath/')
        fail!("#{name} (#{slice}) loads #{dylib} by an absolute path")
        next
      end
      dependency = dylib[%r{@rpath/([^/]+)\.framework/}, 1]
      next if dependency == name

      missing = containing.reject { |set| set.include?(dependency) }
      fail!("#{name} (#{slice}) loads #{dependency}, which a product shipping it does not include") unless missing.empty?
    end
  end
end

# 4. Resources: each JS bundle sits in the framework that loads it; every framework we build
#    carries a privacy manifest (React Native only aggregates them into apps).
{
  'Hyperswitch' => 'hyperswitch.bundle',
  'HyperswitchPaymentMethods' => 'hyperswitch-payment-methods.bundle',
  'HyperswitchPaymentMethodManagement' => 'hyperswitch-payment-method-management.bundle',
  'HyperswitchAirbornePlugin' => 'HyperOTA.plist',
}.each do |framework, resource|
  slices(xcframeworks.fetch(framework)).each do |slice, binary|
    fail!("#{framework} (#{slice}) lacks #{resource}") unless File.exist?(File.join(File.dirname(binary), resource))
  end
end
ours.each do |framework|
  slices(xcframeworks.fetch(framework)).each do |slice, binary|
    fail!("#{framework} (#{slice}) lacks PrivacyInfo.xcprivacy") unless File.exist?(File.join(File.dirname(binary), 'PrivacyInfo.xcprivacy'))
  end
end

# Sentry is linked into its plugin statically; the manifest copied into the repo must match the
# Sentry build RNSentry downloaded.
sentry = Dir.glob(File.expand_path('~/Library/Caches/sentry-react-native/xcframeworks/*/Sentry.xcframework/ios-arm64*/Sentry.framework/PrivacyInfo.xcprivacy')).max
copied = File.join(IOS, 'hyperswitchSDK/Plugins/Sentry/PrivacyInfo.xcprivacy')
if sentry && File.read(sentry) != File.read(copied)
  fail!("hyperswitchSDK/Plugins/Sentry/PrivacyInfo.xcprivacy differs from #{sentry}; copy it over")
end

# 5. A third-party xcframework that comes signed (Meta's React and ReactNativeDependencies)
#    still verifies: it was copied byte for byte. Allowlisted ones had theirs removed.
(xcframeworks.keys - ours).each do |name|
  next unless File.directory?(File.join(xcframeworks[name], '_CodeSignature'))

  _, status = Open3.capture2e('codesign', '--verify', '--strict', xcframeworks[name])
  fail!("#{name}.xcframework: code signature does not verify") unless status.success?
end

# 6. Every framework we build carries the SDK's version (SDKVersion.current).
ours.each do |framework|
  slices(xcframeworks.fetch(framework)).each do |slice, binary|
    version = capture!('/usr/libexec/PlistBuddy', '-c', 'Print :CFBundleShortVersionString', File.join(File.dirname(binary), 'Info.plist')).strip
    fail!("#{framework} (#{slice}) is version #{version}, not #{sdk_version}") unless version == sdk_version
  end
end

if FAILURES.empty?
  puts "guards: #{xcframeworks.size} artifacts OK"
else
  FAILURES.each { |failure| warn "guard: #{failure}" }
  abort "guards: #{FAILURES.size} failure(s)"
end
