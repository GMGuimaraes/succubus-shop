---
name: github-sync-proof-no-token-paste
description: "Provar, com números medidos, que um repositório Git já está sincronizado com o remoto antes de enviar qualquer coisa — e tratar chave colada no chat sem gravá-la. Usar quando o usuário pedir 'sincroniza e manda tudo', 'já fez o envio?', configurar o remoto de um repo novo no GitHub, ou colar um personal access token (ghp_..., github_pat_...) na conversa. Também usar ao escolher entre PAT clássico account-wide e fine-grained por repositório. Não usar para codificação comum, revisão de código ou abrir pull request."
---

# Prova de sincronia, sem token no chat

## Overview

Quando o usuário diz "sincroniza e manda tudo", a primeira entrega é uma **medição**, não um envio: `0 0` de divergência prova que não há nada a enviar, e o mesmo `git push` já funciona com a credencial do keychain. Este skill fixa o portão de verificação e a política de credencial que responde ao pedido "me dá uma chave geral para sempre" sem nunca gravar segredo em arquivo.

## Regra central

**Nunca enviar (push) antes de medir.** Se a medição der divergência zero, dizer isso com os números literais e parar. Enviar código não verificado ou reempurrar o que já está no remoto é pior do que não fazer nada.

## 1. Portão de sincronia

Rodar o script (somente leitura — não contém `push`, `commit`, `checkout`, `reset`, `clean`):

```bash
bash "C:/Users/gmore/.qoder/skills/github-sync-proof-no-token-paste/scripts/sync-proof.sh" <dir-do-repo> <branch>
```

Exemplo medido — saída literal do script em 2026-10-20, repo `D:/Downloads/IronStarsFleetCommand`, branch `main` (o repo avançou desde o turno de origem; estes números são deste run, não dele):

```
repo=/d/Downloads/IronStarsFleetCommand branch=main
remote=https://github.com/GMGuimaraes/iron-stars-fleet-command.git
head=8a31e3d931c4fed4343ed05965428ecadf25449a
remote_sha=8a31e3d931c4fed4343ed05965428ecadf25449a
divergence=behind=0 ahead=0
index_files=10 worktree=tracked-dirty=1 untracked=3
veredito=DIRTY arquivos-modificados=1
aicao=listar-arquivos; nao-incluir-trabalho-alheio-em-envio
```

Leia as duas linhas separadamente: `divergence=behind=0 ahead=0` com `head == remote_sha` prova que **o que está commitado já está no remoto**; o veredito `DIRTY` vem do trabalho local sem commit (`main.gd` modificado + 3 `.uid` não versionados), que não tem nada a ver com envio. Um run `SYNC` tem as mesmas linhas com `tracked-dirty=0` e `untracked` qualquer, e termina em `veredito=SYNC nada-a-enviar`.

Se o script não estiver disponível, medir à mão nesta ordem:

```bash
git -C "<dir>" fetch origin "<branch>"
git -C "<dir>" rev-list --left-right --count "origin/<branch>...HEAD"   # "0 0" = sincronizado
git -C "<dir>" rev-parse HEAD
git -C "<dir>" ls-remote origin "refs/heads/<branch>"                    # SHA igual ao HEAD?
git -C "<dir>" status --short
git -C "<dir>" log --oneline "@{u}..HEAD"                                # vazio = nada pendente
```

Interpretação do veredito:

| veredito | o que dizer | o que fazer |
|---|---|---|
| `SYNC` | "não havia nada a enviar — já está no remoto" + SHA e `0 0` | parar; não rodar push |
| `AHEAD` | "há N envios locais pendentes" | pedir autorização explícita antes de enviar |
| `BEHIND` | "o remoto tem commits que faltam aqui" | perguntar se puxa; nunca forçar |
| `DIRTY` | há trabalho local não gravado | listar arquivos; não incluir WIP alheio num envio |
| `NO-PROOF` | `fetch` ou `ls-remote` falhou (offline, auth, remoto ausente) | **declarar o que não foi provado** em vez de dizer "sincronizado" |

Precedência quando mais de uma condição vale (medido): `NO-PROOF` > `AHEAD` > `BEHIND` > `DIRTY` > `SYNC`. Um repo `AHEAD` **e** `DIRTY` sai como `AHEAD` — leia as linhas `divergence=` e `worktree=` para não esconder o trabalho sujo ao citar o veredito.

### Por que conferir o SHA remoto

`git rev-list` compara `origin/main` **local**, um ref que só anda com `fetch`. Se o `fetch` falhou em silêncio, `0 0` pode ser mentira. Por isso o portão exige `ls-remote` (pergunta ao servidor) para bater o SHA.

### Conferência opcional da árvore (repo público)

Provar que os arquivos gravados são os mesmos no lado do servidor, sem credencial:

```bash
# scratch FORA de /tmp: o Python do Windows não vê /tmp -> FileNotFoundError com http=200 na mesma linha
SCRATCH=/d/Downloads/tmp-userdata; mkdir -p $SCRATCH
curl -sS -o "$SCRATCH/tree.json" -w 'http=%{http_code}\n' \
  "https://api.github.com/repos/<dono>/<repo>/git/trees/<branch>?recursive=1"
```

