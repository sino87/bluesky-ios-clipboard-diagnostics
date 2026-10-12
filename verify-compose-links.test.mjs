import assert from 'node:assert/strict'
import path from 'node:path'
import test from 'node:test'
import {pathToFileURL} from 'node:url'
import {verifyComposeRecords} from './verify-compose-links.mjs'

assert(process.env.BLUESKY_SOURCE_ROOT, 'Set BLUESKY_SOURCE_ROOT to the Bluesky checkout')
const {parseLinkingUrl} = await import(pathToFileURL(path.resolve(process.env.BLUESKY_SOURCE_ROOT, 'src/lib/parseLinkingUrl.ts')))

test('receiver rejects a compose link with an unescaped query separator', () => {
  assert.throws(() => verifyComposeRecords([{
    case: 'query-separator',
    text: 'https://example.com/?a=1&b=2',
    url: 'bluesky://intent/compose?text=https:%2F%2Fexample.com%2F%3Fa=1&b=2',
  }], parseLinkingUrl))
})

test('receiver rejects a compose link that decodes a literal plus as a space', () => {
  assert.throws(() => verifyComposeRecords([{
    case: 'plus-sign',
    text: 'A+B',
    url: 'bluesky://intent/compose?text=A+B',
  }], parseLinkingUrl))
})

test('receiver preserves escaped separators, plus signs and percent escapes', () => {
  const cases = verifyComposeRecords([{
    case: 'query-separator',
    text: 'https://example.com/?a=1&b=2',
    url: 'bluesky://intent/compose?text=https%3A%2F%2Fexample.com%2F%3Fa%3D1%26b%3D2',
  }, {
    case: 'plus-sign',
    text: 'A+B %2B #',
    url: 'bluesky://intent/compose?text=A%2BB%20%252B%20%23',
  }], parseLinkingUrl)
  assert.deepEqual([...cases], ['query-separator', 'plus-sign'])
})

test('receiver verification fails when native records are absent', () => {
  assert.throws(() => verifyComposeRecords([], parseLinkingUrl), /No native compose-link records/)
})
