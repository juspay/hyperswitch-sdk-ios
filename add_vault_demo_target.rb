require 'xcodeproj'

project_path = File.expand_path('hyperswitch.xcodeproj', __dir__)
project = Xcodeproj::Project.open(project_path)
target_name = 'hyperswitchVaultDemo'

if project.targets.any? { |t| t.name == target_name }
  puts "Target #{target_name} already exists, skipping"
  exit 0
end

group = project.main_group.new_group(target_name, target_name)
app_delegate_ref = group.new_file('AppDelegate.swift')
group.new_file('Info.plist')

target = project.new_target(:application, target_name, :ios, '15.1', nil, :swift)
target.source_build_phase.add_file_reference(app_delegate_ref)

target.build_configurations.each do |config|
  bs = config.build_settings
  bs['INFOPLIST_FILE'] = 'hyperswitchVaultDemo/Info.plist'
  bs['PRODUCT_BUNDLE_IDENTIFIER'] = 'io.hyperswitch.vault.demo'
  bs['IPHONEOS_DEPLOYMENT_TARGET'] = '15.1'
  bs['TARGETED_DEVICE_FAMILY'] = '1,2'
  bs['SWIFT_VERSION'] = '5.0'
  bs['GENERATE_INFOPLIST_FILE'] = 'NO'
  bs['MARKETING_VERSION'] = '1.0'
  bs['CURRENT_PROJECT_VERSION'] = '1'
  bs['LD_RUNPATH_SEARCH_PATHS'] = ['$(inherited)', '@executable_path/Frameworks']
end

project.save
puts "Added target #{target_name} to #{project_path}"

scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(target)
scheme.set_launch_target(target)
scheme.save_as(project_path, target_name, true)
puts "Created shared scheme #{target_name}"
