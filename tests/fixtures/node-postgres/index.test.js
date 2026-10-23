import assert from 'node:assert/strict';
import test from 'node:test';

import { connectionTimeout, databaseUrl } from './index.js';

test('compose injects DATABASE_URL into the app container', () => {
  assert.match(databaseUrl(), /^postgres:\/\//);
});

test('the installed dependency resolves', () => {
  assert.equal(connectionTimeout(), 30000);
});
