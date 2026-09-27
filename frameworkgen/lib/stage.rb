# stage.rb vendor:    copies the third-party xcframeworks named by products.yml `binaries` into
#                     build/vendor, where the framework targets that list them link them.
# stage.rb artifacts: completes build/artifacts, which holds our xcframeworks, with the
#                     third-party ones they need at runtime: Meta's React Native runtime
#                     byte for byte, the rest as linked (allowlisted signatures removed).
require_relative 'frameworkgen'
include FrameworkGen

# The resource bundles one of our frameworks carries in build/artifacts.
def bundles(framework)
  Dir.glob(File.join(ARTIFACTS, "#{framework}.xcframework/*/#{framework}.framework/*.bundle"))
end

case ARGV.first
when 'vendor'
  FileUtils.rm_rf(VENDOR)
  binaries = frameworks.flat_map { |name| framework(name).fetch('binaries', []) }.uniq
  binaries.each { |binary| copy_xcframework(third_party_xcframeworks.fetch(binary), VENDOR) }
when 'artifacts'
  missing = frameworks.reject { |framework| File.directory?(File.join(ARTIFACTS, "#{framework}.xcframework")) }
  abort "not built yet: #{missing.join(', ')} (run xcframework)" unless missing.empty?

  # React.xcframework is swapped in place between its Debug and Release builds by a React Native
  # script phase; the archive must have left the Release one there.
  last = Dir.glob(File.join(IOS, 'Pods/React-Core-prebuilt/.last_build_configuration')).first
  abort "React.xcframework is not the Release build (#{last && File.read(last).strip})" unless last && File.read(last).strip == 'Release'

  frameworks.map { |framework| dynamic_dependencies(framework) }.reduce(:merge).each_value do |source|
    copy_xcframework(source, ARTIFACTS)
  end

  # A framework copies the resource bundles of every pod it can see, so it repeats those of the
  # frameworks it builds on (React's privacy bundles): keep each in the framework that links it.
  frameworks.each do |framework|
    inherited = (closure(framework) - [framework]).flat_map { |dependency| bundles(dependency).map { |path| File.basename(path) } }
    bundles(framework).each { |bundle| FileUtils.rm_rf(bundle) if inherited.include?(File.basename(bundle)) }
  end
  puts "staged: #{Dir.children(ARTIFACTS).sort.join(', ')}"
else
  abort 'usage: stage.rb vendor|artifacts'
end
