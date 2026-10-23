import ms from 'ms';

export function databaseUrl() {
  return process.env.DATABASE_URL ?? '';
}

// Uses an installed dependency so that a postCreateCommand which silently
// failed to run npm ci breaks this fixture instead of passing it.
export function connectionTimeout() {
  return ms('30s');
}
