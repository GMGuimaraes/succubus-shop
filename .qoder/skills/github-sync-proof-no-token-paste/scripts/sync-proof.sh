#!/usr/bin/env bash
# Portao deterministico de sincronia Git <-> GitHub. Somente leitura.
# Uso: bash sync-proof.sh <dir-do-repo> [branch]   (padrao: main)
# Vereditos: SYNC | AHEAD | BEHIND | DIRTY | NO-PROOF
set -u

REPO="${1:-}"
BRANCH="${2:-main}"

if [ -z "$REPO" ]; then
  echo "uso: sync-proof.sh <dir-do-repo> [branch]"
  exit 2
fi

g() { git -C "$REPO" "$@" 2>/dev/null; }

echo "repo=$REPO branch=$BRANCH"

if [ ! -d "$REPO" ]; then
  echo "veredito=NO-PROOF motivo=diretorio-inexistente"
  exit 1
fi
if [ -z "$(g rev-parse --is-inside-work-tree)" ]; then
  echo "veredito=NO-PROOF motivo=nao-e-worktree"
  exit 1
fi

REMOTE_URL="$(g remote get-url origin)"
echo "remote=${REMOTE_URL:-<sem-remoto-origin>}"
if [ -z "$REMOTE_URL" ]; then
  echo "veredito=NO-PROOF motivo=sem-remoto"
  exit 1
fi

# 1) fetch: atualiza o ref local origin/<branch> (rede, leitura)
FETCH_OK=1
git -C "$REPO" fetch origin "$BRANCH" >/dev/null 2>&1 || FETCH_OK=0

# 2) SHA local e SHA no servidor (ls-remote pergunta ao servidor, nao ao cache)
HEAD_SHA="$(g rev-parse HEAD)"
REMOTE_SHA="$(g ls-remote origin "refs/heads/$BRANCH" | awk 'NR==1{print $1}')"
echo "head=${HEAD_SHA:-<indeterminado>}"
echo "remote_sha=${REMOTE_SHA:-<indeterminado>}"

# 3) divergencia medida: left=atraso right=adiantado
DIVERGE="$(g rev-list --left-right --count "origin/$BRANCH...HEAD")"
BEHIND="$(printf '%s' "$DIVERGE" | awk '{print $1}')"
AHEAD="$(printf '%s' "$DIVERGE" | awk '{print $2}')"
echo "divergence=behind=${BEHIND:-?} ahead=${AHEAD:-?}"

# 4) indice x arvore de trabalho (arquivos nao versionados continuam fora)
INDEX_FILES="$(g ls-files | grep -c . || true)"
STATUS="$(git -C "$REPO" status --porcelain=v1 2>/dev/null)"
if [ -z "$STATUS" ]; then
  UNTRACKED=0
  DIRTY=0
else
  UNTRACKED="$(printf '%s\n' "$STATUS" | grep -c '^??' || true)"
  DIRTY="$(printf '%s\n' "$STATUS" | grep -vc '^??' || true)"
fi
echo "index_files=${INDEX_FILES:-0} worktree=tracked-dirty=${DIRTY} untracked=${UNTRACKED}"

# 5) o que esta adiantado, em SHA curto (para citar na resposta)
if [ -n "$AHEAD" ] && [ "$AHEAD" != "0" ]; then
  echo "pendentes=$(g log --format=%h "@{u}..HEAD" | tr '\n' ' ')"
fi

# 6) coerencia cache x servidor
if [ -n "$REMOTE_SHA" ] && [ -n "$HEAD_SHA" ] && [ "$REMOTE_SHA" != "$HEAD_SHA" ]; then
  echo "aviso=sha_remoto_diferente_do_head_local (ref local pode estar defasado)"
fi

if [ "$FETCH_OK" = "0" ] || [ -z "$REMOTE_SHA" ] || [ -z "$BEHIND" ] || [ -z "$AHEAD" ]; then
  echo "veredito=NO-PROOF motivo=fetch-ou-consulta-ao-remoto-falhou"
  echo "aicao=declarar-o-que-nao-foi-provado-em-vez-de-dizer-sincronizado"
elif [ "$AHEAD" != "0" ]; then
  echo "veredito=AHEAD pendentes-de-envio=$AHEAD"
  echo "aicao=pedir-autorizacao-expressa-antes-de-enviar"
elif [ "$BEHIND" != "0" ]; then
  echo "veredito=BEHIND atraso=$BEHIND"
  echo "aicao=puxar-so-depois-de-confirmar-com-o-usuario"
elif [ "$DIRTY" != "0" ]; then
  echo "veredito=DIRTY arquivos-modificados=$DIRTY"
  echo "aicao=listar-arquivos; nao-incluir-trabalho-alheio-em-envio"
else
  echo "veredito=SYNC nada-a-enviar"
fi
exit 0
