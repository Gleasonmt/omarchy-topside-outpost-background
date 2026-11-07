#!/bin/bash
# Check this live background before it ships (run by CI on every pull request):
#   - the scene in src/ compiles
#   - live/<name>.frag.qsb has the GLSL variants Omarchy needs (300 es for
#     OpenGL ES drivers such as NVIDIA's, 120 and 150 for desktop GL), each
#     passing a strict compile, and no 100 es variant (NVIDIA rejects it)
#   - it matches src/ (a warning only: another Qt version may build it differently)
#   - the still and the JSON files the plugin reads are there and valid
# Needs qt6-shadertools, glslang and jq.
set -uo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
QSB=${QSB:-/usr/lib/qt6/bin/qsb}
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
fail=0
err() { echo "::error::$*"; fail=1; }
ok() { echo "ok: $*"; }

src=$(ls "$ROOT"/src/*.frag 2>/dev/null | head -1)
[[ -n $src ]] || { err "no shader in src/"; exit 1; }
name=$(basename "$src" .frag)
qsb=$ROOT/live/$name.frag.qsb

# The scene compiles (assembled the way tools/build.sh does it)
t=$(sed -n 's|^// still: *\([0-9.]*\).*|\1|p' "$src" | head -1); t=${t:-20}
{ grep '^#version' "$ROOT/src/common.glsl"; echo "#define STILL_TIME $t"; grep -v '^#version' "$ROOT/src/common.glsl"; cat "$src"; } >"$TMP/$name.frag"
if "$QSB" --glsl "300 es,120,150" --hlsl 50 --msl 12 -o "$TMP/fresh.qsb" "$TMP/$name.frag" >"$TMP/qsb.log" 2>&1; then
  ok "src/$name.frag compiles"
else
  cat "$TMP/qsb.log"; err "src/$name.frag doesn't compile"
fi

# The committed shader pack
if [[ ! -f $qsb ]]; then
  err "live/$name.frag.qsb is missing (run tools/build.sh)"
else
  for v in 300es 120 150; do
    if ! "$QSB" -x "glsl,$v" -o "$TMP/$v.frag" "$qsb" >/dev/null 2>&1; then
      err "live/$name.frag.qsb has no GLSL $v variant (run tools/build.sh)"
    elif glslangValidator -S frag "$TMP/$v.frag" >"$TMP/glslang.log" 2>&1; then
      ok "GLSL $v variant passes a strict compile"
    else
      grep -E 'ERROR' "$TMP/glslang.log" | head -5; err "the GLSL $v variant of live/$name.frag.qsb fails a strict compile"
    fi
  done
  if "$QSB" -x "glsl,100es" -o "$TMP/100es.frag" "$qsb" >/dev/null 2>&1; then
    err "live/$name.frag.qsb has a GLSL 100 es variant: Qt picks it on OpenGL ES and NVIDIA rejects it (build with --glsl \"300 es,120,150\")"
  fi
  if [[ -f $TMP/fresh.qsb ]] && "$QSB" -x "glsl,300es" -o "$TMP/fresh300.frag" "$TMP/fresh.qsb" >/dev/null 2>&1 \
     && ! cmp -s "$TMP/300es.frag" "$TMP/fresh300.frag"; then
    echo "::warning::live/$name.frag.qsb doesn't match src/ as built here: run tools/build.sh and commit the result (ignore if only the Qt version differs)"
  fi
fi

# What the plugin reads
[[ -f $ROOT/backgrounds/$name.png ]] && ok "backgrounds/$name.png" || err "backgrounds/$name.png is missing"
for j in "$ROOT/live/$name.json" "$ROOT/live/mode.json"; do
  jq -e . "$j" >/dev/null 2>&1 && ok "${j#$ROOT/} is valid JSON" || err "${j#$ROOT/} is missing or not valid JSON"
done
if [[ -f $ROOT/live/$name.json ]]; then
  while IFS= read -r f; do
    [[ -z $f ]] && continue
    [[ $f != */* && -f $ROOT/live/$f ]] && ok "live/$f" || err "live/$name.json names live/$f, which is missing"
  done < <(jq -r '[.plate, .video, (.layers // [])[]] | map(select(. != null and . != "")) | .[]' "$ROOT/live/$name.json" 2>/dev/null)
fi

exit $fail
