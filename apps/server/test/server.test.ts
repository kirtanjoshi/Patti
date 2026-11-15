import { describe, expect, it } from 'vitest';
import { AppModule } from '../src/app.module.js';

describe('Server Application Module', () => {
  it('instantiates AppModule', () => {
    expect(AppModule).toBeDefined();
  });
});
