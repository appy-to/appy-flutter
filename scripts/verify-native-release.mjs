#!/usr/bin/env node
// This file is copied into both wrapper repositories. It uses only Node built-ins.
import {readFileSync} from 'node:fs';
import {dirname, resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
import {execFileSync} from 'node:child_process';

export function validateManifest(config) {
  if (config.source !== 'published') {
    throw new Error('Native SDK source is local. Publish Android to Maven Central before releasing this wrapper, then set native-sdk.json source to published.');
  }
  if (!/^\d+\.\d+\.\d+$/.test(config.version ?? '')) throw new Error('Invalid native SDK version.');
  const iosURL = config.ios?.gitUrl ?? config.ios?.packageUrl;
  if (iosURL !== 'https://github.com/appy-to/appy-ios-sdk.git') throw new Error('Unexpected iOS SDK repository.');
  if (config.android?.coordinates !== 'to.appy:appy-sdk') throw new Error('Unexpected Android SDK coordinates.');
  return config.version;
}

export async function verifyPublished(config, fetchURL = fetch, git = execFileSync) {
  const version = validateManifest(config);
  const tag = git('git', ['ls-remote', '--exit-code', '--tags', 'https://github.com/appy-to/appy-ios-sdk.git', `refs/tags/${version}`], {encoding: 'utf8', timeout: 30_000});
  if (!tag.trim()) throw new Error(`Public SPM tag ${version} is missing.`);
  const base = `https://repo.maven.apache.org/maven2/to/appy/appy-sdk/${version}/appy-sdk-${version}`;
  for (const extension of ['pom', 'aar']) {
    const response = await fetchURL(`${base}.${extension}`, {method: 'HEAD', signal: AbortSignal.timeout(30_000)});
    if (!response.ok) throw new Error(`Maven Central ${version}.${extension} is unavailable (HTTP ${response.status}). Do not publish the wrapper yet.`);
  }
  return version;
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const root = resolve(process.argv[2] ?? dirname(fileURLToPath(import.meta.url)) + '/..');
  try {
    const config = JSON.parse(readFileSync(resolve(root, 'native-sdk.json'), 'utf8'));
    const version = await verifyPublished(config);
    console.log(`Native SDK ${version}: public SPM tag and Maven Central POM/AAR are available.`);
  } catch (error) {
    console.error(error.message);
    process.exitCode = 1;
  }
}
