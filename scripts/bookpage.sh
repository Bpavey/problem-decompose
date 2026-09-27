#!/usr/bin/env bash
# bookpage.sh — 取书页文本 / 渲图（book_decompose 与 problem_decompose 的取材用）
#
# 用法:
#   bookpage.sh text <pdf> <first-page> [last-page]     # 打印这些 PDF 页的文本（保留版式）
#   bookpage.sh img  <pdf> <page> [top%] [bottom%]      # 300dpi 渲染该页，可按纵向百分比裁剪
#
# 提示: PDF 页码 = 印刷页码 + offset；offset 因书而异，先试后验（GT Ch.7–9 为 +13）。
set -euo pipefail
mode=${1:?usage: bookpage.sh text|img <pdf> <page> [..]}
pdf=${2:?pdf path}
shift 2
case "$mode" in
  text)
    first=${1:?first page}; last=${2:-$first}
    pdftotext -layout -f "$first" -l "$last" "$pdf" -
    ;;
  img)
    page=${1:?page}; top=${2:-0}; bot=${3:-100}
    base=/tmp/bookpage-$page
    pdftoppm -r 300 -f "$page" -l "$page" -png "$pdf" "$base"
    png=$(ls ${base}*.png | head -1)
    if python3 -c 'import PIL' 2>/dev/null && [ "$top" != "0" -o "$bot" != "100" ]; then
      python3 - "$png" "$top" "$bot" <<'PY'
import sys
from PIL import Image
f, top, bot = sys.argv[1], float(sys.argv[2]), float(sys.argv[3])
im = Image.open(f); w, h = im.size
out = f[:-4] + f"-crop{int(top)}-{int(bot)}.png"
im.crop((0, int(h*top/100), w, int(h*bot/100))).save(out)
print(out)
PY
    else
      echo "$png"
    fi
    ;;
  *) echo "mode must be text|img" >&2; exit 2 ;;
esac
