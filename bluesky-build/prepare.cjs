const fs = require('node:fs')
const path = require('node:path')
const crypto = require('node:crypto')

const root = path.resolve(process.argv[2])
if (path.basename(root) !== 'upstream') throw new Error('Use a disposable upstream checkout')
const bundle = 'org.sino87.blueskysharetest'
const group = `group.${bundle}`
const scheme = 'sino87blueskysharetest'
const changes = []
const digest = value => crypto.createHash('sha256').update(value).digest('hex')
const inputPath = path.join(root, 'src/view/com/composer/text-input/TextInput.tsx')
const inputHash = digest(fs.readFileSync(inputPath))

function replace(relative, before, after, count = 1) {
  const file = path.join(root, relative)
  const original = fs.readFileSync(file, 'utf8')
  if (original.split(before).length - 1 !== count) throw new Error(`Unexpected source: ${relative}`)
  fs.writeFileSync(file, original.split(before).join(after))
  changes.push(relative)
}

const nativeFiles = [
  'modules/Share-with-Bluesky/ShareViewController.swift',
  'modules/BlueskyNSE/NotificationService.swift',
  'modules/expo-background-notification-handler/ios/ExpoBackgroundNotificationHandlerModule.swift',
  'modules/expo-bluesky-swiss-army/ios/SharedPrefs/SharedPrefs.swift',
  'modules/expo-bluesky-swiss-army/ios/SharedPrefs/ExpoBlueskySharedPrefsModule.swift',
]
for (const relative of nativeFiles) {
  const identifier = `verificationGroup${path.basename(relative, '.swift')}`
  replace(relative, '"group.app.bsky"', `${identifier}()`)
  const file = path.join(root, relative)
  let source = fs.readFileSync(file, 'utf8')
  if (!source.includes('import Foundation')) source = 'import Foundation\n' + source
  source += `
private func ${identifier}() -> String {
  let requested = "${group}"
  guard let groups = Bundle.main.object(forInfoDictionaryKey: "ALTAppGroups") as? [String] else {
    return requested
  }
  let matching = groups.filter { $0 == requested || $0.hasPrefix(requested + ".") }
  guard matching.count == 1, let assigned = matching.first else {
    preconditionFailure("Unexpected verification App Group mapping")
  }
  return assigned
}
`
  fs.writeFileSync(file, source)
}
for (const plugin of ['shareExtension', 'notificationsExtension']) {
  for (const file of ['withAppEntitlements.js', 'withExtensionEntitlements.js']) {
    replace(`plugins/${plugin}/${file}`, 'group.app.bsky', group)
  }
}
replace('src/Navigation.tsx', "prefixes: ['bsky://', 'bluesky://', 'https://bsky.app']", `prefixes: ['${scheme}://', 'https://bsky.app']`)
const parserFile = path.join(root, 'src/lib/parseLinkingUrl.ts')
const parser = fs.readFileSync(parserFile, 'utf8')
if (!parser.includes("url.startsWith('bluesky://')")) throw new Error('Unexpected linking parser')
fs.writeFileSync(parserFile, parser.replaceAll('bluesky:', `${scheme}:`))
changes.push('src/lib/parseLinkingUrl.ts')
replace('modules/expo-bluesky-swiss-army/ios/NotificationSettings/ExpoBlueskyNotificationSettingsModule.swift', '"bluesky://settings/notifications"', `"${scheme}://settings/notifications"`)

fs.copyFileSync(path.join(root, 'app.config.js'), path.join(root, 'app.config.base.js'))
fs.writeFileSync(path.join(root, 'app.config.js'), `
module.exports = function (input) {
  const config = require('./app.config.base.js')(input).expo
  config.name = 'Bluesky Share Test'
  config.scheme = '${scheme}'
  config.ios.bundleIdentifier = '${bundle}'
  config.ios.buildNumber = process.env.GITHUB_RUN_NUMBER || '1'
  delete config.ios.appleTeamId
  config.ios.associatedDomains = []
  config.ios.entitlements = {'com.apple.security.application-groups': ['${group}']}
  config.ios.infoPlist.UIBackgroundModes = config.ios.infoPlist.UIBackgroundModes.filter(mode => mode !== 'remote-notification')
  config.updates.enabled = false
  config.plugins = config.plugins.filter(plugin => {
    const name = Array.isArray(plugin) ? plugin[0] : plugin
    return name !== './plugins/starterPackAppClipExtension/withStarterPackAppClip.js'
  })
  const extensions = config.extra.eas.build.experimental.ios.appExtensions
    .filter(extension => extension.targetName !== 'BlueskyClip')
  for (const extension of extensions) {
    extension.bundleIdentifier = '${bundle}.' + extension.targetName
    extension.entitlements = {'com.apple.security.application-groups': ['${group}']}
  }
  config.extra.eas.build.experimental.ios.appExtensions = extensions
  delete config.extra.eas.projectId
  return {expo: config}
}
`)
if (digest(fs.readFileSync(inputPath)) !== inputHash) throw new Error('Composer input must remain unchanged')
const config = require(path.join(root, 'app.config.js'))({}).expo
if (!config.plugins.includes('./plugins/shareExtension/withShareExtensions.js')) throw new Error('Share extension missing')
if (!config.plugins.includes('./plugins/notificationsExtension/withNotificationsExtension.js')) throw new Error('Notification service source missing')
const manifest = {
  bundle, group, scheme, changes,
  variant: process.env.BUILD_VARIANT || 'fixed',
  upstreamCommit: '46d98dd457a197cee8502863b420222508f29fa6',
  composerInputSHA256: inputHash,
  retained: ['Bluesky UI and composer', 'ordinary paste', 'Share Extension', 'App Groups', 'notification service target'],
  unavailable: ['remote push notifications', 'App Clip', 'associated-domain launch', 'communication notifications', 'extra memory entitlements', 'declared age-range entitlement', 'OTA updates'],
  appleSigned: false,
}
fs.writeFileSync(path.join(root, 'verification-config.json'), JSON.stringify(manifest, null, 2) + '\n')
console.log(JSON.stringify(manifest, null, 2))
