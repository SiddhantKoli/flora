# FLORA cloud plant suggestions

This Cloudflare Worker keeps the Pl@ntNet API key off the phone. FLORA sends a
camera capture only after the user taps **Find plant suggestions**. The Worker
forwards the photo to Pl@ntNet, returns up to five names and scores, and does
not save the image. The journal stays on the phone.

Pl@ntNet currently advertises [87,000+ identifiable species and a free plan of
500 identifications per day](https://my.plantnet.org/). Its API may reject a
non-plant photo. Cloudflare Workers' [free plan has 100,000 requests per day](https://developers.cloudflare.com/workers/platform/limits/), so the Pl@ntNet
quota is the practical limit. These are service limits, not FLORA guarantees.

## Deploy

1. Create a free [Pl@ntNet API account](https://my.plantnet.org/) and copy its
   API key. Create a free Cloudflare account.
2. In this directory, run `npx wrangler login` and `npx wrangler deploy`.
3. Run `npx wrangler secret put PLANTNET_API_KEY` and paste the key at the
   private prompt. Do not add it to Git or the Flutter app.
4. Build FLORA with the deployed Worker URL:

   ```sh
   flutter build apk --debug --dart-define=FLORA_IDENTIFY_ENDPOINT=https://flora-plant-suggestions.YOUR-SUBDOMAIN.workers.dev
   ```

The Worker URL must point to the root of this Worker; the app adds `/identify`.
`GET /health` reports whether the key is configured without exposing it. For
local development, use `npx wrangler dev`, add `PLANTNET_API_KEY` to a local
`.dev.vars` file, and use an emulator-accessible endpoint. Keep `.dev.vars` out
of Git.

## Limits and privacy

- A photo is uploaded only when the user requests suggestions. The unfiltered
  original capture is used so creative camera looks do not alter the model input.
- The Worker accepts JPEG or PNG files up to 10 MB, does not persist them, and
  returns only names, family, score, and model version. Pl@ntNet says uploaded
  photos are used in memory for identification and not stored.
- This open endpoint can have its shared free quota exhausted by misuse. Add
  Cloudflare rate limiting and abuse controls before a public launch. Never
  ship the upstream API key in the APK.
- The app works without this service: manual naming and Unknown remain
  available. A model suggestion is not a verified identification.

## Test

`node --test test/index.test.mjs` checks upload validation, key isolation, and
response mapping with a mocked upstream. A live Pl@ntNet call needs your key.
