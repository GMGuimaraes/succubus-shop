#!/usr/bin/env bash
# Harness preto-e-branco: sobe um servidor loopback de um skill, prova cada ramo
# (incluindo o de erro) e derruba o servidor na mesma chamada de shell.
set -uo pipefail

SERVER_LAUNCH="${SERVER_LAUNCH:?defina SERVER_LAUNCH='node /caminho/srv.cjs --dir \"\$VERIFY_IN\" --out \"\$VERIFY_OUT\"'}"
READY_PREFIX="${READY_PREFIX:-READY port=}"
SHUTDOWN_URL_PATH="${SHUTDOWN_URL_PATH:-/shutdown}"
MAX_BYTES="${MAX_BYTES:-40}"
REQUIRE_PRIVATE_NETWORK="${REQUIRE_PRIVATE_NETWORK:-1}"
KEEP_TMP="${KEEP_TMP:-0}"

PASS=0; FAIL=0; SRV_PID=""
chk() { # chk <rotulo> <espera> <obtido>
  if [[ "$3" == *"$2"* ]]; then PASS=$((PASS+1)); printf 'PASS %-26s %s\n' "$1" "$3"
  else FAIL=$((FAIL+1)); printf 'FAIL %-26s esperado=[%s] obtido=[%3$s]\n' "$1" "$2"; fi
}
fail_hard() { printf 'ABORT: %s\n' "$1"; limpar; exit 2; }

limpar() {
  [[ -n "$SRV_PID" ]] && kill "$SRV_PID" 2>/dev/null
  if [[ "$KEEP_TMP" != 1 && -n "${TMP_ROOT:-}" && "$TMP_ROOT" == *"_http_verify_"* ]]; then
    rm -rf "$TMP_ROOT" && printf 'cleanup      %s removido\n' "$TMP_ROOT"
  fi
}
trap limpar EXIT

# pasta de trabalho dentro do cwd, com caminho que o node do Windows entenda
WIN_CWD="$(pwd -W 2>/dev/null || pwd)"
TMP_ROOT="$WIN_CWD/_http_verify_$$"
IN="$TMP_ROOT/in"; OUT="$TMP_ROOT/out"; LOG="$TMP_ROOT/srv.log"
mkdir -p "$IN" "$OUT" || fail_hard "nao consegui criar $TMP_ROOT"

# fixtures: PNG valido (base64 embarcado), corpo abaixo e acima do limite
node -e '
const fs=require("fs");
const png=Buffer.from("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==","base64");
fs.writeFileSync(process.argv[1]+"/cena.png",png);
fs.writeFileSync(process.argv[1]+"/small.bin",Buffer.alloc(5,0x41));
fs.writeFileSync(process.argv[2]+"/big.bin",Buffer.alloc(500,0x42));
' "$IN" "$TMP_ROOT" || fail_hard "node ausente ou falhou ao criar fixtures"
PNG_BYTES=$(wc -c < "$IN/cena.png"); SMALL_BYTES=$(wc -c < "$IN/small.bin")
BIG_BYTES=$(wc -c < "$TMP_ROOT/big.bin")
printf 'fixtures     png=%s small=%s big=%s limite=%s\n' "$PNG_BYTES" "$SMALL_BYTES" "$BIG_BYTES" "$MAX_BYTES"

# servidor em background com o exit code gravado no proprio log:
# estado de shell NAO persiste entre chamadas, entao PID/exit nao podem viver em variavel
VERIFY_IN="$IN" VERIFY_OUT="$OUT" VERIFY_MAX_BYTES="$MAX_BYTES" \
  bash -c "$SERVER_LAUNCH > \"$LOG\" 2>&1; echo \"exit=\$?\" >> \"$LOG\"" &
SRV_PID=$!

PORT=""
for _ in $(seq 1 40); do
  PORT=$(sed -n "s/.*${READY_PREFIX}\([0-9][0-9]*\).*/\1/p" "$LOG" 2>/dev/null | head -1)
  [[ -n "$PORT" ]] && break
  sleep 0.25
done
[[ -n "$PORT" ]] || fail_hard "linha '${READY_PREFIX}<n>' nunca apareceu em $LOG"
B="http://127.0.0.1:$PORT"
printf 'porta        %s (sorteada pelo SO, nao reimprima)\n' "$PORT"

