# Zips every staged xcframework into build/dist with its SPM checksum (SHA-256 of the zip), and
# writes build/dist/artifacts.json. Marks build/artifacts complete, which switches Package.swift
# to these local artifacts (see Package.swift).
require 'digest'
require_relative 'frameworkgen'
include FrameworkGen

FileUtils.rm_rf(DIST)
FileUtils.mkdir_p(DIST)
FileUtils.rm_f(File.join(ARTIFACTS, '.local'))

artifacts = Dir.glob(File.join(ARTIFACTS, '*.xcframework')).sort.to_h do |xcframework|
  name = File.basename(xcframework, '.xcframework')
  zip = File.join(DIST, "#{name}.xcframework.zip")
  run!('ditto', '-c', '-k', '--keepParent', xcframework, zip)
  [name, { 'checksum' => Digest::SHA256.file(zip).hexdigest, 'bytes' => File.size(zip) }]
end

react_native = JSON.parse(File.read(File.join(IOS, '../node_modules/react-native/package.json'))).fetch('version')
File.write(File.join(DIST, 'artifacts.json'), JSON.pretty_generate(
  'version' => sdk_version,
  'reactNative' => react_native,
  'artifacts' => artifacts,
) + "\n")
File.write(File.join(ARTIFACTS, '.local'), "Complete artifacts of #{sdk_version}; Package.swift uses them instead of the release.\n")

# What a product puts in an app on its own: the device binaries and resources of everything it
# ships (Xcode leaves out headers and modules when it embeds a framework; dSYMs stay out), and
# the zips a merchant downloads. Products used together share the frameworks they have in common
# (HyperswitchShared, HyperswitchReactNative, React Native).
def app_bytes(name)
  Dir.glob(File.join(ARTIFACTS, "#{name}.xcframework/ios-arm64/*.framework/**/*"))
     .reject { |file| file.match?(%r{\.framework/(Headers|PrivateHeaders|Modules)/}) }
     .sum { |file| File.file?(file) ? File.size(file) : 0 }
end
mb = ->(bytes) { format('%.1f MB', bytes / 1_048_576.0) }
product_rows = products.keys.map do |product|
  contents = product_contents(product)
  "| #{product} | #{mb.(contents.sum { |name| app_bytes(name) })} | #{mb.(contents.sum { |name| artifacts.fetch(name)['bytes'] })} |"
end
artifact_rows = artifacts.map do |name, info|
  "| #{name} | #{mb.(app_bytes(name))} | #{mb.(info['bytes'])} |"
end
File.write(File.join(DIST, 'size-report.md'), <<~MD)
  # Hyperswitch #{sdk_version} (React Native #{react_native})

  Size on device (arm64, uncompressed) and download size (zipped xcframeworks).

  | Product, alone in an app | In the app | Download |
  |---|---|---|
  #{product_rows.join("\n")}

  | xcframework | In the app | Download |
  |---|---|---|
  #{artifact_rows.join("\n")}
MD
puts File.read(File.join(DIST, 'size-report.md'))
