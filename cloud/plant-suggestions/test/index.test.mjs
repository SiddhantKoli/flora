import test from 'node:test';
import assert from 'node:assert/strict';
import worker, { normalizeResult } from '../src/index.mjs';

function photoRequest() {
  const bytes = new Uint8Array(200);
  bytes[0] = 0xff;
  bytes[1] = 0xd8;
  const body = new FormData();
  body.append('image', new Blob([bytes], { type: 'image/jpeg' }), 'capture.jpg');
  return new Request('https://flora.example/identify', { method: 'POST', body });
}

function limits(allowed = true) {
  return {
    CLIENT_LIMIT: { limit: async () => ({ success: allowed }) },
    GLOBAL_LIMIT: { limit: async () => ({ success: allowed }) },
  };
}

test('normalizes a Pl@ntNet candidate', () => {
  assert.deepEqual(normalizeResult({
    score: .91,
    species: {
      scientificNameWithoutAuthor: 'Hibiscus rosa-sinensis',
      commonNames: ['Chinese hibiscus'],
      family: { scientificNameWithoutAuthor: 'Malvaceae' },
    },
  }), {
    scientificName: 'Hibiscus rosa-sinensis',
    commonName: 'Chinese hibiscus',
    family: 'Malvaceae',
    score: .91,
  });
});

test('does not request identification without a server secret', async () => {
  const response = await worker.fetch(photoRequest(), {});
  assert.equal(response.status, 503);
});

test('forwards photo and returns only ranked names and scores', async () => {
  const originalFetch = globalThis.fetch;
  try {
    globalThis.fetch = async (url, options) => {
      assert.equal(url.searchParams.get('api-key'), 'test-secret');
      const submitted = options.body.get('images');
      assert.equal(submitted.type, 'image/jpeg');
      return Response.json({
        version: 'test-model',
        results: [{ score: .91, species: {
          scientificNameWithoutAuthor: 'Hibiscus rosa-sinensis',
          commonNames: ['Chinese hibiscus'],
          family: { scientificNameWithoutAuthor: 'Malvaceae' },
        } }],
      });
    };
    const response = await worker.fetch(photoRequest(), {
      PLANTNET_API_KEY: 'test-secret',
      ...limits(),
    });
    assert.equal(response.status, 200);
    const data = await response.json();
    assert.equal(data.results[0].scientificName, 'Hibiscus rosa-sinensis');
    assert.equal(data.modelVersion, 'test-model');
    assert.equal(JSON.stringify(data).includes('test-secret'), false);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test('rejects a file that is not a photo', async () => {
  const body = new FormData();
  body.append('image', new Blob([new Uint8Array(200)]), 'bad.bin');
  const response = await worker.fetch(new Request('https://flora.example/identify', {
    method: 'POST', body,
  }), { PLANTNET_API_KEY: 'test-secret', ...limits() });
  assert.equal(response.status, 415);
});

test('stops requests when a rate limit is reached', async () => {
  const response = await worker.fetch(photoRequest(), {
    PLANTNET_API_KEY: 'test-secret',
    ...limits(false),
  });
  assert.equal(response.status, 429);
});

test('fails closed if a rate limiter is missing', async () => {
  const response = await worker.fetch(photoRequest(), {
    PLANTNET_API_KEY: 'test-secret',
  });
  assert.equal(response.status, 503);
});
