#!/usr/bin/env bash
# Build de publicação do Succubus Shop para a itch.io.
#
# Faz seis exports e os .zip com a forma que a itch.io exige:
#   Windows    -> Succubus-Shop-<versao>-windows.zip      (pasta com o .exe dentro)
#   Linux      -> Succubus-Shop-<versao>-linux.zip        (pasta com o .x86_64 dentro)
#   Linux ARM  -> Succubus-Shop-<versao>-linux-arm64.zip  (pasta com o .arm64 dentro)
#   Web        -> Succubus-Shop-<versao>-web.zip          (index.html NA RAIZ do zip)
#   Android    -> succubus-shop-<versao>-arm64.apk        (.apk solto, assinado aqui fora)
#   macOS      -> Succubus-Shop-<versao>-macos.zip        (o .app ja vem zipado do exportador)
#
# Linux e escolhido por ARQUITETURA, nao por distro: o x86_64 publicado roda em qualquer distro
# x86_64 (Debian/Ubuntu, Fedora, Arch, openSUSE, Steam Deck). A linha arm64 cobre o que sobrava,
# que e processador ARM de 64 bits. macOS sai do Windows sem Mac nenhum -- o que exige macOS e
# Xcode e a assinatura de Developer ID e a notarizacao, e este build e ad-hoc sem elas. iOS exige
# o Mac para existir; ver docs/itch-io.md §14.
#
# O Android não vai em .zip de propósito: a itch.io lê a extensão para marcar a plataforma
# e um `.zip` virou "Downloadable" sem o selo de Android. E ele não é assinado pelo Godot:
# `--export-release` de linha de comando não tem como pedir a senha do keystore (a janela do
# editor é a única que pergunta), então o export chega até "Assinando APK de lançamento",
# avisa "O keystore de lançamento não foi encontrado" e morre -- deixando um APK completo e
# sem assinatura nenhuma. Assinar aqui, com o keystore FORA do repo e a senha vinda do
# ambiente, é o que mantém a senha fora do `export_presets.cfg` versionado.
#
# Uso do alvo Android (senha nunca aparece na linha de comando, só no ambiente):
#   SS_KEYSTORE="D:/android-dev/keystores/succubus-shop-release.keystore" \
#   SS_KEYSTORE_PASS="$(cat D:/android-dev/keystores/succubus-shop-release.password)" \
#   GODOT=/c/Users/gmore/godot/godot bash tools/build_itch.sh --only android
#
# A raiz do zip web não é capricho: a itch.io descompacta o arquivo e procura
# index.html no topo. Um `web/index.html` dentro de uma pasta dá "Could not find
# index.html" na página do jogo. E nenhum arquivo descompactado pode passar de
# 200 MB — medido nesta árvore: com textura sem perdas o `.pck` do navegador deu
# 207,33 MB e foi reprovado; depois de `tools/set_texture_budget.py` (WebP com
# perdas por classe, q=0,85 opacas / q=0,92 com alfa) ele mede 43,47 MB, e 48,61 MB com as
# duas fontes de símbolo do §8 de docs/itch-io.md dentro -- e 48,05 MB depois que o
# `exclude_filter` tirou as sondas de desenvolvimento do pacote do jogador; com o MP3 da
# trilha clássica de volta (§10) são 50,26 MB. O `.wasm` custa
# 39,51 MB e é fixo; o zip final do navegador mede 60,01 MB.
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
# O caminho gravado em `export_path` no preset Android. `exportar` confere que ele existe
# depois do export, e `assinar_android` é quem lê este arquivo.
APK_ANDROID="$OUT_DIR/android/succubus-shop-arm64.apk"
ANDROID_APK=""

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
	# menos do que o arquivo é: o .zip de mesa mediu "71M" no du e 82.098.382 bytes no
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
	# O `empacotar` de cima anunciou o tamanho dele; esta reescrita é um novo arquivo
	# (Python recomprime tudo) e o número que a itch.io e o README citam é o deste, final.
	local bytes
	bytes="$(stat -c %s "$destino")"
	echo "  -> tamanho final apos o modo unix: $destino ($bytes bytes, $(awk -v b="$bytes" 'BEGIN{printf "%.2f MB", b/1e6}'))"
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
	TEMPLATES_DIR="$achou"
	echo "Godot $versao_motor • templates em $achou"
	echo "Projeto '$NOME' v$SO_VERSAO"
}

