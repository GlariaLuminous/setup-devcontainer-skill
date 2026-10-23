#!/usr/bin/env node
// remoteUser must name a user that exists in the image. See image-user.mjs.
import { readFileSync } from 'node:fs';
import { parseJsonc } from './parse-jsonc.mjs';
import { expectedUser } from './image-user.mjs';

for (const file of process.argv.slice(2)) {
  const config = parseJsonc(readFileSync(file, 'utf8'));
  const image = config.image ?? '';
  const expected = expectedUser(image);
  const actual = config.remoteUser ?? config.containerUser ?? '';

  if (actual !== expected) {
    console.error(
      `${file}: remoteUser is ${JSON.stringify(actual)}, but image ${JSON.stringify(image)} ships ${JSON.stringify(expected)}`,
    );
    process.exit(1);
  }
}
