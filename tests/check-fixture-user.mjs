#!/usr/bin/env node
// A fixture must run as a non-root user that the image actually ships.
//
// This is the check that would have caught the shipped bug where
// templates/node.jsonc paired typescript-node:22 with remoteUser "vscode":
// that image has no vscode user, so the container died at startup with
//   unable to find user vscode: no matching entries in passwd file
//
// Usage: node check-fixture-user.mjs <devcontainer.json> [fixture-dir]
import { readFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';
import { parseJsonc } from './parse-jsonc.mjs';
import { expectedUser, imageFromDockerfile } from './image-user.mjs';

const [configPath, fixtureDir] = process.argv.slice(2);
const config = parseJsonc(readFileSync(configPath, 'utf8'));
const user = config.remoteUser ?? config.containerUser ?? '';

if (user === '' || user === 'root' || user === '0') {
  console.error(`container would run as root (remoteUser=${JSON.stringify(config.remoteUser ?? null)})`);
  process.exit(1);
}

// Resolve the image: an "image" field (Strategy A) or the FROM line of the
// Dockerfile (Strategy B and C). If neither is readable, only the non-root
// requirement above applies.
let image = config.image ?? '';
if (image === '' && fixtureDir) {
  const dockerfile = join(fixtureDir, '.devcontainer', 'Dockerfile');
  if (existsSync(dockerfile)) {
    image = imageFromDockerfile(readFileSync(dockerfile, 'utf8'));
  }
}

if (image === '') {
  process.exit(0);
}

const expected = expectedUser(image);
if (user !== expected) {
  console.error(
    `${configPath}: remoteUser is ${JSON.stringify(user)}, but image ${JSON.stringify(image)} ships ${JSON.stringify(expected)}`,
  );
  process.exit(1);
}
