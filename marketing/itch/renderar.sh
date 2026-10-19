#!/usr/bin/env bash
# Renderiza as capas da itch.io a partir de capa.html usando o Chrome headless.
# Uso:  bash marketing/itch/renderar.sh
# Requer: Google Chrome (ou Edge) instalado. Não toca no res:// nem no export.
set -euo pipefail

AQUI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAIDA="$AQUI/out"
CHROME=""
for c in \
  "/c/Program Files/Google/Chrome/Application/chrome.exe" \
  "/c/Program Files (x86)/Google/Chrome/Application/chrome.exe" \
  "/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe"; do
  [ -x "$c" ] && CHROME="$c" && break
done
[ -n "$CHROME" ] || { echo "Chrome/Edge nao encontrado"; exit 1; }

mkdir -p "$SAIDA"
# O Chrome nao aceita caminho estilo /tmp do Git Bash, nem "file:///d/...": usa o caminho Windows.
PERFIL="$(cygpath -w "$SAIDA/.chrome-perfil")"
PAGINA="file:///$(cygpath -m "$AQUI")/capa.html"

# variante idioma largura altura [extensao]  -- padrao png
# As oito ultimas linhas sao as medidas fixas da vitrine da Epic Games Store, nas
# duas linguas que a loja exige (ingles e o padrao do produto): 2560x1440 (uso
# geral), 1920x1080 (carrossel), 1200x1600 (retrato) e 1200x1200 (previa social).
# Elas saem em jpg porque o PNG de 2560x1440 pesa 4,36 MB e o teto da Epic para
# imagem de vitrine e 4 MB; o jpg do mesmo quadro sao ~450 KB com o texto nitido.
# A GOG pede key art a 1920x1080, mas em PSD com camadas -- o que o HTML nao produz
# de jeito nenhum.
TABELA="
A pt 625 322
A pt 690 415
A pt 1280 720
A en 625 322
A en 1280 720
B pt 625 322
B pt 1280 720
C pt 625 322
C pt 1280 720
A pt 2560 1440 jpg
A pt 1920 1080 jpg
A en 1920 1080 jpg
A en 2560 1440 jpg
A en 1200 1600 jpg
A en 1200 1200 jpg
A pt 1200 1600 jpg
A pt 1200 1200 jpg
"

echo "$TABELA" | while read -r V L W H EXT; do
  [ -z "${V:-}" ] && continue
  EXT="${EXT:-png}"
  NOME="capa-${V}-${L}-${W}x${H}.${EXT}"
  "$CHROME" --headless=new --disable-gpu --no-sandbox --hide-scrollbars \
    --force-device-scale-factor=1 --window-size="${W},${H}" --virtual-time-budget=8000 \
    --user-data-dir="$PERFIL" \
    --screenshot="$SAIDA/$NOME" \
    "${PAGINA}?v=${V}&lang=${L}&w=${W}&h=${H}" >/dev/null 2>&1
  if [ -f "$SAIDA/$NOME" ]; then
    printf '  ok  %s  %s\n' "$NOME" "$(du -h "$SAIDA/$NOME" | cut -f1)"
  else
    printf '  FALHOU  %s\n' "$NOME"
  fi
done

rm -rf "$PERFIL"
