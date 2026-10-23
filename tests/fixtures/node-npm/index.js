import ms from 'ms';

export function add(a, b) {
  return a + b;
}

// Deliberately uses an installed dependency so a broken postCreateCommand
// (npm ci silently not running) fails this fixture instead of passing it.
export function humanDuration(seconds) {
  return ms(seconds * 1000);
}
