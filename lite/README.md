# WordCraft lite

Size/speed-tuned build of the WordCraft web app for embedding (single user:
editor, .docx, save to PDF). **No upstream source is modified** — everything
lives in `lite/` so the fork stays easy to sync with storytold/wordcraft.

## Build

```sh
lite/build.sh lite      # tuned build -> dist (thin LTO, opt-level s, strip, wasm-opt, .br/.gz)
lite/build.sh upstream  # stock build, for comparison
docker build -f lite/Dockerfile -t wordcraft-lite .   # nginx image serving precompressed files
```

`nginx.conf` serves `.wasm`/`.js` pre-compressed (brotli/gzip) with immutable
cache headers, and `index.html` with `no-cache`.

## Embedding (host page)

- Load `index.html?host=parent` in an iframe. **The parent must be the same
  origin** (serve it behind a reverse proxy, e.g. `/editor/`).
- Protocol: editor sends `wordcraft:ready`; host sends
  `{type:'wordcraft:open', name, bytes: Uint8Array}`; editor sends
  `wordcraft:save {name, saveAs, bytes}` (Ctrl+S) and `wordcraft:dirty`.
- **Export PDF:** the in-app File › Export › PDF button does nothing in host
  mode (save picker unavailable). Call
  `await iframe.contentWindow.wordcraft.execute('file.exportPdf', {})` from the
  host instead; the PDF bytes come back in the result and via `wordcraft:save`.
- **Thai fonts:** bundled fonts have no Thai glyphs. Before loading the iframe,
  put TTF files (e.g. Sarabun, OFL) in IndexedDB database `wordcraft`
  (version 1), object store `fonts`, key = file name, value = `Uint8Array`.
  The app loads them at startup and embeds them in PDFs.

## Measurements (2026-11-25, Chrome, Thai test doc with 30-row table)

| | upstream | lite |
|---|---|---|
| renderer RAM after opening doc | ~441 MB | ~366 MB |

WASM is 14.9 MB brotli. Code-size breakdown showed the removable parts
(ODF ~0.7 MB, extra image codecs ~2.7 MB, WebGPU/naga ~1.2 MB of 61 MB
unoptimised) are small and have no feature flags, so cutting them would need
upstream patches — not done.

Content controls with `w:lock contentLocked` are enforced and survive save.
Saved runs gain `<w:cs w:val="0"/>`; effect on Thai rendering in MS Word not
yet checked.