exportar() {
	local preset="$1"
	# `version.txt` existe em cópia parcial de template e o preflight passa: medido aqui,
	# com APPDATA apontando para o tmp de sonda, o web tinha os `.zip` mas faltavam os
	# `.exe` de mesa, e o export morria no meio da cadeia depois de importar tudo.
	# A conta é feita pelo arquivo que cada preset realmente exige.
	local molde
	case "$preset" in
		"Windows Desktop") molde="windows_release_x86_64.exe" ;;
		Linux) molde="linux_release.x86_64" ;;
		"Linux (arm64)") molde="linux_release.arm64" ;;
		macOS) molde="macos.zip" ;;
		Web) molde="web_nothreads_release.zip" ;;
		Android) molde="android_release.apk" ;;
		*) echo "FALHA: preset desconhecido '$preset'."; exit 1 ;;
	esac
	if [ ! -f "$TEMPLATES_DIR/$molde" ]; then
		echo "FALHA: falta o molde '$molde' em $TEMPLATES_DIR."
		echo "       Ou APPDATA está apontando para uma cópia parcial de templates,"
		echo "       ou os templates deste alvo não foram instalados."
		exit 1
	fi
	echo "── export: $preset (molde $molde) ──"
	# O exportador web exige a PASTA de destino já existente: `DirAccess::exists(base_dir)`
	# falha com "Target folder does not exist" e o export morre antes de escrever o primeiro
	# byte. Como o preset grava dentro de `.export/<alvo>/`, a pasta é criada aqui.
	local destino
	case "$preset" in
		"Windows Desktop") destino="$OUT_DIR/windows" ;;
		Linux) destino="$OUT_DIR/linux" ;;
		"Linux (arm64)") destino="$OUT_DIR/linux-arm64" ;;
		macOS) destino="$OUT_DIR/macos" ;;
		Web) destino="$OUT_DIR/web" ;;
		Android) destino="$OUT_DIR/android" ;;
		*) echo "FALHA: preset desconhecido '$preset'."; exit 1 ;;
	esac
	mkdir -p "$destino"
	"$GODOT" --headless --path . --export-release "$preset" 2>&1 | tail -n 20
	# A porta de conferência era uma linha fixa no `.apk` do Android e valia para TODO preset
	# — defeito latente medido em 2026-10-20: os `.zip` de mesa da alpha.6 são das 12:34 e o
	# gate entrou no script às 15:57, então nenhum build de mesa passou por ele. O arquivo
	# esperado agora é lido do próprio `export_path` do preset: fonte única, sem tabela para
	# envelhecer. O export Android escreve o APK e SO DEPOIS reclama da assinatura; com
	# `package/signed=false` no preset ele termina em 0 e entrega o arquivo alinhado, sem
	# assinatura, e `assinar_android` é quem fecha a conta com o keystore de verdade.
	local export_path
	export_path="$(awk -v want="$preset" '
		/^name=/        { n = $0; sub(/^name="/, "", n); sub(/"$/, "", n) }
		/^export_path=/ { p = $0; sub(/^export_path="/, "", p); sub(/"$/, "", p)
		              if (n == want) { print p; exit } }
	' export_presets.cfg)"
	[ -n "$export_path" ] || { echo "FALHA: preset '$preset' não tem export_path no cfg."; exit 1; }
	EXPORT_PATH="$destino/$(basename "$export_path")"
	[ -e "$EXPORT_PATH" ] || {
		echo "FALHA: o export de '$preset' não deixou '$EXPORT_PATH'."
		exit 1
	}
	echo "  export: $EXPORT_PATH"
}

