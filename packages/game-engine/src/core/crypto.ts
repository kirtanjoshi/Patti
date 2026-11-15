import { createHash } from 'node:crypto';

export function sha256(input: string): string {
  return createHash('sha256').update(input, 'utf8').digest('hex');
}

export function commitSeed(seed: string): string {
  return sha256(seed);
}

export function verifySeed(seed: string, expectedHash: string): boolean {
  return sha256(seed).toLowerCase() === expectedHash.toLowerCase();
}
