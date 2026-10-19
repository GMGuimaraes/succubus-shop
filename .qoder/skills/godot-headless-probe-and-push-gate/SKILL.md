---
name: godot-headless-probe-and-push-gate
description: 'Portao reproduzivel de validacao antes de todo commit e push no jogo Godot Succubus Shop (D:/Downloads/succubus-shop). Usar ao testar logica ou cena em headless, ao escrever sonda _tmp_*.gd com extends SceneTree, ao rodar --check-only, smoke com --quit-after e log em arquivo, ao filtrar erro conhecido por grep, ao isolar o save real com APPDATA descartavel, ao promover sondas utiles para res://tools/ e ao limpar sujeira preexistente (.import CRLF, project.godot, .manus/) antes de enviar para origin/main.'
---

# Godot headless probe and push gate (Succubus Shop)

## Overview

Todo jogo valido uma mudanca neste repo com uma sonda headless antes de commitar. O
portao existe por dois motivos inegociaveis: o probe chama `_save_game()` sem querer e
corrói o save real do usuario, e a sujeira gerada pelo proprio Godot (`.import` em CRLF,
`project.godot`, `.manus/`) entra junto no commit quando ninguem confere.

Executar na ordem. Pular passo nao e acelerar, e estragar.

## Fixos do ambiente

| Item | Valor |
|---|---|
| Projeto | `D:/Downloads/succubus-shop` (fora do workspace; nunca indexado aqui) |
| Binario Godot | `C:/Users/gmore/godot/godot` (4.7.2.stable.official) |
| Shell | Git Bash, caminhos em `/d/...` |
| APPDATA descartavel | `D:/Downloads/tmp-userdata` |
| Save real a preservar | `%APPDATA%/Godot/app_userdata/Succubus Shop/succubus_shop_save.cfg` |
| Remoto | `GMGuimaraes/succubus-shop`, só `main`, sem `gh` CLI (git HTTPS + credential helper) |
| Jogo principal | `res://main.tscn`, script `res://main.gd` |

Antes de assumir a versao do motor, conferir `"$GODOT" --version`; o usuario atualiza o
Godot e o numero muda.

Esta skill tem copia rastreada no repo em
`.qoder/skills/godot-headless-probe-and-push-gate/SKILL.md`. O arquivo que carrega e o de
`C:/Users/gmore/.qoder/skills/`; o do repo e o que as outras sessoes e pessoas leem. Toda
edicao aqui precisa ser espelhada la e commitada, senao o portao passa a existir em duas
versoes que dao respostas diferentes.

## Passo 0 - registrar o hash do save real

Sempre antes de qualquer comando que instantiate o jogo.

```bash
GODOT="/c/Users/gmore/godot/godot"
SAVE_REAL="$APPDATA/Godot/app_userdata/Succubus Shop/succubus_shop_save.cfg"
md5sum "$SAVE_REAL"   # anotar o hash; conferir no passo 8
```

## Passo 1 - sincronizar com o remoto antes de editar

```bash
cd /d/Downloads/succubus-shop
git fetch origin
git log --oneline HEAD..origin/main      # remoto na frente?
git log --oneline origin/main..HEAD      # local na frente?
git status --short
```

Se `origin/main` tiver commits novos, inspecionar e sincronizar preservando as alteracoes
locais. Nunca fazer rebase/merge com risco real de conflito sem pedir autorizacao. O
checkout costuma estar atrasado e com WIP solto de outra IA: tratar como alheio, nao como
licenca para limpar.

## Passo 2 - reuse a sonda que ja existe

O repo mantem sondas vivas. Antes de criar arquivo:

```bash
ls _tmp_*.gd
grep -ln "_on_customer_tick\|_reset_run" _tmp_*.gd
```

Algumas perguntas ja tem sonda (fila, forja, cartas, romance, ruina, finais, saldo do dia,
expedicao, pessoal, arcos de faccao, thumbnails e filmagens de cena). Estender uma sonda
existente e melhor que criar a decima copia.

