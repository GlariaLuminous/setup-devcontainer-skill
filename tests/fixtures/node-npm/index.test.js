import assert from 'node:assert/strict';
import test from 'node:test';

import { add, humanDuration } from './index.js';

test('add returns the sum', () => {
  assert.equal(add(1, 2), 3);
});

test('humanDuration resolves the installed dependency', () => {
  assert.equal(humanDuration(120), '2m');
});
