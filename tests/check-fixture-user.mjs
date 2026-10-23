#!/usr/bin/env node
// Fails when a devcontainer.json would leave the container running as root.
// The security baseline in SKILL.md requires a non-root remoteUser.
import { readFileSync } from 'node:fs';

const config = JSON.parse(readFileSync(process.argv[2], 'utf8'));
const user = config.remoteUser ?? config.containerUser ?? '';

if (user === '' || user === 'root' || user === '0') {
  console.error(`container would run as root (remoteUser=${JSON.stringify(config.remoteUser ?? null)})`);
  process.exit(1);
}