## Passo 3 - template da sonda

Arquivo `_tmp_<assunto>.gd` na raiz, `extends SceneTree`, sem cena propria:

```gd
extends SceneTree

## Uma frase do que a sonda prova e por que isso importa na tela.

const OUT := "D:/Downloads/tmp-userdata/"

func _initialize() -> void:
	var game := (load("res://main.tscn") as PackedScene).instantiate()
	get_root().add_child(game)
	await _frames(3)
	game.world_timer.stop()
	game._reset_run()
	game._refresh_ui()
	# ... exercitar a funcao e printar o veredito com rotulo legivel ...
	quit()

func _frames(n: int) -> void:
	for i in range(n):
		await process_frame
```

### Sonda de causa: o numero se moveu e nao sei por que

Quando a pergunta nao e "a funcionalidade funciona?" e sim "por que o ouro pulou?", a
sonda nao deve assertar nada: capture o estado da loja, rode UM `_on_customer_tick()` e
imprima so o que divergiu. A atribuicao vem do mural, nao do delta.

```gd
const CHAVES := ["gold", "reputation", "daily_gold_earned", "customers_served",
	"credit_book", "regular_bonds", "regular_arc_seen", "faction_standing",
	"player_level", "player_xp", "unlocked_achievements", "shop_day"]

func _estado(g) -> Dictionary:
	var e := {}
	for k in CHAVES:
		e[k] = str(g.get(k))
	return e

func _divergiu(antes: Dictionary, depois: Dictionary) -> void:
	for k in CHAVES:
		if antes[k] != depois[k]:
			print("   %s: %s -> %s" % [k, antes[k], depois[k]])

# na corrida, por tique:
var antes := _estado(g)
g._on_customer_tick()
var depois := _estado(g)
_divergiu(antes, depois)
for linha in String(g.last_event).split("\n"):
	print("   mural: ", linha)
```

