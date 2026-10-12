const assert = require('node:assert/strict')
const path = require('node:path')
const fs = require('node:fs')
const {pathToFileURL} = require('node:url')

async function main() {
  const root = path.resolve(process.argv[2])
  const {getConfig} = require(path.join(root, 'node_modules/@expo/config'))
  const {IOSConfig} = require(path.join(root, 'node_modules/expo/config-plugins'))
  const {exp} = getConfig(root)
  assert.equal(IOSConfig.XcodeUtils.sanitizedName(exp.name), 'BlueskyShareTest')
  assert.equal(exp.ios.bundleIdentifier, 'org.sino87.blueskysharetest')
  assert.equal(exp.scheme, 'sino87blueskysharetest')
  assert.deepEqual(exp.ios.associatedDomains, [])
  assert.deepEqual(exp.ios.entitlements, {
    'com.apple.security.application-groups': ['group.org.sino87.blueskysharetest'],
  })
  assert.equal(exp.updates.enabled, false)
  assert.deepEqual(exp.extra.eas.build.experimental.ios.appExtensions.map(item => item.targetName).sort(), ['BlueskyNSE', 'Share-with-Bluesky'])
  const plugins = exp.plugins.map(item => Array.isArray(item) ? item[0] : item)
  assert(plugins.includes('./plugins/shareExtension/withShareExtensions.js'))
  assert(plugins.includes('./plugins/notificationsExtension/withNotificationsExtension.js'))
  assert(!plugins.includes('./plugins/starterPackAppClipExtension/withStarterPackAppClip.js'))
  const {parseLinkingUrl} = await import(pathToFileURL(path.join(root, 'src/lib/parseLinkingUrl.ts')))
  const text = 'A shared caption\nhttps://example.com/invite'
  for (const prefix of ['sino87blueskysharetest://', 'sino87blueskysharetest:///']) {
    const parsed = parseLinkingUrl(`${prefix}intent/compose?text=${encodeURIComponent(text)}`)
    assert.equal(parsed.hostname, '')
    assert.equal(parsed.pathname, '/intent/compose')
    assert.equal(parsed.searchParams.get('text'), text)
  }
  assert.equal(parseLinkingUrl('https://bsky.app/profile/example.com').pathname, '/profile/example.com')
  const config = JSON.parse(fs.readFileSync(path.join(root, 'verification-config.json')))
  const input = fs.readFileSync(path.join(root, 'src/view/com/composer/text-input/TextInput.tsx'))
  assert.equal(require('node:crypto').createHash('sha256').update(input).digest('hex'), config.composerInputSHA256)
  console.log('PASS: Expo configuration, extension retention, isolated compose links and unchanged composer input')
}
main().catch(error => { console.error(error); process.exitCode = 1 })
