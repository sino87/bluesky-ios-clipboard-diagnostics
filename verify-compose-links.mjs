import assert from 'node:assert/strict'
import {readFileSync} from 'node:fs'
import path from 'node:path'
import {pathToFileURL} from 'node:url'

export function verifyComposeRecords(records, parseLinkingUrl) {
  assert(records.length > 0, 'No native compose-link records were captured')
  const seenCases = new Set()
  for (const record of records) {
    assert(!seenCases.has(record.case), `Duplicate native case: ${record.case}`)
    seenCases.add(record.case)
    const parsed = parseLinkingUrl(record.url)
    assert.equal(parsed.pathname, '/intent/compose')
    assert.deepEqual([...parsed.searchParams.keys()], ['text'])
    assert.equal(parsed.searchParams.get('text'), record.text, record.case)
  }
  return seenCases
}

async function main() {
  const [logFile, sourceRoot] = process.argv.slice(2)
  assert(logFile && sourceRoot, 'Usage: node verify-compose-links.mjs <xcodebuild.log> <source-root>')
  const marker = '[compose-encoding] '
  const records = readFileSync(logFile, 'utf8').split(/\r?\n/)
    .filter(line => line.includes(marker))
    .map(line => JSON.parse(line.slice(line.indexOf(marker) + marker.length)))
  const {parseLinkingUrl} = await import(pathToFileURL(path.resolve(sourceRoot, 'src/lib/parseLinkingUrl.ts')))
  const cases = verifyComposeRecords(records, parseLinkingUrl)
  assert.deepEqual([...cases].sort(), [
    'percent-fragment-text',
    'plus-text',
    'query-text',
    'query-url',
    'separate-special-text-url',
  ])
  console.log(`PASS: ${cases.size} native compose links preserve text through the Bluesky receiver`)
}

if (process.argv[1] && import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href) {
  main().catch(error => {
    console.error(error)
    process.exitCode = 1
  })
}
