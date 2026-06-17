#!/usr/bin/env ruby
require 'xcodeproj'
require 'fileutils'

project_path = File.expand_path('../macos/Ponten.xcodeproj', __dir__)
project = Xcodeproj::Project.open(project_path)

app_target = project.targets.find { |t| t.name == 'Ponten' }
abort('Ponten target not found') unless app_target

uitest_name = 'PontenUITests'
existing = project.targets.find { |t| t.name == uitest_name }

if existing
  puts "#{uitest_name} already exists"
  target = existing
else
  puts "Creating #{uitest_name} target"
  target = project.new_target(:ui_test_bundle, uitest_name, :osx, '13.0', nil, 'com.ponten.app.uitests')
  target.product_type = 'com.apple.product-type.bundle.ui-testing'
  target.add_dependency(app_target)

  group = project.main_group.find_subpath(uitest_name, true) || project.main_group.new_group(uitest_name, uitest_name)

  test_file = File.expand_path('../macos/PontenUITests/MenuBarUITests.swift', __dir__)
  FileUtils.mkdir_p(File.dirname(test_file))

  file_ref = group.new_file('MenuBarUITests.swift')
  target.add_file_references([file_ref])

  project.targets.each do |t|
    next unless t.respond_to?(:product_type)
  end

  # Add to scheme
  scheme_path = File.expand_path('../macos/Ponten.xcodeproj/xcshareddata/xcschemes/Ponten.xcscheme', __dir__)
  if File.exist?(scheme_path)
    scheme = Xcodeproj::XCScheme.new(scheme_path)
    test_action = scheme.test_action
    testable = Xcodeproj::XCScheme::TestAction::TestableReference.new(target)
    testable.skipped = false
    test_action.add_testable(testable)
    scheme.save!
    puts 'Added PontenUITests to Ponten scheme'
  end
end

target.build_configurations.each do |config|
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = nil
  config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '13.0'
  config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
  config.build_settings['GENERATE_INFOPLIST_FILE'] = 'YES'
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.ponten.app.uitests'
  config.build_settings['SWIFT_VERSION'] = '5.9'
  config.build_settings['TEST_TARGET_NAME'] = 'Ponten'
  config.build_settings['DEVELOPMENT_TEAM'] = ''
end

project.save
puts 'Done.'