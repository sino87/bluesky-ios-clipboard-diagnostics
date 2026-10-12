require 'xcodeproj'

ios = File.join(File.expand_path(ARGV.fetch(0)), 'ios')
project_path = Dir[File.join(ios, '*.xcodeproj')].fetch(0)
project = Xcodeproj::Project.open(project_path)
expected = ['BlueskyShareTest', 'Share-with-Bluesky', 'BlueskyNSE']
raise 'Unexpected app targets' unless project.targets.map(&:name).sort == expected.sort
group = 'group.org.sino87.blueskysharetest'
project.build_configurations.each { |configuration| configuration.build_settings.delete('DEVELOPMENT_TEAM') }
project.root_object.attributes.fetch('TargetAttributes', {}).each_value { |attributes| attributes.delete('DevelopmentTeam') }
project.targets.each do |target|
  target.build_configurations.each do |configuration|
    settings = configuration.build_settings
    settings.delete('DEVELOPMENT_TEAM')
    settings['CODE_SIGNING_ALLOWED'] = 'NO'
    settings['CODE_SIGNING_REQUIRED'] = 'NO'
    settings['CODE_SIGN_IDENTITY'] = ''
    if target.name != 'BlueskyShareTest'
      settings['APPLICATION_EXTENSION_API_ONLY'] = 'YES'
      settings['SKIP_INSTALL'] = 'YES'
    end
    entitlement_path = settings.fetch('CODE_SIGN_ENTITLEMENTS').delete('"')
    Xcodeproj::Plist.write_to_path({'com.apple.security.application-groups' => [group]}, File.join(ios, entitlement_path))
    info_path = settings.fetch('INFOPLIST_FILE').delete('"')
    info_path = File.join(ios, info_path)
    info = Xcodeproj::Plist.read_from_path(info_path)
    info['CFBundleDisplayName'] = target.name == 'BlueskyNSE' ? 'Bluesky Test Notifications' : 'Bluesky Share Test'
    Xcodeproj::Plist.write_to_path(info, info_path)
  end
end
project.save
puts "Configured unsigned targets: #{expected.join(', ')}"