Regras desta sonda:
- **`:=` nao infere de Dictionary nem de chamada sem tipo.** Medido em
  `tools/probes/causa.gd`: `var texto := depois[k]` da Parse Error ("Cannot infer the
  type ... because the value doesn't have a set type"), e `var g := await _loja(...)`
  tambem. Escreva o tipo na mao: `var texto := str(depois[k])`, `var g = await _loja(...)`.
- **O chao da loja e re-declarado, nao importado.** `const Bancada := preload(...)` e
  `Bancada._loja("causa")` da Parse Error ("Cannot call non-static function on the class").
  Toda sonda viva (`salao.gd`, `bancada.gd`, `fiado.gd`) carrega o proprio corpo de
  `_loja()`: instanciar, `await _frames(3)`, `_fixar_locale()`, parar o `world_timer`,
  `seed()`, `_reset_run()`. Copie o corpo, nao chame por classe.
- **Sele as conquistas e o nivel antes de medir** (o `_blindar()` ja existe em
  `tools/probes/bancada.gd`: `_selar()` + `player_level = 60`). Sem a rolha, o selo paga
  ouro no meio do tique e a diferenca que voce atribui ao fiado era premio de conquista.
  Medida real deste repo: um unico tique deu +260 de caixa e o culpado era a ficha de
  arco, nao o livro de fiado.
- **Um tique nao e uma causa.** A mesma virada cobre conta da casa, fiado vencido e selo.
  Medido: um tique de loja nova nao moveu chave nenhuma e o mural era um roubo —
  "pegou Pato Amaldiçoado e correu", zero ouro. Se o delta sair vazio, a resposta esta no
  mural, nao na ausencia de diferenca.
- **Por que cada chave da lista:** `daily_gold_earned` registra faturamento mesmo com o
  ouro parado no livro; `credit_book` e Dictionary, dai o `str()` no snapshot (sem ele a
  comparacao sai por referencia); `regular_bonds` e `regular_arc_seen` explicam a etiqueta
  que andou sozinha; `unlocked_achievements` e a prova de que a rolha vazou.
- Nao existe `badges` nem um `level`/`xp` de loja no `main.gd`: os nomes reais sao
  `unlocked_achievements`, `player_level` e `player_xp`. A banda e derivada
  (`_progress_band_now()` sobre `business_score()`), entao nao entra no snapshot.
- Saida no formato do repo (`caixa 5000 -> 5059`), que e o que torna o diff lavel no log.

Fotograma de cena: `get_root().get_texture().get_image().save_png(OUT + "nome.png")` e ler
o PNG de volta com a ferramenta Read. Um probe sem saida legivel nao prova nada.

Essa linha do fotograma so funciona **em janela** (ver passo 6): com `--headless` a textura
vem null e cada `save_png` reprova. Se a sonda vai fotografar, ela ja nasce sem a flag -
nao e um ajuste de ultimo minuto depois do primeiro erro.

## Passo 4 - armadilhas de determinismo (corrigidas a mao na origem deste ritual)

- **Nunca `await` entre ticks.** A rotacao de atores do palco consome RNG guiado por
  frames reais; esperar no meio do laco muda o resultado entre o caso A e o caso B. Rodar
  todos os `_on_customer_tick()` em sequencia e esperar uma unica vez no fim.
- **Dicionario aliasado.** `game.spec_choice = d` nao copia; `_reset_run()` faz
  `d.clear()` e esvazia o literal do chamador. Sempre `d.duplicate(true)`.
- **Estado que sobrevive ao `_reset_run()`:** limpar a mao antes de cada lado de um A/B
  `regular_bonds`, `regular_orders_completed`, `regular_story_progress`,
  `regular_story_completed`, `regular_arc_seen`, `romance_stage`, `card_counts`,
  `faction_standing`, `season_baseline`. Eles atravessam vidas e mexem nos precos.
- **Conquistas poluem a medida.** Rodar uma rodada de aquecimento descartavel antes e
  Flush de `_check_achievements()`, senao o payout cai num lado so.
- **Imprimir com casas decimais** (`%+.1f`). Arredondar para ouro inteiro escondeu um
  ganho real de +0.4 e leu como "sem efeito".
- **Checar o caminho antes de exercitar.** Quase toda funcao de jogo termina em
  `_save_game()` e `audio.gd` persiste `audio_settings.cfg`. Preferir logica pura com
  `--check-only` quando a pergunta e de compilacao.
- **`:=` nao infere `await` de funcao sem tipo.** `var loja := await _loja(...)` da Parse
  Error ("variable doesn't have a set type"). Usar `var loja = await ...` quando o helper
  retorna Variant.
- **Traducao se mede pela chave, nao pelo rotulo.** No Godot 4.7 nao existem
  `Label.get_displayed_text()` nem `Button.get_translated_text()` (sao de 3.x); o `.text`
  continua carregando o literal original porque quem traduz e o motor na hora de desenhar.
  Medir com `TranslationServer.translate(chave)` ou `node.tr(chave)`.
  `TranslationServer.get_loaded_translations()` tambem nao existe: e `get_translations()`.
- **`set_locale()` de locale sem tabela cai no melhor ajuste.** Com so uma traducao
  registrada, pedir um idioma ausente devolve aquela unica tabela (medido: locale `de`
  acordou em ingles). O idioma original precisa de tabela identidade (chave -> chave), senao
  voltar ao portugues continua lendo ingles.
- **O idioma e da pessoa, nao da partida, e por isso sobrevive ao `_reset_run()`.**
  `_pick_locale()` (main.gd) grava `locale` + `locale_confirmed` em
  `Locales.SETTINGS_PATH` = `user://locale_settings.cfg`; `_load_person_settings()` le o
  arquivo no `_ready()`, e o comentario no codigo diz que a preferencia mora fora do save de
  proposito. Uma rodada anterior que passou pelo seletor de idioma deixa o proximo probe em
  ingles, e ai a assercao em portugues sobre `.text` le ausencia sem regressao alguma no
  jogo: medido, o selo "FORMA DEMONÍACA" virou "AUSENTE (esperado presente)" em
  `tools/probes/filtro.gd`. O jogo chama `tr()` antes de escrever o `.text` (painel de
  furia, botoes de setor), entao o alvo e o rotulo. Fixar no helper da sonda, logo apos os
  fotogramas de `_ready()` e antes de `_reset_run()`:
  `g.locale = Locales.DEFAULT`, `g.locale_confirmed = true`,
  `TranslationServer.set_locale(Locales.DEFAULT)`. Na duvida, imprimir `game.locale` antes
  de afirmar regressao de texto.
- **Modal auto-aberto em `_ready()` cega a sonda.** Uma janela que para o `world_timer` e
  so fecha por clique tranca qualquer probe headless (e screenshots ficam escurecidos pela
  camada dim). Guardar o auto-open com `DisplayServer.get_name() != "headless"` e chamar
  `_open_menu()` explicitamente na sonda.
- **Save descartavel novo traz o seletor de idioma por cima de toda foto.** Medidas em
  `tools/probes/galeria.gd`: as seis primeiras capturas sairam cobertas pelo "ESCOLHA O
  IDIOMA", porque o APPDATA descartavel nunca viu a loja e o `locale_confirmed` esta
  false. Fechar pelo caminho do jogador (`game._close_menu()`), nao com `visible = false`:
  esconder a camada deixa o estado do menu vivo e pula a preferencia de idioma que o resto
  das assercoes espera. Atencao: `_close_menu()` chama `_save_game()` - so e seguro porque
  o `APPDATA` esta redirecionado.

## Passo 5 - `--check-only` na sonda e em tudo que foi tocado

```bash
cd /d/Downloads/succubus-shop
env APPDATA="D:\\Downloads\\tmp-userdata" "$GODOT" --headless --path . \
  --check-only --script res://_tmp_<assunto>.gd
```

Repetir com `--script res://main.gd` (e cada outro `.gd` tocado). Erro de parse aqui custa
segundos; descobri-lo no passo 6 custa um smoke inteiro.

## Passo 6 - smoke em background, com log em arquivo

Probe de cena passa do timeout do Bash: rodar **sempre** em background e ler o log depois.

```bash
env APPDATA="D:\\Downloads\\tmp-userdata" "$GODOT" --headless --path . \
  --quit-after 1800 --script res://_tmp_<assunto>.gd > /d/Downloads/tmp-userdata/probe.log 2>&1
```

**Sonda que fotografa o palco corre SEM `--headless`.** O display server headless nao tem
rasterizador, entao `get_root().get_texture().get_image()` devolve null e cada
`save_png`/`get_region` reprova com `ERROR: Parameter "t" is null` +
`SCRIPT ERROR: Cannot call method 'save_png' on a null value`. A sonda roda, mede certo e
parece aprovada - so que o olhar nao existe. Regra: logica pura = `--headless`;
recorte de frame de cena = janela (`--path .` sem flag), e `mkdir -p` da pasta de saida
antes, porque `save_png` falha em silencio para diretorio inexistente.
`tools/probes/trajeto.gd` e `tools/probes/galeria.gd` carregam essa dica no cabecalho
("janela: precisa de viewport para os recortes"). O resto do portao continua valendo na
sonda de janela: `APPDATA` descartavel, log em arquivo, gate de grep e conferencia do save.

- `APPDATA` inline no comando, nunca `export` no shell compartilhado.
- Delete do save descartavel antes da rodada, para o probe nao ler progresso de teste
  antigo como se fosse real
  `rm -f "/d/Downloads/tmp-userdata/Godot/app_userdata/Succubus Shop/succubus_shop_save.cfg"`.
- `--quit-after` e em iteracoes (frames), nao segundos; 1800 cobre varios tiques do mundo.
- **Assertiva de isolamento** logo apos a primeira rodada: o save novo tem de aparecer sob
  `D:/Downloads/tmp-userdata/`. Se nao aparecer, o probe escreveu no save real - parar e
  refazer o passo 0 antes de continuar. Este portao falha aberto: na duvida, nao rodar.

## Passo 7 - gate de erro por grep

```bash
grep -nE "ERROR|SCRIPT ERROR|Cannot|Invalid|assert" /d/Downloads/tmp-userdata/probe.log
```

Qualquer linha que sobrar reprova o push: voltar ao passo 4. Saida vazia e aprovacao.

**Nao existe mais baseline tolerada.** Houve duas. A primeira era diaria: todo smoke
imprimia `WARNING: 2 ObjectDB instances were leaked at exit` + `ERROR: 1 resources still
in use at exit`, e o portao filtrava essas duas linhas mais `shop_theme_loop.mp3`. Medida
com `--verbose` (unico modo de ver o *nome* do objeto vazado) a dupla diaria era
`res://audio/rare.wav` e o `AudioStreamPlaybackWAV` dele, deixado vivo quando a arvore morre
com um efeito tocando; fechada em 2026-10-17 por `_exit_tree()` em `audio.gd`. Sobrou a
segunda, intermitente (1 a 3 rodadas em 5), cujo nome era `AudioStreamPlaybackMP3` +
`AudioStreamMP3` de `shop_theme_loop.mp3`.

A causa das duas e a mesma, e nao e o arquivo: `AudioStreamPlayer::stop()` apenas *agenda* a
destruicao do playback na thread de audio. Um processo que chama `quit()` no mesmo instante
nunca da esses frames, e o playback aparece como instancia orphan. Medido em
`tools/probes/musica.gd`, lado `tocando`: 3 em 5 antes do corte, 1 em 5 mesmo depois de parar
a trilha na saida da arvore. Parar nao basta -- o que fecha a conta e **nao iniciar reproducao
onde nao ha ouvido**: `_setup_background_music()` (main.gd) e `audio.gd::play()` so dao
`play()` quando `DisplayServer.get_name() != "headless"`, e a contabilidade de resfriamento e
janela de rajada continua identica porque acontece antes do gesto. Lado `confere`, sem
reproducao: 0 em 6 rodadas, e a bateria de 6 rodadas de `tools/probes/menu.gd` voltou limpa.

Consequencia honesta, e o que se sabe ate aqui: no mesmo dia a trilha virou
`res://audio/shop_theme_loop.wav` sintetizada pelo proprio projeto
(`tools/generate_audio.py`), com `compress/mode=0` no `.wav.import` -- e as duas linhas
sumiram (0 em 6 rodadas, gate sem nenhuma exclusao). A troca de formato **nao era a cura**.
Em 2026-10-19, a pedido do jogador, o MP3 classico voltou como tema do salao
(`assets/shop_theme_loop.mp3`, 91,6 s) e a WAV ficou com os tres infortunios; o gate continua
0 linhas em 9 rodadas headless, porque quem fecha a conta e o corte do `play()` e o
`_exit_tree()`, nao o container. Forcando reproducao com o MP3 no ar, `--verbose` nomeia
`AudioStreamMP3` + `AudioStreamPlaybackMP3` sobre `res://assets/shop_theme_loop.mp3` em 1 de 2
rodadas; com WAV sozinho nomeava a WAV na mesma taxa intermitente. O nome no log e apenas o
arquivo que estava tocando -- a causa continua sendo o `stop()` adiado. Fechar a janela com
musica tocando ainda pode imprimir as duas linhas no console: isso nao e o gate, e nao se
passa a tolerar.

Os dois formatos pedem dois lacos diferentes, e a sonda asserta os dois: WAV quer
`loop_mode = LOOP_FORWARD`, `loop_begin = 0` e `loop_end = floori(get_length() * mix_rate) - 1`
-- nunca `data.size()`, que com `compress/mode=2` ja vem codificado, encolhe ~5x e corta a
musica no meio. MP3 quer so `loop = true` em runtime: o `.import` grava `loop=false`, e quem
manda e o valor que o player le antes de `play()`. Vivem em `tools/probes/musica.gd`. Se a
linha voltar **numa sonda**, e regressao do corte: rodar com `--verbose`, ler o nome impresso
em `Leaked instance:` / `Resource still in use:` e consertar a origem — nunca alargar o
`grep -v` ate o gate aprovar tudo.

## Passo 8 - conferir o save real

```bash
md5sum "$SAVE_REAL"
```

Mudou, o probe escreveu no lugar errado. Reverter pelo proprio jogo, com um script que
aplica o delta inverso; editar o `.cfg` na mao esta bloqueado e perde a semantica do
jogo. Relatar o desvio ao usuario em vez de consertar em silencio.

## Passo 9 - sonda nao se joga fora: conectar ao jogo

O destino de uma sonda e um destes tres, decididos pelo que ela respondeu:

1. **Continuou util** (prova algo que vai ser perguntado de novo - economia, fila,
   saldo, finais) - mover para `res://tools/probes/<nome>.gd`, que e codigo rastreado,
   e gravar no cabecalho a linha de comando exata de execucao, no padrao de
   `res://tools/split_poses.gd`:

   ```
   ## Uso: godot --headless --path . --quit-after 1800 -s res://tools/probes/<nome>.gd
   ```

   Sonda que fotografa recebe a linha **sem** `--headless`, que e a unica que roda:

   ```
   ## Uso (janela aberta, de proposito):
   ##   APPDATA="D:\\Downloads\\tmp-userdata" godot --path . --quit-after 90000 \
   ##     -s res://tools/probes/<nome>.gd
   ```

   Copiar a linha headless para uma sonda de foto e deixar no repo um comando que reprova
   na primeira linha - ver `tools/probes/galeria.gd` como referencia de cabecalho.

   Commitar como ferramenta de desenvolvimento, com o resto da tarefa.
2. **Virou funcionalidade do jogo** - o que ela media deveria acontecer na partida, nao
   num script solto. Abrir como mudanca em `main.gd` e só entao aposentar a sonda.
3. **Descartavel** - apagar apenas os `_tmp_*.gd` criados nesta rodada, com o `.uid`
   correspondente `rm -f _tmp_<assunto>.gd _tmp_<assunto>.gd.uid`.

Nao apagar sonda criada por outra sessao ou por rodada anterior. As 21 sondas herdadas no
repo sao materia-prima do caso 1 e do caso 2, nao lixo - promove-las e trabalho
proprio, agendado, e nao efeito colateral silencioso de um push alheio.

## Passo 10 - sujeira local, commit e push

```bash
git status --short
git diff --ignore-cr-at-eol --stat -- '*.import' project.godot
```

O `--import` do Godot reescreve os `.import` rastreados com LF, gerando churn de CRLF em
~17 arquivos mais `project.godot`. Confirmar que o diff e puro final de linha
(vazio sob `--ignore-cr-at-eol`) e so entao descartar - `git checkout --` e destrutivo,
pedir autorizacao antes. `.manus/` e artefatos de `D:/Downloads/tmp-userdata/` jamais
entram no commit.

```bash
git add <arquivos desta tarefa, um por um>
git commit -m "<feat/fix/docs: o que e por que>"
git push origin main
git status --short
```

Commitar por nome de arquivo, nunca `git add -A`. Relatar os dois resultados: o da
verificacao remota (passo 1) e o do push.

## Riscos deste ritual

- **Sessao concorrente no mesmo repo.** Se outra sessao estiver escrevendo
  `main.gd` enquanto o smoke roda, a validacao prova um estado que ja nao existe. Conferir
  `git status` e perguntar antes de rodar.
- **Falha aberta e o modo seguro.** Se `APPDATA` nao resolver como esperado, o gate nao
  roda; nao se assume que "desta vez nao grava no jogo".
- **Aprovacao visual nao acontece aqui.** Timing, sensacao de animacao e arte precisam do
  usuario no editor. Dizer isso em vez de declarar sucesso.