# Assinatura de release do Android, feita fora do Godot (ver o cabecalho do script).
# A senha entra pelo ambiente e nunca pela linha de comando: `--ks-pass env:` lee a
# variavel dentro do processo, e nothing dela vai para o log nem para o repo.
assinar_android() {
	local bt="${ANDROID_BUILD_TOOLS:-D:/android-dev/sdk/build-tools/35.0.0}"
	[ -f "$bt/zipalign.exe" ] || { echo "FALHA: falta zipalign em $bt (instale build-tools no SDK)."; exit 1; }
	[ -f "$bt/apksigner.bat" ] || { echo "FALHA: falta apksigner em $bt."; exit 1; }
	[ -n "${SS_KEYSTORE:-}" ] && [ -f "$SS_KEYSTORE" ] || {
		echo "FALHA: SS_KEYSTORE não aponta para um keystore."
		echo "       SS_KEYSTORE=<caminho.keystore> SS_KEYSTORE_PASS=<senha> bash tools/build_itch.sh --only android"
		echo "       A senha fica no ambiente da pessoa, não no export_presets.cfg versionado."
		exit 1
	}
	[ -n "${SS_KEYSTORE_PASS:-}" ] || { echo "FALHA: SS_KEYSTORE_PASS ausente."; exit 1; }
	local alinhado="$APK_ANDROID.aligned"
	local destino="$OUT_IT/succubus-shop-$SO_VERSAO-arm64.apk"
	rm -f "$destino"
	"$bt/zipalign.exe" -f -p 4 "$APK_ANDROID" "$alinhado" || { echo "FALHA: zipalign."; exit 1; }
	"$bt/apksigner.bat" sign \
		--ks "$SS_KEYSTORE" \
		--ks-key-alias "${SS_KEY_ALIAS:-succubus-shop}" \
		--ks-pass env:SS_KEYSTORE_PASS \
		--key-pass env:SS_KEYSTORE_PASS \
		--out "$destino" "$alinhado" || { echo "FALHA: apksigner sign."; exit 1; }
	rm -f "$alinhado" "${destino}.idsig"
	# O veredito é a assinatura lida de volta, não o código de saída do comando anterior:
	# um APK que o jogador não instala por culpa de um keystore errado é a pior surpresa
	# possível, e `verify --print-certs` é o que prova que quem assinou foi o nosso par.
	echo "── apksigner verify ──"
	"$bt/apksigner.bat" verify --print-certs "$destino" 2>&1 | grep -E "^Verified|Signer #1 certificate DN" | sed 's/^/   /'
	local bytes
	bytes="$(stat -c %s "$destino")"
	echo "  -> $destino ($bytes bytes, $(awk -v b="$bytes" 'BEGIN{printf "%.2f MB", b/1e6}'))"
	ANDROID_APK="$destino"
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
		linux-arm64)
			exportar "Linux (arm64)"
			empacotar "$OUT_IT/Succubus-Shop-$SO_VERSAO-linux-arm64.zip" "$OUT_DIR/linux-arm64"
			marcar_execucao "$OUT_IT/Succubus-Shop-$SO_VERSAO-linux-arm64.zip"
			;;
		macos)
			# Quem produz o .zip aqui e o proprio exportador do Godot -- e nao `empacotar`:
			# medido no zip do export, as entradas ja nascem com sistema Unix e o binario com
			# modo 0755, que e justamente o que se perde quando o alvo e um .app solto saido
			# do Windows ("Projects exported as .zip are not affected by this issue", doc
			# oficial). Reempacotar daqui seria trocar o cuidado do motor pelo nosso.
			exportar "macOS"
			local zip_macos="$OUT_IT/Succubus-Shop-$SO_VERSAO-macos.zip"
			cp -f "$EXPORT_PATH" "$zip_macos"
			command -v python >/dev/null 2>&1 || {
				echo "FALHA: preciso de python para conferir o bundle de macOS."
				exit 1
			}
			python tools/check_macho_fat.py "$zip_macos" || exit 1
			local bytes
			bytes="$(stat -c %s "$zip_macos")"
			echo "  -> $zip_macos ($bytes bytes, $(awk -v b="$bytes" 'BEGIN{printf "%.2f MB", b/1e6}'))"
			;;
		web)
			exportar "Web"
			empacotar "$OUT_IT/Succubus-Shop-$SO_VERSAO-web.zip" "$OUT_DIR/web"
			;;
		android)
			exportar "Android"
			assinar_android
			;;
	esac
}

SO_ALVO="windows linux linux-arm64 web android macos"
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
	if [ "$alvo" = "android" ]; then
		# O alvo Android não é um .zip: é o .apk assinado, conferido pelo nome real.
		[ -n "$ANDROID_APK" ] && [ -f "$ANDROID_APK" ] \
			&& echo "$(stat -c %s "$ANDROID_APK" | awk '{printf "%.2f MB", $1/1e6}')  $(basename "$ANDROID_APK")" \
			|| echo "QUEBRA: nenhum .apk assinado gerado"
		continue
	fi
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
