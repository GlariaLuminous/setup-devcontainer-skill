#!/usr/bin/env node
// Parses a .jsonc file: JSON plus // line comments and /* block comments */.
// Comments are blanked out rather than deleted so that error offsets keep
// pointing at the original line.
import { readFileSync } from 'node:fs';
import { pathToFileURL } from 'node:url';

export function stripComments(text) {
  let out = '';
  let inString = false;
  let inLine = false;
  let inBlock = false;

  for (let i = 0; i < text.length; i++) {
    const char = text[i];
    const next = text[i + 1];

    if (inLine) {
      if (char === '\n') {
        inLine = false;
        out += char;
      } else {
        out += ' ';
      }
      continue;
    }

    if (inBlock) {
      if (char === '*' && next === '/') {
        inBlock = false;
        out += '  ';
        i++;
      } else {
        out += char === '\n' ? '\n' : ' ';
      }
      continue;
    }

    if (inString) {
      out += char;
      if (char === '\\') {
        out += next ?? '';
        i++;
      } else if (char === '"') {
        inString = false;
      }
      continue;
    }

    if (char === '"') {
      inString = true;
      out += char;
      continue;
    }

    if (char === '/' && next === '/') {
      inLine = true;
      out += '  ';
      i++;
      continue;
    }

    if (char === '/' && next === '*') {
      inBlock = true;
      out += '  ';
      i++;
      continue;
    }

    out += char;
  }

  return out;
}

export function parseJsonc(text) {
  return JSON.parse(stripComments(text));
}

// Only act as a CLI when executed directly; importing this module must not
// run it. pathToFileURL handles Windows drive letters and backslashes.
const isMain = process.argv[1] !== undefined
  && import.meta.url === pathToFileURL(process.argv[1]).href;

if (isMain) {
  for (const file of process.argv.slice(2)) {
    try {
      parseJsonc(readFileSync(file, 'utf8'));
    } catch (error) {
      console.error(`${file}: ${error.message}`);
      process.exit(1);
    }
  }
}
