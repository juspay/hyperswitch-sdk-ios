# Release archives of the HyperswitchSDK scheme (every framework in products.yml), one per
# platform. Our frameworks land in <archive>/Products/Library/Frameworks with their dSYMs.
require_relative 'frameworkgen'
include FrameworkGen

FileUtils.mkdir_p(File.join(BUILD, 'frameworkgen', 'logs'))
PLATFORMS.each do |sdk, destination|
  archive = File.join(ARCHIVES, "#{sdk}.xcarchive")
  log = File.join(BUILD, 'frameworkgen', 'logs', "archive-#{sdk}.log")
  FileUtils.rm_rf(archive)
  command = [
    'xcodebuild', 'archive',
    '-workspace', 'Hyperswitch.xcworkspace',
    '-scheme', 'HyperswitchSDK',
    '-configuration', 'Release',
    '-destination', destination,
    '-archivePath', archive,
    '-derivedDataPath', File.join(BUILD, 'dd-release'),
    'SKIP_INSTALL=NO',
    'CODE_SIGNING_ALLOWED=NO',
    "HYPERSWITCH_VERSION=#{sdk_version}",
  ]
  puts "$ #{command.join(' ')} > #{log}"
  next if system(*command, chdir: IOS, out: log, err: [:child, :out])

  system('grep', '-E', 'error:|BUILD FAILED|ARCHIVE FAILED', log)
  abort "archive for #{sdk} failed, see #{log}"
end