W='%{http_code} %{content_type} %{size_download}'

# 1 GET de arquivo conhecido
r=$(curl -sS -o "$TMP_ROOT/get.bin" -w "$W" "$B/cena.png" 2>&1)
chk "1 GET png" "200 image/png $PNG_BYTES" "$r"
if cmp -s "$IN/cena.png" "$TMP_ROOT/get.bin"; then
  PASS=$((PASS+1)); printf 'PASS %-26s bytes identicos ao fixture\n' "1b GET byte-exato"
else
  chk "1b GET byte-exato" "iguais" "divergiu"
fi

# 2 preflight: 204 + cabecalho de rede privada (trava do https -> 127.0.0.1)
h=$(curl -sS -i -X OPTIONS "$B/cena.png" 2>&1)
chk "2 OPTIONS 204" "204" "$(printf '%s' "$h" | head -1)"
if [[ "$REQUIRE_PRIVATE_NETWORK" == 1 ]]; then
  chk "2b Allow-Private-Network" "Access-Control-Allow-Private-Network: true" "$(printf '%s\n' "$h" | grep -i 'private-network' || echo 'cabecalho ausente')"
fi

# 3 POST pequeno grava em --out
r=$(curl -sS -o "$TMP_ROOT/post.json" -w "$W" -X POST --data-binary "@$IN/small.bin" "$B/banner.jpg" 2>&1)
chk "3 POST pequeno" "200" "$r"
DISK=$(wc -c < "$OUT/banner.jpg" 2>/dev/null || echo "ausente")
chk "3b gravado no disco" "$SMALL_BYTES" "$DISK"

# 4 POST acima do limite -> 413 com corpo JSON. code=000 aqui e socket caido, NAO erro do servidor
r=$(curl -sS -o "$TMP_ROOT/over.json" -w "$W" -X POST --data-binary "@$TMP_ROOT/big.bin" "$B/grande.jpg" 2>&1)
chk "4 POST acima do limite" "413" "$r"
[[ "${r:0:3}" == "000" ]] && fail_hard "code=000: o servidor fechou a conexao em vez de responder 413"
head -c 400 "$TMP_ROOT/over.json"; printf '\n'

# 5 saida depois do 413 nao pode ter parcial nem zero-byte
chk "5 sem arquivo parcial" "ausente" "$(ls "$OUT" 2>/dev/null | grep -c grande.jpg | sed 's/^1$/presente/;s/^0$/ausente/')"
LIXO=$(find "$OUT" -type f -size +"${MAX_BYTES}c" 2>/dev/null | wc -l)
chk "5b nada acima do limite" "0" "$LIXO"

# 6 servidor segue vivo depois do erro
r=$(curl -sS -o /dev/null -w "$W" -X POST --data-binary "@$IN/small.bin" "$B/depois.jpg" 2>&1)
chk "6 vivo apos o 413" "200" "$r"

# 7 path traversal em tres formas; --path-as-is impede o curl de normalizar antes de sair
for p in "../SKILL.md" "%2e%2e%2fSKILL.md" "..%5C..%5CSKILL.md"; do
  r=$(curl -sS --path-as-is -o /dev/null -w "%{http_code}" "$B/$p" 2>&1)
  chk "7 traversal $p" "404" "$r"
done

# 8 shutdown limpo: 200, exit=0 no log, porta recusando
r=$(curl -sS -o "$TMP_ROOT/bye.txt" -w "%{http_code}" "$B$SHUTDOWN_URL_PATH" 2>&1)
chk "8 GET shutdown" "200" "$r"
for _ in $(seq 1 20); do grep -q "^exit=" "$LOG" && break; sleep 0.25; done
chk "8b servidor saiu" "exit=0" "$(tail -1 "$LOG")"
SRV_PID=""
r=$(curl -s --max-time 5 -o /dev/null -w "%{http_code}" "$B/cena.png" 2>/dev/null)
chk "8c porta fechada" "000" "$r"

printf '\n== %s de %s assercoes passaram ==\n' "$PASS" "$((PASS+FAIL))"
printf 'log do servidor (ultimas linhas):\n'; tail -5 "$LOG"
[[ "$KEEP_TMP" == 1 ]] && printf 'KEEP_TMP=1: %s\n' "$TMP_ROOT"
[[ "$FAIL" -eq 0 ]]
