#!/usr/bin/env bash
# WordCraft lite: build the web app with size/speed tuned settings, without touching upstream files.
#
# Usage (inside the builder image, from the repo root):  lite/build.sh [lite|upstream]
#   lite      fat LTO + 1 codegen unit (default)
#   upstream  the repo's own [profile.release] as-is (for comparison)
# Output: dist/web-<mode>/  plus .br / .gz copies of the big files.
set -euo pipefail
MODE="${1:-lite}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$ROOT/dist/web-$MODE"

if [[ "$MODE" == "lite" ]]; then
  # Overrides Cargo.toml [profile.release] through env vars, so the upstream file stays untouched.
  export CARGO_PROFILE_RELEASE_LTO="${LITE_LTO:-thin}"
  export CARGO_PROFILE_RELEASE_CODEGEN_UNITS=1
  export CARGO_PROFILE_RELEASE_OPT_LEVEL="${LITE_OPT_LEVEL:-s}"
  export CARGO_PROFILE_RELEASE_STRIP=symbols
fi
export CARGO_TARGET_DIR="${CARGO_TARGET_DIR:-$ROOT/target-$MODE}"

cd "$ROOT/apps/wordcraft-web"
# Rust >= 1.87 emits bulk-memory / sign-ext ops by default; trunk's wasm-opt needs them enabled.
# Make a throwaway copy of upstream's index.html with those flags (never committed, upstream untouched).
sed 's|data-wasm-opt="z"|data-wasm-opt="z" data-wasm-opt-params="--enable-bulk-memory --enable-bulk-memory-opt --enable-nontrapping-float-to-int --enable-sign-ext --enable-mutable-globals --enable-reference-types --enable-multivalue"|' \
  index.html > index.lite.html
trap 'rm -f "$ROOT/apps/wordcraft-web/index.lite.html"' EXIT
trunk build --release --dist "$OUT" index.lite.html
[[ -f "$OUT/index.lite.html" ]] && mv "$OUT/index.lite.html" "$OUT/index.html"

# Pre-compress for nginx (stock nginx serves .gz via gzip_static; .br via the map in nginx.conf).
find "$OUT" -type f \( -name '*.wasm' -o -name '*.js' -o -name '*.html' -o -name '*.css' \) -print0 |
  while IFS= read -r -d '' f; do
    brotli -f -q 11 -k "$f"
    gzip -f -9 -k "$f"
  done

echo "== $MODE =="
ls -l "$OUT"