```bash
curl -sS -o "$SCRATCH/repo.json" "https://api.github.com/repos/<dono>/<repo>"
# a API devolve "private"; NAO existe chave "public" -> KeyError
python -c "import json;d=json.load(open(r'D:/Downloads/tmp-userdata/repo.json'));print('private',d['private'],'default',d['default_branch'],'pushed_at',d['pushed_at'])"
```

`$SCRATCH` é o mesmo diretório do bloco anterior — rode os dois na mesma chamada de shell, e use o caminho absoluto do Windows no Python (o Python do Windows não vê `/tmp`).

Comparar os caminhos da árvore com `git -C "<dir>" ls-files` (índice, não worktree). Diferença = envio faltando ou arquivo fora do índice de propósito (cache gerado, backup `.bak`) — esses últimos ficam fora do repo e devem ser nomeados na resposta.

## 2. Credencial: o que fazer com a chave colada no chat

Token apareceu na conversa = token exposto. A resposta correta é **revogar**, não armazenar.

Distinção que resolve o pedido do usuário ("quero uma geral para sempre"):

- **Credencial já guardada no keychain pelo GCM** — pode ser `gho_…` (token OAuth emitido pelo login do Git Credential Manager) ou `ghp_…` (PAT clássico). Ambas têm 40 caracteres e são *account-wide*: cobrem **todo** repositório novo da conta — `git remote add origin …` + enviar, nada a refazer. Medição nesta máquina (2026-10-20, `git credential fill`): `len=40 prefix=gho_` — é OAuth do GCM, não PAT clássico.
- **Fine-grained** (`github_pat_…`): nascido para ser limitado a repositórios escolhidos e permissões estreitas. **Por construção ele não é geral** — colar um novo em cada repo é justamente o retrabalho que o usuário quer evitar.

Provar que a credencial do keychain existe e cobre o caso de uso, sem nunca imprimir o segredo:

```bash
TOK=$(printf 'protocol=https\nhost=github.com\n\n' | git credential fill | sed -n 's/^password=//p')
printf 'credencial=github.com len=%s prefix=%s\n' "${#TOK}" "${TOK:0:4}"; unset TOK
```

Imprimir **apenas** `${#TOK}` e, quando precisar distinguir o tipo, os 4 caracteres do prefixo `${TOK:0:4}` (`gho_` = OAuth do login do GCM, `ghp_` = PAT clássico, `github_pat_` = fine-grained) — nunca o valor inteiro. O stdout desta ferramenta é copiado para o log da sessão e para a interface: um `echo "$TOK"` vaza a chave de novo, exatamente como já aconteceu.

Três vias de gravação que este skill **proíbe**, e o motivo a dizer ao usuário:

1. `.git/config` do repo — a chave fica legível para quem abrir a pasta e vai junto em qualquer cópia do diretório.
2. URL do remoto com `usuario:token@github.com/…` — idem, e ainda aparece em `git remote -v`, em log e em zip do projeto.
3. `.env` / `.txt` / script no diretório do projeto.

As três ficam legíveis para quem abrir a pasta, e as duas primeiras vão junto num zip ou num envio acidental.

Quando a credencial do keychain expirar ou for revogada: deixar o Git perguntar **uma** vez (`git push` abre o login do GCM no navegador e grava sozinho). Não inventar armazenamento manual.

## 3. Formato da resposta

Entregar números literais, não intenção. Exemplo real do turno de origem (medidos naquele run — `da8fd57…` e 9 arquivos; não reutilize estes valores se a medição atual for outra):

> Não havia nada a enviar — já está sincronizado, e conferi no GitHub em vez de assumir. `git rev-list --left-right --count origin/main...HEAD` → `0 0`; `git ls-remote origin` → `refs/heads/main = da8fd57…`, igual ao `HEAD` local; API → `private=False default=main pushed_at=2026-10-20T18:02:25Z`; a árvore remota tem os mesmos 9 arquivos do índice local, os três envios (`3a19a6b` → `1809f1b` → `da8fd57`) já estão lá. Fora do repo de propósito: `.godot/` (cache gerado) e `main.gd.bak` (backup pré-existente). Sobre a chave: não a usei nem gravei; o GCM já tem uma credencial account-wide no keychain (`len=40 prefix=gho_`, OAuth do login do GCM) e cobre qualquer repo novo — o `github_pat_…` que você colou é fine-grained, por-repositório por construção, e está exposto: revogue-o.

## Riscos e limites

- `fetch` e `ls-remote` fazem rede (leitura; não alteram o remoto nem o estado de trabalho local).
- Skill restrito a *provar estado de sincronia e tratar credencial*. Qualquer alteração de histórico ou envio continua dependendo de pedido explícito do usuário.
- Repo privado: a API anônima devolve `404`/`401` — dizer que a árvore não foi conferida; não passar token na linha de comando expandida. Se precisar autenticar, manter o header literal `-H "Authorization: Bearer $TOK"` dentro da mesma chamada de shell onde `TOK` foi lido, sem nunca expandi-lo no texto do comando.

## Resources

- [scripts/sync-proof.sh](scripts/sync-proof.sh) — portão determinístico de sincronia (saída de uma linha por métrica, veredito `SYNC`/`AHEAD`/`BEHIND`/`DIRTY`/`NO-PROOF`).
