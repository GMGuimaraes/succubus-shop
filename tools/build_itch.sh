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
# 200 MB — medido nesta árvore: com textura sem perdas o `.pck` do navegador deu
# 207,33 MB e foi reprovado; depois de `tools/set_texture_budget.py` (WebP com
# perdas, q=0,85 opacas / q=0,92 com alfa) ele mede 43,47 MB. O `.wasm` custa
# 39,51 MB e é fixo, então o download total do build web ≈ 83 MB.
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
			local cmd estagio
			estagio="$(dirname "$destino")/stage"
			if command -v powershell.exe >/dev/null 2>&1; then cmd="powershell.exe"
			else cmd="pwsh"; fi
			rm -rf "$estagio"
			mkdir -p "$estagio"
			cp -r "$pasta_origem"/* "$estagio/"
			# PowerShell não entende caminho MSYS (`/d/...`): Compress-Archive responde
			# "não existe ou não é um caminho do sistema de arquivos válido" — e ainda devolve
			# 0, então o script seguia sem zip nenhum. Os caminhos são convertidos para o formato
			# do Windows quando o conversor existe (Git Bash), e o arquivo é conferido depois:
			# zip vazio tem de reprovar o build aqui, não estourar na página da itch.
			local cam_estagio="$estagio\\*" cam_destino="$destino"
			if command -v cygpath >/dev/null 2>&1; then
				cam_estagio="$(cygpath -w "$estagio")\\*"
				cam_destino="$(cygpath -w "$destino")"
			fi
			"$cmd" -NoProfile -Command "\$ErrorActionPreference='Stop'; Compress-Archive -Path '$cam_estagio' -DestinationPath '$cam_destino' -Force"
			rm -rf "$estagio"
			;;
	esac
	[ -s "$destino" ] || { echo "FALHA: '$destino' não foi gerado (zip ausente ou vazio)."; exit 1; }
	# `du` mede o que o disco ocupa, e com compressão transparente do NTFS ele devolve
	# menos do que o arquivo é: o .zip de mesa mediu "71M" no du e 82.623.209 bytes no
	# `stat`. O número que a itch mostra e o que o jogador baixa é o lógico, então é ele
	# que se imprime aqui.
	local bytes
	bytes="$(stat -c %s "$destino")"
	echo "  -> $destino ($bytes bytes, $(awk -v b="$bytes" 'BEGIN{printf "%.2f MB", b/1e6}'))"
}

# O `.zip` do alvo Linux nasce no Windows, e nem `Compress-Archive` nem o `zip` do MSYS
# gravam o bit de execução: medido com `zipinfo`, o binário saía `-rw----`, que no Linux é
# um arquivo que o jogador não consegue nem ler, quanto mais rodar. Python reescreve o
# atributo externo de cada entrada (sistema Unix, modo 0755) sem reempacotar o conteúdo.
marcar_execucao() {
	local destino="$1"
	if ! command -v python >/dev/null 2>&1; then
		echo "FALHA: preciso de python para gravar o modo de execução no .zip linux."
		exit 1
	fi
	python - "$destino" <<'PYEOF'
import os, sys, zipfile
src = sys.argv[1]
tmp = src + ".mode.tmp"
with zipfile.ZipFile(src) as zin, zipfile.ZipFile(tmp, "w", zipfile.ZIP_DEFLATED) as zout:
	for item in zin.infolist():
		info = zipfile.ZipInfo(item.filename, date_time=item.date_time)
		info.compress_type = item.compress_type
		info.create_system = 3  # 3 = Unix: unico sistema cujo modo o desempacotador respeita
		info.external_attr = (0o755 & 0xFFFF) << 16
		zout.writestr(info, zin.read(item.filename))
os.replace(tmp, src)
print("  modo unix 0755 gravado nas entradas de %s" % os.path.basename(src))
PYEOF
	[ -s "$destino" ] || { echo "FALHA: a reescrita de modo corrompeu '$destino'."; exit 1; }
}

preflight() {
	"$GODOT" --version >/dev/null 2>&1 || {
		echo "FALHA: não achei o Godot em '$GODOT'. Passe GODOT=/caminho/do/godot."
		exit 1
	}
	local versao_motor
	versao_motor="$("$GODOT" --version)"
	# A pasta de templates leva a versão CURTA (`4.7.2.stable`), o `--version` devolve a
	# build inteira (`4.7.2.stable.official.ed1daf0bf`). Comparar as duas direto é o falso
	# negativo que reprovava um build com templates já instalados — medido aqui: o export
	# web passava a mão enquanto o preflight dizia "não instalados".
	local versao_curta
	versao_curta="$(printf '%s' "$versao_motor" | cut -d. -f1-4)"
	# O lugar do template muda de plataforma: %APPDATA%\Godot no Windows,
	# ~/.local/share/godot no Linux. Os dois são procurados; nenhum é criado aqui.
	local achou=""
	for base in "${APPDATA:-}/Godot/export_templates" "$HOME/.local/share/godot/export_templates"; do
		if [ -n "$base" ] && [ -f "$base/$versao_curta/version.txt" ]; then
			achou="$base/$versao_curta"
		fi
	done
	if [ -z "$achou" ]; then
		echo "FALHA: templates de export não instalados para '$versao_curta'."
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
	# O exportador web exige a PASTA de destino já existente: `DirAccess::exists(base_dir)`
	# falha com "Target folder does not exist" e o export morre antes de escrever o primeiro
	# byte. Como o preset grava dentro de `.export/<alvo>/`, a pasta é criada aqui.
	local destino
	case "$preset" in
		"Windows Desktop") destino="$OUT_DIR/windows" ;;
		Linux) destino="$OUT_DIR/linux" ;;
		Web) destino="$OUT_DIR/web" ;;
		*) echo "FALHA: preset desconhecido '$preset'."; exit 1 ;;
	esac
	mkdir -p "$destino"
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
			marcar_execucao "$OUT_IT/Succubus-Shop-$SO_VERSAO-linux.zip"
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
	echo "$(stat -c %s "$local_zip" | awk '{printf "%.2f MB", $1/1e6}')  $(basename "$local_zip")"
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
