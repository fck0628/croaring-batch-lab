#!/bin/sh
# Linux dependencies: ffmpeg with libass, python3 with fontTools, and DejaVu Sans.
set -eu
src=$(CDPATH='' cd "$(dirname "$0")" && pwd)
out=$(mktemp -d)
cd "$out"
echo "Generated clips and hashes: $out"
cp "$src/test.ass" .
cp "${DEJAVU_FONT:-/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf}" good.ttf
python3 - <<'PY'
from fontTools.ttLib import TTFont
font = TTFont("good.ttf")
replacement = font.getBestCmap()[ord("x")]
for table in font["cmap"].tables:
    if table.isUnicode() and ord("o") in table.cmap:
        table.cmap[ord("o")] = replacement
font.save("bad.ttf")
PY
for f in good bad; do
  ffmpeg -nostdin -v error -f lavfi -i color=s=320x180:r=5:d=1 -i test.ass \
    -map 0:v -map 1:s -c:v ffv1 -c:s ass -attach "$f.ttf" \
    -metadata:s:t:0 mimetype=application/x-truetype-font \
    -metadata:s:t:0 filename=poster-bold.ttf "$f.mkv"
done
d=$(mktemp -d)
trap 'rm -rf "$d"' EXIT
mkdir "$d/empty"
printf '<fontconfig><dir>%s/empty</dir><cachedir>%s/cache</cachedir></fontconfig>' "$d" "$d" > "$d/fonts.conf"
for f in good bad; do
  FONTCONFIG_FILE="$d/fonts.conf" ffmpeg -nostdin -i "$f.mkv" -vf "subtitles=$f.mkv" -an -f framemd5 "$f.md5" 2>"$d/$f.log"
  grep 'fontselect:' "$d/$f.log"
  awk '/^0,/{print $NF}' "$f.md5" > "$d/$f.frames"
done
paste "$d/good.frames" "$d/bad.frames" | awk 'NF != 2 {exit 1} {if ($1 != $2) n++} END {print n+0, "of", NR, "frames differ"; if (n!=5 || NR!=5) exit 1}'
