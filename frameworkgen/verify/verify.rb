require_relative '../lib/frameworkgen'
include FrameworkGen

VERIFY = File.join(BUILD, 'verify')
SIMULATOR = ENV.fetch('VERIFY_SIMULATOR', 'iPhone 17 Pro')

SDKS = {
  'Hyperswitch' => 'VERIFY_PAYMENTS',
  'HyperswitchPaymentMethods' => 'VERIFY_PAYMENT_METHODS',
  'HyperswitchPaymentMethodManagement' => 'VERIFY_PAYMENT_METHOD_MANAGEMENT',
  'HyperswitchLite' => 'VERIFY_LITE',
  'HyperswitchAuthentication' => 'VERIFY_AUTHENTICATION',
}.freeze

COMBOS = {
  'Payments' => %w[Hyperswitch],
  'PaymentMethods' => %w[HyperswitchPaymentMethods],
  'PaymentMethodManagement' => %w[HyperswitchPaymentMethodManagement],
  'Lite' => %w[HyperswitchLite],
  'Authentication' => %w[HyperswitchAuthentication HyperswitchAuthenticationNetcetera3DS],
  'All' => products.keys,
}.freeze
unknown = COMBOS.values.flatten.uniq - products.keys
abort "verify combos name products products.yml lacks: #{unknown.join(', ')}" unless unknown.empty?

abort 'build/artifacts is not a complete build: run frameworkgen/build.sh all' unless File.exist?(File.join(ARTIFACTS, '.local'))
selected = ARGV.empty? ? COMBOS.keys : ARGV
(selected - COMBOS.keys).each { |name| abort "unknown combo #{name}; known: #{COMBOS.keys.join(', ')}" }

targets = {}
schemes = {}
selected.each do |name|
  combo_products = COMBOS.fetch(name)
  conditions = combo_products.filter_map { |product| SDKS[product] }.join(' ')
  app = "Verify#{name}"
  targets[app] = {
    'type' => 'application',
    'platform' => 'iOS',
    'sources' => ['../../frameworkgen/verify/App'],
    'dependencies' => combo_products.map { |product| { 'package' => 'Hyperswitch', 'product' => product } },
    'info' => { 'path' => "#{app}/Info.plist", 'properties' => { 'UILaunchScreen' => {} } },
    'settings' => { 'base' => {
      'PRODUCT_BUNDLE_IDENTIFIER' => "io.hyperswitch.verify.#{name.downcase}",
      'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => "$(inherited) #{conditions}",
      'GENERATE_INFOPLIST_FILE' => 'YES',
    } },
  }
  schemes[app] = { 'build' => { 'targets' => { app => 'all' } } }
end

FileUtils.rm_rf(File.join(VERIFY, 'dd'))
FileUtils.mkdir_p(VERIFY)
FileUtils.mkdir_p(File.join(BUILD, 'frameworkgen', 'logs'))
spec = {
  'name' => 'Verify',
  'options' => { 'deploymentTarget' => { 'iOS' => '15.1' } },
  'settings' => { 'base' => { 'SWIFT_VERSION' => '5.0', 'CODE_SIGN_STYLE' => 'Automatic', 'DEVELOPMENT_TEAM' => '' } },
  'packages' => { 'Hyperswitch' => { 'path' => '../..' } },
  'targets' => targets,
  'schemes' => schemes,
}
File.write(File.join(VERIFY, 'project.yml'), YAML.dump(spec))
run!('xcodegen', 'generate', '--quiet', '--spec', File.join(VERIFY, 'project.yml'), chdir: VERIFY)

results = {}
selected.each do |name|
  app = "Verify#{name}"
  log = File.join(BUILD, 'frameworkgen', 'logs', "verify-#{name}.log")
  common = ['-project', File.join(VERIFY, 'Verify.xcodeproj'), '-scheme', app, '-derivedDataPath', File.join(VERIFY, 'dd')]
  steps = {
    'simulator' => ['xcodebuild', 'build', *common, '-configuration', 'Release', '-destination', "platform=iOS Simulator,name=#{SIMULATOR}"],
    'device' => ['xcodebuild', 'build', *common, '-configuration', 'Release', '-destination', 'generic/platform=iOS', 'CODE_SIGNING_ALLOWED=NO'],
  }
  File.write(log, "")
  results[name] = steps.map do |step, command|
    ok = system(*command, out: [log, 'a'], err: [:child, :out])
    "#{step} #{ok ? 'ok' : 'FAILED'}"
  end
  puts format('%-32s %s', app, results[name].join(', '))
end

failed = results.select { |_, steps| steps.any? { |step| step.include?('FAILED') } }
abort "verify: failed #{failed.keys.join(', ')} (logs in build/frameworkgen/logs/verify-*.log)" unless failed.empty?
puts "verify: #{results.size} apps OK"
