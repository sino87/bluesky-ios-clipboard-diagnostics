require 'xcodeproj'
require 'fileutils'

source_root = File.expand_path(ARGV.fetch(0))
raise 'Run from the diagnostics directory' unless File.file?('AppDelegate.swift')
controller = File.join(source_root, 'modules/Share-with-Bluesky/ShareViewController.swift')
raise "Missing upstream source: #{controller}" unless File.file?(controller)

FileUtils.mkdir_p('generated')
FileUtils.cp(controller, 'generated/ShareViewController.swift')
project = Xcodeproj::Project.new('generated/ClipboardDiagnostics.xcodeproj')
app = project.new_target(:application, 'ClipboardDiagnostics', :ios, '18.0')
tests = project.new_target(:unit_test_bundle, 'ClipboardDiagnosticsTests', :ios, '18.0')
tests.add_dependency(app)

app.source_build_phase.add_file_reference(project.main_group.new_file('../AppDelegate.swift'))
app.source_build_phase.add_file_reference(project.main_group.new_file('ShareViewController.swift'))
tests.source_build_phase.add_file_reference(project.main_group.new_file('../ClipboardDiagnosticsTests.swift'))

[app, tests].each do |target|
  target.build_configurations.each do |configuration|
    settings = configuration.build_settings
    settings['SWIFT_VERSION'] = '5.0'
    settings['CODE_SIGNING_ALLOWED'] = 'NO'
    settings['GENERATE_INFOPLIST_FILE'] = 'YES'
    settings['PRODUCT_BUNDLE_IDENTIFIER'] = "org.clipboard.diagnostics.#{target.name}"
    settings['TARGETED_DEVICE_FAMILY'] = '1,2'
    settings['ENABLE_TESTABILITY'] = 'YES'
  end
end

tests.build_configurations.each do |configuration|
  configuration.build_settings['TEST_HOST'] = '$(BUILT_PRODUCTS_DIR)/ClipboardDiagnostics.app/ClipboardDiagnostics'
  configuration.build_settings['BUNDLE_LOADER'] = '$(TEST_HOST)'
end

project.save
scheme = Xcodeproj::XCScheme.new
scheme.configure_with_targets(app, tests, launch_target: true)
scheme.save_as(project.path, 'ClipboardDiagnostics', true)
