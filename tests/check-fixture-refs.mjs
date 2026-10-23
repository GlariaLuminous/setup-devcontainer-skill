#!/usr/bin/env node
// Resolves every Dockerfile / build context referenced by a fixture's
// devcontainer.json and reports the ones that do not exist on disk.
//
// This is the check that catches "Strategy C without a Dockerfile" and
// "build context points outside the project" without paying for a docker
// build. Usage: node tests/check-fixture-refs.mjs <fixture-dir>
import { existsSync, readFileSync, statSync } from 'node:fs';
import { dirname, relative, resolve } from 'node:path';

const fixtureDir = resolve(process.argv[2] ?? '');
const configPath = resolve(fixtureDir, '.devcontainer', 'devcontainer.json');

if (!existsSync(configPath)) {
  console.error(`missing ${configPath}`);
  process.exit(1);
}

const config = JSON.parse(readFileSync(configPath, 'utf8'));
const devcontainerDir = dirname(configPath);

function report(label, target, mustBeDirectory) {
  const exists = existsSync(target);
  const ok = exists && (mustBeDirectory ? statSync(target).isDirectory() : statSync(target).isFile());
  if (!ok) {
    console.log(`MISSING\t${label}\t${relative(fixtureDir, target) || '.'}`);
  }
  return ok;
}

// Minimal compose reader: returns the service names and the raw text of each
// service body. Only needs to survive the shapes this repository generates,
// so it deliberately avoids pulling in a YAML dependency -- but it does not
// assume a particular indentation width, which a plain regex would.
function readServices(text) {
  const lines = text.split(/\r?\n/);
  const services = new Map();

  const servicesAt = lines.findIndex((line) => /^services:\s*$/.test(line));
  if (servicesAt === -1) return services;

  const serviceIndent = lines
    .slice(servicesAt + 1)
    .find((line) => /^\s+\S/.test(line))
    ?.match(/^\s+/)[0].length;
  if (serviceIndent === undefined) return services;

  let current = null;
  let body = [];

  for (const line of lines.slice(servicesAt + 1)) {
    if (/^\s*(#.*)?$/.test(line)) continue;

    const indent = line.match(/^\s*/)[0].length;
    if (indent < serviceIndent) break;

    const header = indent === serviceIndent && line.match(/^\s+([A-Za-z0-9_.-]+):\s*$/);
    if (header) {
      if (current) services.set(current, body.join('\n'));
      current = header[1];
      body = [];
    } else if (current) {
      body.push(line);
    }
  }
  if (current) services.set(current, body.join('\n'));

  return services;
}

let ok = true;

if (config.build) {
  const context = config.build.context ?? '.';
  const dockerfile = config.build.dockerfile ?? 'Dockerfile';
  const contextDir = resolve(devcontainerDir, context);
  ok = report('build context', contextDir, true) && ok;
  ok = report('Dockerfile', resolve(contextDir, dockerfile), false) && ok;
}

const composeFiles = config.dockerComposeFile
  ? (Array.isArray(config.dockerComposeFile) ? config.dockerComposeFile : [config.dockerComposeFile])
  : [];

for (const composeFile of composeFiles) {
  const composePath = resolve(devcontainerDir, composeFile);
  if (!report('compose file', composePath, false)) {
    ok = false;
    continue;
  }

  const services = readServices(readFileSync(composePath, 'utf8'));
  const service = config.service ?? [...services.keys()][0];

  if (!services.has(service)) {
    console.log(`MISSING\tservice ${service}\tnot defined in ${composeFile}`);
    ok = false;
    continue;
  }

  // Only the service devcontainer.json selects is built, so only that one
  // needs its Dockerfile to exist.
  const body = services.get(service);
  const dockerfile = body.match(/^\s*dockerfile:\s*(\S+)/m);
  if (!dockerfile) continue;

  const context = body.match(/^\s*context:\s*(\S+)/m);
  const contextDir = resolve(dirname(composePath), context ? context[1] : '.');
  ok = report('compose build context', contextDir, true) && ok;
  ok = report('compose Dockerfile', resolve(contextDir, dockerfile[1]), false) && ok;
}

process.exit(ok ? 0 : 1);
