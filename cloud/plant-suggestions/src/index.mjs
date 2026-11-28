const MAX_IMAGE_BYTES = 10 * 1024 * 1024;

function json(body, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      'content-type': 'application/json; charset=utf-8',
      'cache-control': 'no-store',
      'x-content-type-options': 'nosniff',
    },
  });
}

export function normalizeResult(result) {
  const species = result?.species ?? {};
  return {
    scientificName: species.scientificNameWithoutAuthor ?? '',
    commonName: species.commonNames?.[0] ?? '',
    family: species.family?.scientificNameWithoutAuthor ?? '',
    score: typeof result?.score === 'number' ? result.score : 0,
  };
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (url.pathname === '/health' && request.method === 'GET') {
      return json({ status: 'ok', configured: Boolean(env.PLANTNET_API_KEY) });
    }
    if (url.pathname !== '/identify' || request.method !== 'POST') {
      return json({ error: 'Not found' }, 404);
    }
    if (!env.PLANTNET_API_KEY) {
      return json({ error: 'Identification is not configured' }, 503);
    }
    if (!env.CLIENT_LIMIT || !env.GLOBAL_LIMIT) {
      return json({ error: 'Identification is not configured' }, 503);
    }
    try {
      const ip = request.headers.get('cf-connecting-ip') ?? 'unknown';
      const [client, global] = await Promise.all([
        env.CLIENT_LIMIT.limit({ key: ip }),
        env.GLOBAL_LIMIT.limit({ key: 'all-identifications' }),
      ]);
      if (!client.success || !global.success) {
        return json({ error: 'Please wait before trying another photo' }, 429);
      }
    } catch {
      return json({ error: 'Identification is temporarily unavailable' }, 503);
    }
    const length = Number(request.headers.get('content-length'));
    if (Number.isFinite(length) && length > MAX_IMAGE_BYTES + 10000) {
      return json({ error: 'Photo is too large' }, 413);
    }
    if (!(request.headers.get('content-type') ?? '').startsWith('multipart/form-data')) {
      return json({ error: 'Expected a photo upload' }, 415);
    }

    let image;
    try {
      const form = await request.formData();
      image = form.get('image');
    } catch {
      return json({ error: 'Could not read photo' }, 400);
    }
    if (!image || typeof image.arrayBuffer !== 'function' ||
        image.size < 100 || image.size > MAX_IMAGE_BYTES) {
      return json({ error: 'Photo must be between 100 bytes and 10 MB' }, 400);
    }
    const signature = new Uint8Array(await image.slice(0, 8).arrayBuffer());
    const jpeg = signature[0] === 0xff && signature[1] === 0xd8;
    const png = signature[0] === 0x89 && signature[1] === 0x50 &&
      signature[2] === 0x4e && signature[3] === 0x47;
    if (!jpeg && !png) {
      return json({ error: 'Only JPEG or PNG photos are supported' }, 415);
    }

    const upstream = new FormData();
    upstream.append('images',
      new Blob([image], { type: jpeg ? 'image/jpeg' : 'image/png' }),
      jpeg ? 'plant.jpg' : 'plant.png');
    const target = new URL('https://my-api.plantnet.org/v2/identify/all');
    target.searchParams.set('api-key', env.PLANTNET_API_KEY);
    target.searchParams.set('nb-results', '5');
    target.searchParams.set('lang', 'en');
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 30000);
    try {
      const response = await fetch(target, {
        method: 'POST',
        body: upstream,
        signal: controller.signal,
      });
      if (response.status === 404) return json({ error: 'No plant match' }, 404);
      if (response.status === 429) return json({ error: 'Daily limit reached' }, 429);
      if (!response.ok) return json({ error: 'Identification unavailable' }, 502);
      const data = await response.json();
      return json({
        results: (Array.isArray(data.results) ? data.results : [])
          .slice(0, 5).map(normalizeResult),
        modelVersion: data.version ?? '',
      });
    } catch {
      return json({ error: 'Identification unavailable' }, 502);
    } finally {
      clearTimeout(timeout);
    }
  },
};
