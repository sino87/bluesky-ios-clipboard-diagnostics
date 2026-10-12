require 'xcodeproj'
require 'fileutils'
require 'digest'

source_root = File.expand_path(ARGV.fetch(0))
controller_path = File.join(source_root, 'modules/Share-with-Bluesky/ShareViewController.swift')
controller = File.read(controller_path)
raise 'Unexpected upstream App Group references' unless controller.scan('group.app.bsky').length == 1
raise 'Expected patched share controller' unless controller.include?('private func handleText(items: [NSItemProvider])')

bundle_id = 'org.sino87.clipboardprobe'
group_id = "group.#{bundle_id}"
scheme_id = 'sino87clipboardprobe4'
FileUtils.mkdir_p('generated/device-probe')
File.write('generated/device-probe/ShareViewController.swift', controller.gsub('"group.app.bsky"', 'ProbeStore.groupIdentifier'))

common_info = {
  'CFBundleDevelopmentRegion' => 'en',
  'CFBundleExecutable' => '$(EXECUTABLE_NAME)',
  'CFBundleIdentifier' => '$(PRODUCT_BUNDLE_IDENTIFIER)',
  'CFBundleInfoDictionaryVersion' => '6.0',
  'CFBundleName' => '$(PRODUCT_NAME)',
  'CFBundleShortVersionString' => '1.0',
  'CFBundleVersion' => '4',
  'CFBundleDisplayName' => 'Share Probe 4',
  'MainAppScheme' => scheme_id,
  'ProbeAppGroup' => group_id,
  'ProbeControllerSHA256' => Digest::SHA256.hexdigest(controller),
  'ProbeUpstreamCommit' => '46d98dd457a197cee8502863b420222508f29fa6'
}
app_info = common_info.merge(
  'CFBundlePackageType' => 'APPL',
  'LSRequiresIPhoneOS' => true,
  'UILaunchScreen' => {},
  'UISupportedInterfaceOrientations' => ['UIInterfaceOrientationPortrait'],
  'CFBundleURLTypes' => [{ 'CFBundleURLName' => bundle_id, 'CFBundleURLSchemes' => [scheme_id] }]
)
extension_info = common_info.merge(
  'CFBundlePackageType' => 'XPC!',
  'NSExtension' => {
    'NSExtensionPrincipalClass' => '$(PRODUCT_MODULE_NAME).DeviceShareViewController',
    'NSExtensionPointIdentifier' => 'com.apple.share-services',
    'NSExtensionAttributes' => {
      'NSExtensionActivationRule' => {
        'NSExtensionActivationSupportsText' => true,
        'NSExtensionActivationSupportsWebURLWithMaxCount' => 1,
        'NSExtensionActivationSupportsImageWithMaxCount' => 10,
        'NSExtensionActivationSupportsMovieWithMaxCount' => 1
      }
    }
  }
)
Xcodeproj::Plist.write_to_path(app_info, 'generated/device-probe/App-Info.plist')
Xcodeproj::Plist.write_to_path(extension_info, 'generated/device-probe/Share-Info.plist')
Xcodeproj::Plist.write_to_path(
  { 'com.apple.security.application-groups' => [group_id] },
  'generated/device-probe/Probe.entitlements'
)

project = Xcodeproj::Project.new('generated/device-probe/ClipboardDeviceProbe.xcodeproj')
app = project.new_target(:application, 'ClipboardDeviceProbe', :ios, '18.0')
extension = project.new_target(:app_extension, 'ClipboardProbeShare', :ios, '18.0')
app.add_dependency(extension)
embed = app.new_copy_files_build_phase('Embed App Extensions')
embed.dst_subfolder_spec = '13'
embed.add_file_reference(extension.product_reference).settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }

%w[AppDelegate.swift ProbeViewController.swift ProbeStore.swift ProfileDiagnostics.swift].each do |name|
  app.source_build_phase.add_file_reference(project.main_group.new_file("../../device-probe/#{name}"))
end
%w[DeviceShareViewController.swift ProbeStore.swift].each do |name|
  extension.source_build_phase.add_file_reference(project.main_group.new_file("../../device-probe/#{name}"))
end
extension.source_build_phase.add_file_reference(project.main_group.new_file('ShareViewController.swift'))

[app, extension].each do |target|
  target.build_configurations.each do |configuration|
    settings = configuration.build_settings
    settings['SWIFT_VERSION'] = '5.0'
    settings['CODE_SIGNING_ALLOWED'] = 'NO'
    settings['CODE_SIGNING_REQUIRED'] = 'NO'
    settings['CODE_SIGN_ENTITLEMENTS'] = 'Probe.entitlements'
    settings['GENERATE_INFOPLIST_FILE'] = 'NO'
    settings['INFOPLIST_FILE'] = target == app ? 'App-Info.plist' : 'Share-Info.plist'
    settings['PRODUCT_BUNDLE_IDENTIFIER'] = target == app ? bundle_id : "#{bundle_id}.share"
    settings['TARGETED_DEVICE_FAMILY'] = '1'
    settings['SKIP_INSTALL'] = target == app ? 'NO' : 'YES'
    settings['APPLICATION_EXTENSION_API_ONLY'] = 'YES' if target == extension
  end
end
project.save
scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(app)
scheme.set_launch_target(app)
scheme.archive_action.build_configuration = 'Release'
scheme.save_as(project.path, 'ClipboardDeviceProbe', true)
puts "Generated device app and share extension: #{bundle_id}, #{group_id}"
