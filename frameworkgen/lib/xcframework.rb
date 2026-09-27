# One xcframework per framework in products.yml, from the device and simulator archives.
# `-archive … -framework …` also packs each slice's dSYM.
require_relative 'frameworkgen'
include FrameworkGen

FileUtils.rm_rf(ARTIFACTS)
FileUtils.mkdir_p(ARTIFACTS)
frameworks.each do |framework|
  command = ['xcodebuild', '-create-xcframework']
  PLATFORMS.each_key do |sdk|
    archive = File.join(ARCHIVES, "#{sdk}.xcarchive")
    abort "#{archive} is missing: run archive first" unless File.directory?(archive)
    command += ['-archive', archive, '-framework', "#{framework}.framework"]
  end
  command += ['-output', File.join(ARTIFACTS, "#{framework}.xcframework")]
  run!(*command)
end
