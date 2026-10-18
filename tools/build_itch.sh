#!/usr/bin/env bash
# Build de publicação do Succubus Shop para a itch.io.
#
# Faz três exports e três .zip com a forma que a itch.io exige:
#   Windows  -> Succubus-Shop-<versao>-windows.zip   (pasta com o .exe dentro)
#   Linux    -> Succubus-Shop-<versao>-linux.zip     (pasta com o .x86_64 dentro)
#   Web      -> Succubus-Shop-<versao>-web.zip       (index.html NA RAIZ do zip)
#
# A raiz do zip web não é capricho: a itch.io descompacta o arquivo e procura
# index.html no topo. Um `web/index.html` dentro de uma pasta dá "Could not find
# index.html" na página do jogo. E nenhum arquivo descompactado pode passar de
# 200 MB — o `.pck` do navegador mede ~155 MB, então cabe, mas é o teto a
# vigiar quando a arte crescer.
#
# Uso:
#   GODOT="/c/Users/gmore/godot/godot" bash tools/build_itch.sh
#   GODOT=... bash tools/build_itch.sh --only web
#
# Este script NÃO baixa nada. Sem os templates de export instalados ele para na
# porta e diz o caminho de instalação, porque baixar ~1 GB sem pedir não é papel
# de um script de build.
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$PWD"

GODOT="${GODOT:-godot}"
OUT_DIR="$ROOT/.export"
OUT_IT="$ROOT/.export/itch"
SO_VERSAO="$(sed -n 's/^config\/version="\{0,1\}\([^"]*\)"\{0,1\}$/\1/p' project.godot)"
[ -n "$SO_VERSAO" ] || { echo "FALHA: project.godot não tem config/version."; exit 1; }
NOME="$(sed -n 's/^config\/name="\(.*\)"$/\1/p' project.godot)"

ZIP_ENGINE=""
if command -v zip >/dev/null 2>&1; then
	ZIP_ENGINE="zip"
elif command -v powershell.exe >/dev/null 2>&1 || command -v pwsh >/dev/null 2>&1; then
	ZIP_ENGINE="powershell"
else
	echo "FALHA: nem 'zip' nem PowerShell para montar os .zip."
	exit 1
fi

empacotar() {
	local destino="$1" pasta_origem="$2"
	rm -f "$destino"
	case "$ZIP_ENGINE" in
		zip) (cd "$pasta_origem" && zip -q -r -X "$destino" .) ;;
		powershell)
			local cmd
			if command -v powershell.exe >/dev/null 2>&1; then cmd="powershell.exe"
			else cmd="pwsh"; fi
			rm -rf "$(dirname "$destino")/stage"
			mkdir -p "$(dirname "$destino")/stage"
			cp -r "$pasta_origem"/* "$(dirname "$destino")/stage/"
			"$cmd" -NoProfile -Command "Compress-Archive -Path '$(dirname "$destino")/stage/*' -DestinationPath '$destino' -Force"
			rm -rf "$(dirname "$destino")/stage"
			;;
	esac
}

preflight() {
	"$GODOT" --version >/dev/null 2>&1 || {
		echo "FALHA: não achei o Godot em '$GODOT'. Passe GODOT=/caminho/do/godot."
		exit 1
	}
	local versao_motor
	versao_motor="$("$GODOT" --version)"
	# O lugar do template muda de plataforma: %APPDATA%\Godot no Windows,
	# ~/.local/share/godot no Linux. Os dois são procurados; nenhum é criado aqui.
	local achou=""
	for base in "${APPDATA:-}/Godot/export_templates" "$HOME/.local/share/godot/export_templates"; do
		[ -n "$base" ] && [ -d "$base/$versao_motor" ] && achou="$base/$versao_motor"
	done
	if [ -z "$achou" ]; then
		echo "FALHA: templates de export não instalados para '$versao_motor'."
		echo "       Instale no editor: Editor > Manage Export Templates > Download."
		echo "       (O script não baixa: é ~1 GB e a decisão é sua.)"
		exit 1
	fi
	echo "Godot $versao_motor • templates em $achou"
	echo "Projeto '$NOME' v$SO_VERSAO"
}

exportar() {
	local preset="$1"
	echo "── export: $preset ──"
	mkdir -p "$OUT_DIR"
	"$GODOT" --headless --path . --export-release "$preset" 2>&1 | tail -n 20
}

caso() {
	case "$1" in
		windows)
			exportar "Windows Desktop"
			empacotar "$OUT_IT/Succubus-Shop-$SO_VERSAO-windows.zip" "$OUT_DIR/windows"
			;;
		linux)
			exportar "Linux"
			empacotar "$OUT_IT/Succubus-Shop-$SO_VERSAO-linux.zip" "$OUT_DIR/linux"
			;;
		web)
			exportar "Web"
			empacotar "$OUT_IT/Succubus-Shop-$SO_VERSAO-web.zip" "$OUT_DIR/web"
			;;
	esac
}

SO_ALVO="windows linux web"
if [ "${1:-}" = "--only" ]; then
	SO_ALVO="$2"
	shift 2
fi

preflight
mkdir -p "$OUT_IT"

for alvo in $SO_ALVO; do
	caso "$alvo"
done

echo
echo "── verificação de forma ──"
for alvo in $SO_ALVO; do
	local_zip="$OUT_IT/Succubus-Shop-$SO_VERSAO-$alvo.zip"
	[ -f "$local_zip" ] || { echo "QUEBRA: falta $local_zip"; continue; }
	echo "$(du -h "$local_zip" | cut -f1)  $(basename "$local_zip")"
done

if [ -f "$OUT_IT/Succubus-Shop-$SO_VERSAO-web.zip" ]; then
	if command -v unzip >/dev/null 2>&1; then
		unzip -l "$OUT_IT/Succubus-Shop-$SO_VERSAO-web.zip" | awk 'NF==4 && $4!~/^\// {print "   "$4}' | head
		unzip -l "$OUT_IT/Succubus-Shop-$SO_VERSAO-web.zip" | grep -q " index.html$" \
			&& echo "   index.html está na raiz ✓" \
			|| echo "   QUEBRA: index.html não está na raiz do zip web"
	fi
fi

echo
echo "Pronto. Suba os .zip em https://itch.io/game/new > Files, e marque o de web"
echo "como 'Played in the browser'. A copy da página está em docs/itch-io.md."
