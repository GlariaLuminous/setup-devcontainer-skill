import assert from 'node:assert/strict';
import test from 'node:test';

import { connectionTimeout, databaseUrl } from './index.js';

// DATABASE_URL only exists inside the compose app container, so this test is
// skipped when the suite is run straight on a host. verify.sh asserts the
// variable is present in the container, so the container path stays covered.
test('compose injects DATABASE_URL into the app container', (t) => {
  if (databaseUrl() === '') {
    t.skip('DATABASE_URL is not set; run this inside the dev container');
    return;
  }
  assert.match(databaseUrl(), /^postgres:\/\//);
});

test('the installed dependency resolves', () => {
  assert.equal(connectionTimeout(), 30000);
});
