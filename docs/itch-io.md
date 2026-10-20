# Kit de publicação — itch.io

Copy, avisos honestos e o passo a passo para subir o **Succubus Shop** na itch.io.
Os números abaixo não são chutes: foram medidos em 2026-10-18 com
`tools/probes/publicar.gd` (60 conferências, 0 quebras), `tools/probes/idioma.gd`
(228/228 chaves nas cinco tabelas traduzidas), `tools/probes/menu.gd` (100 definições
de conquista) e uma varredura PNG da árvore `assets/`.

---

## 1. Estado real — o que ainda bloqueia o botão de publicar

> Resolvido em 2026-10-19: nada bloqueava, o botão foi clicado e a página está no ar
> (`shininoobi.itch.io/succubus-shop`, §11). A tabela abaixo continua como diagnóstico do
> caminho até a publicação, não como lista de pendências.

| Item | Estado | O que falta |
|---|---|---|
| Presets de export (`Windows Desktop`, `Linux`, `Web`) | prontos, conferidos por sonda, e os três exportam de verdade | — |
| Ícone do build (`icon.svg`, 128×128, 1127 bytes) | pronto | — |
| Guarda de plataforma (sem janela de arquivo no navegador) | pronta e medida | — |
| Templates de export do Godot 4.7.2 | **instalados** (`%APPDATA%\Godot\export_templates\4.7.2.stable`) | — |
| Build Windows real | gerado e medido: `.exe` de 153,67 MB descompactado (`.pck` embutido), zip de **82,10 MB** | ver §6 antes de confiar na arte |
| Build Linux real | gerado e medido: `Succubus Shop.x86_64` de 118,06 MB, zip de **73,35 MB**, com o modo unix `0755` gravado no `.zip` | o zip criado no Windows sairia `-rw----` (sem bit de execução) — `marcar_execucao()` corrige |
| Build web real | gerado e medido: `.pck` de 48,05 MB, zip de **57,81 MB**, `index.html` na raiz | ver §6 antes de confiar na arte |
| Fontes de símbolo embarcadas (§8) | prontas e medidas **só no navegador**: os presets de mesa filtram `fonts/*.ttf` e o binário de mesa não tem uma ocorrência da Noto | — |
| Orçamento de textura do `.pck` | aplicado (`tools/set_texture_budget.py`) | conferir o recorte no olho (§6) |
| Descrição "About" do repositório GitHub | editável pela API (`PATCH /repos/...`) — ver §16 | — |

`tools/build_itch.sh` ainda **não baixa nada**: sem templates ele para na porta com a
instrução de instalação. O preflight comparava a versão longa do motor
(`4.7.2.stable.official.ed1daf0bf`) com a pasta de templates (`4.7.2.stable`) e reprovava
um build já instalado — corrigido, agora corta a versão curta e, antes de cada alvo,
confere o molde de release daquela plataforma (ver a armadilha do `version.txt` acima).

Duas armadilhas medidas nesta rodada, nenhuma delas com erro honesto na tela:

- **O preset Linux só existe para o motor com `platform="Linux/X11"`.** Com `Linux/*BSD` ou
  `Linux/bsd` o `export_presets.cfg` carrega sem reclamar nada no boot do editor, o preset é
  **descartado em silêncio**, e o export responde `Invalid export preset name: Linux` citando
  como detectados só `"Windows Desktop"` e `"Web"`. Os três candidatos foram rodados um por
  um; a asserção ficou em `tools/probes/publicar.gd` para ninguém "modernizar" a string.
- **O exportador procura o template dentro de `$APPDATA/Godot/export_templates`** — a mesma
  variável que as sondas trocam para `D:\Downloads\tmp-userdata` a fim de não escrever no
  save real. Com o `APPDATA` descartável, o export diz `Nenhum modelo de exportação
  encontrado no caminho esperado: D:/Downloads/tmp-userdata/Godot/export_templates/...`. Os
  três `--export-release` do `build_itch.sh` usam o `%APPDATA%` verdadeiro; só as sondas
  mudam de pasta.
- **`version.txt` não prova molde nenhum.** O diretório descartável das sondas tem uma
  cópia parcial de templates: o `version.txt` e os `.zip` do navegador estão lá, os `.exe`
  de mesa não. O preflight passava por ele e a cadeia morria no export de mesa, depois de
  importar a árvore inteira. Desde esta rodada `exportar()` confere o arquivo que cada
  preset realmente exige (`windows_release_x86_64.exe`, `linux_release.x86_64`,
  `web_nothreads_release.zip`) e para em dois segundos dizendo o nome que falta.

---

## 2. Ficha técnica (o que a página pode prometer)

| Campo | Valor medido |
|---|---|
| Motor | Godot 4.7.2.stable |
| Versão | `0.1.0-alpha.6` (núcleo `0.1.0`). A loja anuncia o próprio número no rodapé de toda tela do menu e na primeira linha dos créditos — no navegador e em Linux não há `.exe` para olhar no explorador |
| Janela | 1280×720, escala `canvas_items` |
| Renderizador | `gl_compatibility` — escolhida de propósito: é a que roda em navegador e em GPU antiga |
| Threads no build web | **desligadas** (`variant/thread_support=false`) → não exige `SharedArrayBuffer`, então roda em qualquer hospedagem, inclusive a da itch.io, sem cabeçalho cruzado |
| Idiomas | português, inglês, espanhol, francês, italiano, alemão (catálogo com as mesmas 228 chaves nas cinco tabelas traduzidas) |
| Conquistas | 100 definições. Na itch.io elas **não** aparecem: só a integração opcional com a Steam as entrega — na vitrine elas contam como conteúdo, não como sistema |
| Conteúdo | fantasia sombria adulta, **tom sugestivo atrás de um botão**; nenhuma nudez explícita em nenhum modo |
| Save | arquivo em mesa; no navegador mora no armazenamento do site (IndexedDB) |
| Massa de arte | **667 PNG** na árvore: 169,60 Mpx, 274,87 MB. O corte com perdas por classe (`tools/set_texture_budget.py`, `compress/mode=1`) embarca **41,46 MB de `.ctex`** — 21,81 MB das 57 opacas + 19,65 MB das 610 com alfa — e fecha o `.pck` do navegador em 43,47 MB, que viram **48,61 MB** com as fontes e **48,05 MB** depois de as 72 sondas de desenvolvimento saírem do pacote com as duas fontes de símbolo (§8); com o MP3 da trilha clássica de volta são **50,26 MB** (§10) |
| Download do build web | **60,01 MB** compactado (`.zip` de 60.008.512 bytes). Dentro dele `.pck` 50,26 MB e `.wasm` 39,51 MB descompactado — o `.wasm` é o motor, fixo, não depende da arte |
| Download dos builds de mesa | Windows **84,30 MB** (um `.exe` de 155,87 MB descompactado, `.pck` embutido); Linux **75,55 MB** (binário `x86_64` de 120,26 MB, `.pck` embutido). Os dois passam o limite de 200 MB por arquivo descompactado. As fontes do §8 **não** embarcam neles: `exclude_filter` com `fonts/*.ttf`, conferido no binário |

Regra da itch.io que aperta aqui: cada arquivo **descompactado** tem de caber em 200 MB.
O `.pck` sem perdas media 207,33 MB e era reprovado; hoje cabe com folga. Ver §6.

---

## 3. Título, tagline, descrição curta

**Título:** `Succubus Shop`

**Tagline (a linha curta embaixo do título — 116 e 110 caracteres; a PT são 122 bytes e
**não** cabe: o campo mede byte, ver §5):**

- PT: `Gerencie uma loja de relíquias no submundo: forja, fiado, invasões e sete finais — com uma succubus atrás do balcão.`
- EN: `Run an infernal relic shop: forging, credit, invasions and seven endings — with a succubus behind the counter.`

**Short description (o parágrafo nos cards da itch.io):**

- PT: `Simulador de gestão em fantasia sombria. Você é a succubus que herdou uma loja de relíquias e precisa fazer ela pagar: fabricar, vender, fiar, expedir, se defender da rua e escolher em quem gastar cada ponto de talento. Sete capítulos, sete desfechos, reencarnação do império e uma clientela que lembra do seu nome.`
- EN: `A management sim set in dark fantasy. You are the succubus who inherited a relic shop and has to make it pay: forge, sell, extend credit, send expeditions, defend the door and choose where every talent point goes. Seven chapters, seven endings, a dynasty you can reincarnate, and regulars who remember your name.`

---

## 4. Descrição longa (markdown, cole direto)

### PT-BR

```markdown
Uma succubus herdou a loja de relíquias da família — e o buraco no caixa.

**Succubus Shop** é um simulador de gestão com campanha. Nada de clique infinito:
a casa tem um dia que vira, uma rua que acorda de um humor, e uma conta que cobra.

**O balcão.** Os clientes entram sozinhos, escolhem o que está na prateleira e
reclamam se não encontram. Preço, reputação e fila se mexem conforme o estoque
encalha ou some — o mercado reage ao seu movimento, não ao contrário.

**A forja.** Seis ingredientes, seis níveis de qualidade, e o topo do espectro
tem porta: Lendário só entra no rolo depois de seis degraus somados entre
Alquimia, Biblioteca e vidas já reencarnadas.

**O prazo.** Mercadoria apodrece. Cada virada de dia derruba um degrau da peça
mais antiga da estante, e o Depósito de sal vende prazo em ouro.

**A rua.** Três rivais acendem placa em dias fixos e levam corpo da sua porta e
dinheiro do bolso de quem entra. A resposta é comprar a placa. Já a visita grande
bate com poder de 22 a 112, e só se resolve com as mãos que a casa já paga.

**A casa.** Custo diário, dívida com teto, livro de fiado que cobra, filiais fora
do salão, funcionários com salário na conta da manhã. E, quando o caixa aperta
mesmo, o desfecho de ruína.

**A vida longa.** Sete capítulos, sete desfechos (cinco de facção, o da casa e o da ruína),
pedidos escritos das cinco facções que pagam privilégio permanente, árvore de
talento com dois ofícios concorrentes por trilha — assinar um raspa o outro até a
próxima vida — e reencarnação do império com aura, dotes e placar por temporada.

**A mesa.** Seis idiomas na primeira abertura. Tutorial que não para o jogo.
Menu no ESC. Cena sensual é tom, não nudez: existe um botão, e ele muda a voz da
loja sem mover um número dela.

## Como jogar no navegador

O save no navegador mora no armazenamento do site: nada sai para arquivo, e
limpar os dados do navegador apaga a loja. Se você quer garantir o progresso,
jogue no build de mesa, que tem exportar e importar save.

## avisos de conteúdo

Fantasia sombria com temas adultos tratados em tom sugestivo: flerte, insinuação,
poses provocantes. **Nenhuma nudez explícita em nenhum modo.** Há um botão de
conteúdo sensual no menu, e desligá-lo não corta progressão, economia ou conquistas.

## ficha técnica

Godot 4.7 • 1280×720 • `gl_compatibility` (roda em GPU integrada e no navegador) •
seis idiomas • alpha jogável em desenvolvimento.
```

### English

```markdown
A succubus inherited the family's relic shop — and the hole in the till.

**Succubus Shop** is a management sim with a campaign. No infinite clicking: the
house has a day that turns, a street that wakes up in a mood, and a bill that comes.

**The counter.** Customers walk in on their own, buy what is on the shelf and
complain when it isn't. Price, reputation and the queue move as stock stalls or runs
out — the market reacts to you, not the other way round.

**The forge.** Six ingredients, six quality tiers, and the top of the spectrum has a
door: Legendary only enters the roll after six steps summed across Alchemy, the
Library and lives already reincarnated.

**The shelf life.** Goods rot. Each day turns one step down on the oldest item, and
the Salt Depot sells time for gold.

**The street.** Three rivals raise a sign on fixed days and take bodies from your
door and coin from your customers' purses. The answer is to buy the sign. The big
visit knocks with power 22 to 112, and only hands the house already pays can hold it.

**The house.** Daily upkeep, debt with a ceiling, a credit ledger that actually
collects, branches outside the hall, staff on the morning bill — and, when the box
squeezes for real, the ruin ending.

**The long game.** Seven chapters, seven endings (six by faction plus ruin), written
requests from all five factions that pay permanent privilege, a talent tree with two
rival trades per track — signing one erases the other until your next life — and a
dynasty you reincarnate with auras, permanent perks and a seasonal scoreboard.

**The table.** Six languages on first launch. A tutorial that never stops the game.
An ESC menu. Sensual content is tone, not nudity: one switch, and it changes the shop's
voice without moving a single number in it.

## Playing in the browser

In the browser the save lives in the site's storage: nothing goes out to a file, and
clearing browser data erases the shop. Want to keep progress for sure? Use the desktop
build, which exports and imports save files.

## content warnings

Dark fantasy with adult themes handled suggestively: flirting, innuendo, provocative
poses. **No explicit nudity in any mode.** There is a sensual-content switch in the
menu, and turning it off cuts no progression, economy or achievement.

## tech

Godot 4.7 • 1280×720 • `gl_compatibility` (runs on integrated GPUs and in the browser) •
six languages • playable alpha in development.
```

---

## 5. Campos da itch.io

| Campo | Valor |
|---|---|
| Classification | **Games** |
| Type | **Play in browser** (o zip web) **+ Downloadable** (Windows e Linux) |
| Genre / Tags | Gênero: `simulation`. Tags (só do catálogo da vitrine): `godot`, `management`, `dark-fantasy`, `fantasy`, `economy`, `story-rich`, `female-protagonist`, `incremental`, `ai-generated`. **Não existem** `shop-sim` nem `portuguese`: o campo de tags é uma lista fechada de 622 termos e recusa texto novo |
| Content warning | A página de metadados da itch.io **não tem** categoria de conteúdo sexual: só dois checkboxes — *Has sensitive content* (marcado) e *Show content warning* (marcado). Com os dois ligados o visitante passa pelo aviso antes da página, e o texto "sexual themes, no nudity" fica na descrição (§4). **Não** há como marcar "nudez" nem "não-nudez": o que se promete é o que está escrito |
| Status | **In Progress** |
| Multiplayer | nenhum (mín/máx 1 jogador) |
| Inputs | mouse + teclado (ESC abre o menu) |
| Language | Portuguese, Portuguese (Brazil), English, Spanish, French, Italian, German — o campo é código ISO; `pt` e `pt-BR` marcados para o jogo aparecer nos dois filtros |
| Accessibility | *Interactive tutorial* (o único item da lista que o jogo entrega hoje; *configurable controls* não existe, então não foi marcado) |
| Session duration | *About an hour* por objetivo (capítulo) |
| Cover image | 625×322 — `marketing/itch/out/capa-A-pt-625x322.png` (variante A, salão com a chefe). Mínimo aceito: 315×250; recomendado 630×500 |
| Banner | **não existe campo de banner** na página de projeto da itch.io: capa + galeria é que são renderizados |
| Thumbnail | 16:9 — a própria capa |
| Screenshots / gallery | os sete `screenshots/gallery_*.png` |
| Release name | `v0.1.0-alpha.6` — o número vai no nome do zip e, dentro do jogo, em `config/version` |
| Notes no arquivo | escreva "alpha em desenvolvimento; save no navegador fica no armazenamento do site" |
| Available platforms | Windows, Linux, HTML5 |
| Pricing | **"Name your own price"** — é o que o modo *free* com doação renderiza na página pública. Não existe campo "pague o que quiser" com mínimo: os três modos são `free`, `paid`, `disable_payments`, e `paid` exige mínimo > 0 (a vitrine rejeita o save com *"paid projects must have a price set"*). Conta sem forma de pagamento configurada também não pode ter preço: o aviso na tela é *"no one will be able to download your project"* |

**Tagline tem teto de 120 BYTES, não de caracteres.** A frase PT do §3 (116 caracteres
acentuados) são 122 bytes em UTF-8 e o save devolve *"expected text between 1 and 120
characters"* sem dizer que a régua é de byte. A versão publicada, de 97 bytes:
`Forja, fiado, invasões e sete finais — a succubus que herdou a loja de relíquias da família.`

**Nome de arquivo** — o script gera:

```
Succubus-Shop-0.1.0-alpha.6-windows.zip
Succubus-Shop-0.1.0-alpha.6-linux.zip
Succubus-Shop-0.1.0-alpha.6-web.zip
```

---

## 6. O build web é grande: o que fazer com isso

Medido no primeiro export de verdade, não estimado:

| Estado da arte | Cache de textura (`.godot/imported`) | `index.pck` | Veredito |
|---|---|---|---|
| sem perdas (`compress/mode=0` — como estava) | 204,3 MB | **207,33 MB** | **reprovado**: a itch.io limita cada arquivo descompactado a 200 MB |
| Com perdas por classe (`tools/set_texture_budget.py`, `compress/mode=1` = WebP) | 58,5 MB | **43,47 MB** | aprovado, com folga de ~4,6× |
| o mesmo, com as duas fontes de símbolo embarcadas (§8) | +3,51 MB de `.fontdata` | **48,61 MB** | aprovado, com folga de ~4,1× |

Duas crenças desta seção caíram na medição:

1. A distribuição de pixels contava `assets/` e dava 161,75 Mpx; a árvore toda (poses,
   cenários, impressos) tem **667 PNG e 169,60 Mpx**.
2. O texto assumia compressão VRAM no `.pck` ("um conjunto ≈ 81 MB, dois ≈ 162 MB").
   Nenhuma textura do projeto pedia conjunto VRAM: `vram_texture_compression` no preset
   não reencodeia pixel nenhum, e o `.pck` embarcava a arte **sem perdas** (`mode=0`). Por
   isso ele
   estourava os 200 MB, e por isso a alavanca tinha de ser o modo de compressão da
   textura, não o preset.

A conta por classe, que é o que o script usa:

| Classe | Arquivos | Mpx | MB na árvore | `.ctex` embarcado | aplicada |
|---|---|---|---|---|---|
| opacas (fundos pintados, onde a perda não se vê) | 57 | 123,99 | 199,84 | 21,81 MB (0,176 B/texel) | `compress/mode=1`, q=0,85 |
| com alfa (recorte de personagem e de objeto) | 610 | 45,61 | 75,03 | 19,65 MB (0,431 B/texel) | `compress/mode=1`, q=0,92 |
| **total** | **667** | **169,60** | **274,87** | **41,46 MB** | — |

O alfa recebe qualidade maior porque a borda recortada é justamente o que o olho pega —
é o contrato do recorte fiel às curvas, medido em `tools/probes/recorte.gd`.

BPP usados na projeção do script (`BPP_LOSSY_OPAQUE` / `BPP_LOSSY_ALPHA` em
`tools/set_texture_budget.py`): lossless 1,07 B/texel; lossy q=0,85 em arte opaca **0,21**;
lossy q=0,92 em arte com alfa **0,37**. Aplicados aos 123,99 + 45,61 Mpx da tabela, isso
projeta 42,92 MB contra os **43,47 MB** do `.pck` real — 0,55 MB de erro, que é o tipo de
conta que se revalida antes de prometer a folga. Pesados os 667 `.ctex` um por um, o erro por
classe é maior do que o total sugere: as opacas saem 0,176 B/texel (a projeção cobrava 0,21)
e as com alfa 0,431 (cobrava 0,37); os dois lados se cancelam e fecham em **41,46 MB** de
textura embarcada. O cache de `.godot/imported` **não** é a
régua dessa medida: ele ainda carrega entradas dos exports anteriores. Basis/UASTC
(`mode=3`) custa 3,00 B/texel e foi reprovado na medição: 508 MB.

O `.wasm` custa 39,51 MB e não depende da arte. Com as fontes do §8 dentro, o download
total do navegador é **58,35 MB compactados** (`.zip` de 58.352.045 bytes; **57,81 MB**, `.zip` de 57.811.416, com as sondas excluídas; **60,01 MB**, `.zip` de 60.008.512, com o MP3 da trilha clássica de volta — §10) — eram 53,45 MB
antes delas, e o `.pck` é o que cresce: 43.469.492 → 48.607.204 → 48.049.800 → 50.256.952
bytes. Um build honesto
para o navegador: o maior arquivo extraído (o `.pck`, 50,26 MB) cabe 4,0× no teto de 200 MB
por arquivo.

O que a mudança **não** é: os PNGs do repositório continuam os mesmos. Quem decide a
codificação são os 667 `.png.import` (659 em `assets/`, 8 em `screenshots/`), commitados
junto. `python tools/set_texture_budget.py
--reset` devolve tudo para `mode=0` e o próximo `--import` re-encodeia sem perdas.

**Nome do codificador, conferido no contêiner.** O `compress/mode=1` do Godot 4 grava um
**WebP com perdas** dentro do `.ctex`: nas quatro texturas abertas (as duas classes, tamanhos
de 144×422 a 2560×1440) a assinatura `WEBP` aparece no mesmo offset 64, depois do cabeçalho
`GST2` (versão, largura, altura, formato, mipmaps). A árvore continua sem nenhum `.webp`
**fonte** — os 667 arquivos são PNG, e quem escolhe a codificação é o importador. Nota de
método, porque o erro aconteceu nesta rodada: concluir "não é WebP" pela ausência de `.webp`
na árvore é ler o contêiner pelo nome do arquivo. A assinatura se abre nos bytes, não no
`find`.

**O que ainda falta aqui é olho humano.** WebP com perdas em arte pintada é escolha de
gosto, não de byte: abrir o build no navegador e conferir o recorte dos personagens e o
ruido nas paredes escuras antes de publicar (§8). As outras saídas da lista antiga
(publicar só mesa, variantes de assets por export, avisar e deixar) continuam
disponíveis, mas nenhuma é necessária com o `.pck` em 43,47 MB.

---

## 7. Passo a passo

> A página foi publicada em 2026-10-19; o resultado item por item desta lista está no §11.
> O único item que continua em aberto é o de **olho humano**: o build web abre e o console
> fica limpo, mas o recorte dos personagens e o ruído nas paredes escuras são escolha de
> gosto, e quem confere é você.

```bash
# 1. uma vez só, no editor: Editor > Manage Export Templates > Download

# 2. gerar os três zips
GODOT="/c/Users/gmore/godot/godot" bash tools/build_itch.sh

# 3. só um alvo, se estiver depurando
GODOT="/c/Users/gmore/godot/godot" bash tools/build_itch.sh --only web
```

Antes de marcar *Publish*, confira:

- [ ] `bash tools/build_itch.sh` terminou com os três `.zip` listados
- [ ] o zip web tem `index.html` **na raiz** (o script confere e diz `✓` ou `QUEBRA`)
- [ ] o zip linux tem o binário em modo `rwxr-xr-x` (`zipinfo` confere; sem
      `marcar_execucao()` o Windows empacota `-rw----` e o jogador não consegue rodar)
- [ ] nenhum arquivo descompactado passa de 200 MB
- [ ] o build web abre no navegador **sem** os botões de exportar/importar save, e com o
      aviso no lugar (isso é medido em `tools/probes/publicar.gd`, dos dois lados)
- [ ] o build web aberto no Chrome mostra `♥` vermelho, `★` dourado, `☰` e `▶` desenhados,
      sem nenhum tofu `▯` na tela (§8) — e o console do navegador fica limpo, sem o aviso
      de "fonte embarcada ausente"
- [ ] os binários de mesa **não** carregam as fontes: `grep -c NotoColorEmoji` no `.exe` e
      no `.x86_64` devolve `0`
- [ ] o build de mesa **tem** os dois botões
- [ ] o seletor de idioma aparece na primeira abertura das três plataformas
- [ ] a tagline e a descrição longa estão na página, nas duas línguas
- [ ] o aviso de conteúdo diz "sexual themes", não "nudity"
- [ ] `README.md` e a página dizem a mesma versão

## 8. O que ainda não dá para prometer

- **Conquistas na itch.io.** As 100 conquistas existem no jogo e na Steam; a itch.io não
  tem achievements, então a página pode dizer "100 conquistas para caçar", não que elas
  desbloqueiam algo na vitrine.
- **Nuvem.** Save em nuvem é Steam Cloud. No navegador, o save é do site e limpar dados
  o apaga — o jogo avisa isso na própria tela de save.
- **Mobile: marcado, e com uma ressalva que só o dedo fecha.** A afirmação antiga
  ("a UI foi desenhada para 1280×720 com mouse, não marque mobile friendly") venceu quando a
  UI de toque entrou no jogo (`main.gd::_fit_touch`, sonda `tools/probes/toque.gd`) e o
  `mobile_friendly` foi marcado na itch. O que autoriza o checkbox: (a) export **single-threaded**
  (`variant/thread_support=false`), que é o modo que a doc oficial da Godot descreve como o que
  funciona bem em macOS/iOS; (b) SharedArrayBuffer **desligado** na vitrine, porque ligá-lo é que
  quebraria o Safari. O que não foi medido: o jogo aberto num iPhone de verdade — o Safari tem
  problemas de WebGL 2.0 que os outros navegadores não têm, e checkbox nenhum substitui isso.
  A régua final fechou em 2026-10-20: relida do servidor, `embed[mobile_friendly]=true` e
  `embed[cdn_type]=false`, a página pública não mostra **aviso nenhum** de celular, e o parágrafo
  "No iPhone e no iPad" está na vitrine. O que continua sem medição é o aparelho: o texto promete
  o caminho, não o desempenho.
- **Os emoji do navegador: resolvido, com o número errado que eu prometi.** Medido no
  primeiro build web aberto no Chrome: **84 codepoints** que a fonte padrão do motor não
  desenha (emoji colorido e símbolos de interface — `♥ ★ ☰ ✓ ✦ ▸ ░ █ ─ ← → ≈ ∞ ✗  ✕`),
  somando 3.206 usos nos `.gd`. No desktop eles saem porque o motor pede a fonte ao sistema
  operacional; no navegador não há sistema operacional por trás, e cada um virava o tofu `▯`.
  A rota escolhida foi embarcar a fonte: `Noto Color Emoji` (OFL) para os 63 coloridos e
  `DejaVu Sans` (Bitstream Vera) para os 21 monocromáticos, montados como **cadeia de
  fallback** — nunca como fonte padrão, porque trocar a padrão moveria a métrica de todo
  texto do jogo. A colorida vem primeiro na cadeia porque a DejaVu também desenha vários dos
  63 e, se vier antes, o emoji sai preto-e-branco. Fiação em `main.gd:_setup_web_fonts()`,
  chamada em `_ready()` só quando `web_build`.
  **A promessa de tamanho estava errada, e o erro foi a favor do jogador:** o arquivo oficial
  da Noto tem 25.332.736 bytes; a tabela `SVG ` (só para navegador, 20.288.281 B) é arrancada
  por `tools/strip_font_svg.py` e o que embarca mede 5.044.436 B. No `.pck`, o `.fontdata`
  importado custa 3.082.128 B (emoji) + 429.187 B (DejaVu). O `.pck` web cresceu 5.137.712 B
  porque leva também o `.ttf` cru. **O download** subiu de 53,45 MB para **58,35 MB** (**57,81 MB** no build de hoje) — não os
  "~64 MB" prometidos. Nos dois presets de mesa `exclude_filter` tem `fonts/*.ttf`, e o
  resultado foi conferido no binário: **0** ocorrências de `NotoColorEmoji` no `.exe` de
  154.222.744 B e no `.x86_64` de 118.614.472 B; as mesas cresceram só 0,02 MB (os `.txt` de licença, que o
  filtro não alcança).
  **Prova, não aparência:** união 84/84 conferida glifo por glifo; a A/B de 200 tiques na
  mesma semente rodou 6 processos com a cadeia e 6 sem, `MEDIDA` byte por byte idêntica
  (`dia=11 ouro=809 fama=0 atendidos=5 afeto=27 furia=5 prateleira=6 vinculos=1`) e 0 crashes
  nos 12; no Chrome aberto pelo servidor local o `♥` saiu vermelho, o `★` dourado, o `☰` e o
  `▶` desenhados, sem nenhum `▯` na tela, e o console limpo. Licenças no repo em
  `fonts/OFL-NotoColorEmoji.txt` e `fonts/LICENSE-DejaVuSans.txt`.
  **O que ainda não foi visto:** o build final foi reaberto no Chrome e a primeira tela — o
  seletor de idioma, que é a mesma camada do menu — saiu com o rodapé `Versão: 0.1.0-alpha.6`
  desenhado, os glifos coloridos e o console limpo. Mas o clique sintético no `☰` não chega
  ao canvas (o Godot ignora evento não-confiável), então as telas internas (opções,
  conquistas, salvar) continuam sem print do navegador — vale abrir o `.zip` no itch.io e
  bater o olho antes de marcar *Publish*. E o harness que mediu os crashes (`_tmp_flaky.gd`,
  promovido a `tools/probes/fonte_frequencia.gd`) deixou um achado registrado: um FATAL
  intermitente do TextServer cai em ~metade dos processos quando um `Label` novo com esses
  glifos entra numa árvore de jogo já rodando, **com ou sem** a cadeia — a cadeia foi absolvida
  pela frequência (`flat` 4/8, `nested` 5/8, `emoji` 5/8, nenhuma fiação 5/12; com texto ASCII,
  0/12). É caminho do motor no headless do Windows, não do recurso: a rota publicada ficou
  limpa nos 12 processos.
- **A arte com perdas precisa do seu olho.** O `.pck` caiu para 43,47 MB com WebP q=0,85
  (opacas) e q=0,92 (com alfa). No print do build web a borda dos personagens e as paredes
  escuras estão limpas, mas isso foi visto por uma máquina, não por você.
- **Data de "1.0".** Ainda falta balanceamento e a aprovação visual do chão, da oclusão
  e do timing de animação no editor, que só você pode dar.

---

## 9. A release de mesa: `v0.1.0-alpha.6`

A vitrine da itch.io espera upload manual. A **release do GitHub não**: o workflow
`.github/workflows/alpha-release.yml` é disparado por qualquer tag `v*-alpha.*`, baixa o
Godot 4.7.2 e os templates no runner, exporta o preset `Windows Desktop`, empacota e
publica uma **pré-release** com `gh release create`. Subir a release é, portanto, um
`git push origin v0.1.0-alpha.6` — não um clipe de arquivo numa página.

Dois contratos entraram nesse workflow nesta rodada, porque a página mentir sobre o
arquivo é pior que não ter página:

- **O nome do asset sai de `config/version`.** A alpha.5 foi publicada como
  `Succubus-Shop-Windows-Alpha.zip`, nome que não diz a versão e que não é o nome que o
  README cita. Hoje os dois caminhos (CI e `tools/build_itch.sh`) produzem
  `Succubus-Shop-<versão>-windows.zip`.
- **O `.exe` é conferido pelo recurso de versão.** Depois do export, a CI lê
  `VersionInfo.FileVersion` do binário e exige que ele comece pelo núcleo de
  `config/version` (`0.1.0`). É a regra que `tools/probes/publicar.gd` já cobrava no
  preset, agora cobrava no arquivo que o jogador baixa — o explorador mostra a versão do
  `.exe`, não a do jogo.

### Medido no build publicado da alpha.6 (trilha só em WAV)

| Arquivo | Bytes | MB |
|---|---|---|
| `Succubus-Shop-0.1.0-alpha.6-windows.zip` | 82.098.382 | 82,10 |
| `.export/windows/Succubus Shop.exe` (extraído, `.pck` embutido) | 153.665.336 | 153,67 |
| `Succubus-Shop-0.1.0-alpha.6-linux.zip` (após gravar o modo unix) | 73.351.720 | 73,35 |
| `Succubus-Shop-0.1.0-alpha.6-web.zip` | 57.811.416 | 57,81 |
| `.export/web/index.pck` | 48.049.800 | 48,05 |

Estes números descrevem o **asset publicado** da `v0.1.0-alpha.6`. A árvore atual tem a
trilha em duas faixas e mede mais pesado: ver §10.

### O que o pacote do jogador não leva mais

`tools/probes/*.gd` (36 sondas promovidas) e `_tmp_*.gd` (36 sondas soltas de outras
sessões) eram empacotados nos três presets: o índice do `.pck` listava os 72 caminhos.
Nenhum arquivo do jogo referencia `res://tools/` — conferido em `.gd`, `.tscn` e `.tres`,
zero ocorrências —, então `exclude_filter` ganhou `_tmp_*.gd,tools/*` nos três alvos.
O `.pck` do navegador caiu 568.664 bytes e o `.exe` de mesa, 540.914. Conferido no
binário exportado: `res://main.tscn` está dentro, `res://tools/probes/` não.

Provar sem mexer no portão: `tools/build_itch.sh` agora recusa um alvo cujo molde de
release não existe (`windows_release_x86_64.exe`, `linux_release.x86_64`,
`web_nothreads_release.zip`). O preflight só olhava `version.txt`, que existe em cópia
parcial de templates — com `APPDATA` apontando para o diretório descartável das sondas, o
export web tinha os `.zip` mas faltavam os `.exe`, e a cadeia morria depois de importar a
árvore inteira. Agora morre em dois segundos, com o nome do arquivo que falta.

### O que a alpha.6 traz sobre a alpha.5 publicada

Sessenta commits. O que muda na mão de quem joga, em prosa:

- **Onboarding**: painel *COMO SE JOGA* e o cartaz do primeiro dia, que explicam a rua
  antes de o jogador adivinhar.
- **Seis idiomas** no catálogo (francês, italiano e alemão entraram depois da alpha.5),
  com paridade de **228 chaves** conferida sonda a sonda.
- **Livro de Fiado** (#75), **clientes VIP** (#78) e **cartaz do combo** (#80) — a alpha.5
  publicada não tem nenhum dos três.
- **Casa que cresce em arte real** por faixa de progresso, com recorte fiel às curvas dos
  móveis (#83, #84, #85, #86, #93) e elenco que não flutua nem fica anão na sala de
  expedições (#87, #92).
- **Trilha em WAV sintetizado** no lugar do MP3 que vazava recurso ao fechar a janela
  (#101), emoji colorido no build web (#103) e a loja anunciando a própria versão em toda
  tela do menu (#106).
- **Registros da casa** (#107): oito seções de marco no menu, que só leem.
- **README virou contrato medido** (#98): cada número que a página cita tem uma asserção
  no motor, e a sonda reprova quando o texto e o código discordam.

---

## 10. A trilha voltou a ser duas faixas — o que isso custa ao pacote

O pedido do jogador foi explícito: a gravação antiga era mais empolgante e a sintetizada,
baixo astral demais para o salão. Desde este commit a casa tem **duas faixas e a situação
escolhe o turno** (`main.gd`, `_music_situation()` com a chave `track`):

| Faixa | Arquivo | Medido | Turno |
|---|---|---|---|
| clássica | `assets/shop_theme_loop.mp3` | 2.205.424 bytes, 91,64 s, 192 kbps mono 44,1 kHz, md5 `c27893dde0957857c943ccf8f28a4aea` | salão, forja, biblioteca, santuário, estrada |
| sombria | `audio/shop_theme_loop.wav` | 2.016.044 bytes, 45,71 s, 22.050 Hz, 2.016.000 amostras | alarme na porta, casa na ruína, vigário na calçada |

O MP3 não foi regenerado: voltou do próprio histórico do repositório com
`git restore --source=e63a5eb^`, o mesmo blob que saiu em `e63a5eb`. Nenhum pitch, nenhum dB
mudou — a tabela que o §2 e o README publicam continua a mesma, e é a mesma sonda
(`tools/probes/porta.gd`) que a imprime.

### Custo real nos três alvos

Reexportados com `GODOT=... bash tools/build_itch.sh` no `%APPDATA%` real (nunca no
diretório descartável das sondas: lá faltam molde de release e o export morre depois de
importar a árvore inteira):

| Arquivo | Antes (alpha.6 publicado) | Agora | Delta |
|---|---|---|---|
| `.export/web/index.pck` | 48.049.800 | **50.256.952** | +2.207.152 |
| `Succubus-Shop-0.1.0-alpha.6-web.zip` | 57.811.416 | **60.008.512** | +2.197.096 |
| `Succubus-Shop-0.1.0-alpha.6-windows.zip` | 82.098.382 | **84.297.687** | +2.199.305 |
| `.export/windows/Succubus Shop.exe` | 153.665.336 | **155.872.504** | +2.207.168 |
| `Succubus-Shop-0.1.0-alpha.6-linux.zip` | 73.351.720 | **75.549.335** | +2.197.615 |

O delta do `.pck` é o arquivo cru mais 1,7 KB de índice — áudio não passa por compressão
VRAM nem por reencode. O maior arquivo extraído segue sendo o `.pck` do navegador, agora com
**50,26 MB**: cabe 4,0× no teto de 200 MB por arquivo da itch.io. Confiere-se o embarque pelo
**índice de caminhos** do binário, não pelo grep de string de UI (o script vai compilado):
`res://assets/shop_theme_loop.mp3` e `res://audio/shop_theme_loop.wav` aparecem os dois no
`.pck` web, no `.exe` de mesa e no `x86_64` de Linux.

### A itch.io já serve a trilha dupla

`config/version` segue `0.1.0-alpha.6` e nenhuma tag nova foi cortada. Mas a vitrine
**não** é mais o build WAV-only: em 2026-10-19 os três arquivos da página foram
reenviados com os artefatos deste commit — web 60.008.512, windows 84.297.687, linux
75.549.335 bytes (§11). Quem baixa a alpha.6 hoje recebe o pacote com o MP3.

Isso cruza a linha que a seção seguinte reserva ao dono da conta: **o MP3 sem procedência
registrada está público na itch.io agora**, embarcado nos três alvos. Se a resposta for
"não", o caminho é tirar `assets/shop_theme_loop.mp3` da árvore, reexportar e reenviar —
não há como voltar ao zip WAV-only que estava no ar, porque ele foi sobrescrito no
repositório de export.

### A licença do MP3 é a dúvida que fica

O arquivo entrou no repositório em `cb5b641` (12/10/2026), autoria **Manus**
(`Co-authored-by: Manus <dev-agent@manus.ai>`), sem procedência registrada em lugar nenhum.
O §8 já lista "arte, áudio e animação originais, com licença verificada" como trabalho
pendente da loja, e foi exatamente essa lacuna que motivou `e63a5eb` a trocar a trilha por
uma sintetizada pelo projeto. Ela está reposta por pedido do jogador e o blob já é público no
histórico do próprio repositório, então nada vaza de novo ao embarcá-lo — mas **subir o
build com o MP3 para a itch.io é decisão de licença, não de build**, e quem a toma é o dono.
A alternativa medida está no §9: o mesmo jogo com a trilha só em WAV custa 2,20 MB a menos.

### O vazamento do fechamento: o que mudou de verdade

A troca de formato nunca foi a causa do `2 ObjectDB instances were leaked` /
`1 resources still in use`. A causa é o `AudioStreamPlayer.stop()`: ele **agenda** a
destruição do playback na thread de áudio, e um processo que chama `quit()` em seguida nunca
cede os frames que essa destruição precisa. Por isso o corte certo era o de ouvido, não o de
contêiner — e ele está em `main.gd`:

```gd
func _trilha_audivel() -> bool:
    return DisplayServer.get_name() != "headless"
```

Medido com a dupla faixa no ar:

| Modo da sonda | Rodadas | Linhas de vazamento |
|---|---|---|
| `musica.gd` em `confere` + `menu` (headless, nada toca) | 9 | **0** |
| `musica.gd` em `tocando` (reprodução forçada) | 7 | 2 |

Na rodada forçada com `--verbose`, os dois instâncias nomeadas são `AudioStreamMP3` e
`AudioStreamPlaybackMP3` e o recurso é `res://assets/shop_theme_loop.mp3`; com o WAV sozinho
a mesma intermitência apareceu em 1 rodada de 5. Ou seja: **o contêiner só muda o nome que o
log imprime**. Fechando a janela com o ✕ enquanto a trilha toca, aquelas duas linhas podem
voltar — nenhum portão de push as vê, porque o portão roda headless e headless não toca. Não
existe mais baseline tolerada no grep do portão: o que passa é zero.

---

## 11. A página no ar — `shininoobi.itch.io/succubus-shop`

Publicada em 2026-10-19 pelo editor web da conta (a API com chave de usuário é **somente
leitura**: ela entrega o registro do jogo e os arquivos, mas não escreve página nenhuma).
Estado conferido na página pública, não no formulário:

| Campo | No ar |
|---|---|
| Status | *Published*, plataforma `HTML5, Windows, Linux`, gênero `Simulation`, status *In progress* |
| Preço | *Name your own price* (modo `free` + doação) |
| Arquivos | web 57 MB · windows 80 MB · linux 72 MB — os três são os artefatos da trilha dupla (§10) |
| Embed | 1280×720, *Embed in page*, botão de fullscreen ligado, sem auto-start, sem scrollbars, **sem** `SharedArrayBuffer` (o build é no-threads — marcar essa caixa pediria um cabeçalho que a itch.io não manda) |
| Prova de fogo | o iframe do build web abre, mostra o seletor de idioma com as seis línguas e `Versão: 0.1.0-alpha.6` no rodapé, console limpo |
| Capa / galeria | capa 625×322 (variante A) + os sete `screenshots/gallery_*.png`; `og:image` aponta para a capa |
| Metadados | teclado+mouse · `pt`, `pt-BR`, `en`, `es`, `fr`, `it`, `de` · *Interactive tutorial* · 1 jogador · *About an hour* · *Has sensitive content* + *Show content warning* |

Quatro armadilhas que só apareceram na hora de clicar em *Publish*:

- **O *Embed options* não existe até o zip web ser enviado com o projeto já marcado como
  HTML5.** A sequência importa: criar os arquivos com `Kind = Downloadable` e depois trocar
  para `HTML Game` deixa a página inteira no erro *"You've selected a HTML5 game but haven't
  configured how your project is embedded"* — sem erro no save, sem nada no formulário. A
  seção só é renderizada (por JS, então um `curl` no HTML não a vê) depois de reenviar o zip
  **com o tipo já salvo** e com ele na **primeira linha** da lista de arquivos. Foi o que
  custou um reenvio de 60 MB nesta rodada.
- **Reenviar um arquivo de mesmo nome substitui a linha** (o id muda, a posição volta para o
  fim): depois de reenviar o web zip foi preciso movê-lo de novo para a posição 0, senão o
  embed aponta para o arquivo errado — conferido no `src` do iframe (`html-classic.itch.zone/html/<id>/`).
- **Os bytes enviados não batiam com os do disco.** As três linhas diziam `alpha.6` e
  55/78/70 MB, que são os zips da **alpha.5**: o upload tinha lido a pasta de export antes do
  reexport da trilha dupla. A régua honesta é comparar o tamanho que a vitrine mostra com
  `ls -l .export/itch` — foi assim que a divergência apareceu.
- **`butler` não é obrigatório, mas falta.** Sem butler o envio é o arrastar-e-soltar do
  navegador; funciona, não tem retomada e não confere hash. Para as próximas alphas,
  `butler push` dá versão, canal e checksum de graça.

O que a vitrine **não** entrega e a página não promete: conquistas da Steam, save em nuvem,
jogo em celular, e o aviso de conteúdo sexual como categoria — a itch.io só tem o checkbox de
conteúdo sensível, e o texto do aviso mora na descrição (§4).

---

## 12. O tema da página — editor nativo, sem CSS

Aplicado em 2026-10-19. A itch.io **não libera o editor de CSS por conta própria** (o
`/docs/creators/css-guide` diz que o acesso é pedido caso a caso e negado a conta vazia), e o
tema não tem URL própria: sete endereços chutados (`/appearance`, `/theme`, `/styles`,
`/customize`…) dão 404. O editor é o botão **Edit theme** na página pública, que abre uma
gaveta lateral (`init_GameThemeEditor`) cujo `submit_url` é o próprio `/edit`. Tudo abaixo é
campo nativo daquela gaveta.

Paleta tirada da UI do jogo, não inventada:

| Campo | Valor |
|---|---|
| `bg_color` / `bg2_color` | `#120a18` / `#1d1226` |
| `bg2_alpha` | `90` — a caixa de conteúdo deixa 10 % do fundo vazar; abaixo de ~85 o texto começa a brigar com a arte |
| `text_color` / `link_color` | `#e6dced` / `#e05299` |
| `header_text_color` / `button_color` | `#f0b429` / `#a01f63` (a itch calcula o branco do botão e a borda `#442f55` sozinha) |
| `font_family` / `font_size` | `lato` / `large` |
| `header_font_family` | `Grenze Gotisch` |
| `screenshots_loc` | `sidebar` |
| `banner_image` | id `31091238` — faixa 1600×500, JPEG 195 KB, recorte de `assets/expedition_hall_scene.png` (os dois estandartes + a mesa do mapa) |
| `background_image` | id `31091266` — 1600×914, JPEG 294 KB de `assets/library_tidy_scene.png`, `no-repeat`, `align_center`, `fixed` |
| `embed_background_image` | vazio de propósito: o canvas 1280×720 cobre a área e arte atrás só faz ruído na borda |

Seis coisas que só apareceram na prática:

- **O banner mantém a proporção na largura do conteúdo.** Um PNG 1792×1024 virou um herói de
  731 px que comia a viewport inteira e empurrava o jogo para baixo. Banner bom aqui é faixa
  larga (~3,2:1), não a arte cheia.
- **O fundo é servido em `/original/`.** Os dois PNGs de 3 MB pesavam ~6 MB por visita à
  página. A `image_size_limit` do uploader é 3.145.728 bytes, e as cenas do repo vivem na
  borda (2,79–2,95 MB) — ou seja, dá para estourar o limite por um nada. Recodificar em
  JPEG q0.86 levou o par para 489 KB sem diferença visível.
- **Não há PIL, ImageMagick nem ffmpeg nesta máquina.** O recorte e a compressão foram feitos
  dentro do próprio navegador: `fetch` no servidor CORS local → `createImageBitmap` →
  `canvas.drawImage` com a fonte recortada → `canvas.toBlob('image/jpeg', .86)`. Saiu mais
  simples que instalar toolchain de imagem.
- **O slider `bg2_alpha` é React com handler só no *nub* e só no teclado.** `mousedown`,
  `pointerdown` e arrastar o *nub* não movem nada; `nub.focus()` + dez `keydown ArrowLeft`
  levam de 100 a 90. É o caminho reprodutível.
- **O `input[type=file]` do uploader é filho direto de `<html>`**, não do `<body>` — por isso
  ele não aparece na árvore de acessibilidade e nenhuma ferramenta de automação o vê. (A
  `upload_file` do navegador ainda devolve `Invalid arguments for file_upload: name is not
  supported` nesta versão, então o caminho nem existe.) O que funciona: garfar
  `HTMLInputElement.prototype.click`, clicar *Upload*, e escrever `input.files` via
  `DataTransfer` + `new File([...], nome, {type:'image/jpeg'})` + `change`. O `accept` do
  campo é `image/png,image/jpeg,image/gif` — JPEG entra.
- **Trocar a imagem reseta o resto do widget? Não — mas remove e reenvia.** Com `have_upload`
  só existe o botão *Remove image*; é preciso remover, aí o *Upload* reaparece. O id novo vem
  no `input[name="layout[...][image_id]"]` depois do terceiro POST do fluxo (`upload-image` →
  `itchio.commondatastorage.googleapis.com` → `action=success`), e os três precisam voltar
  `success`. `repeat`/`align`/`fixed` sobreviveram ao reenvio.

A régua da verificação é a página pública recarregada, não a gaveta: conferir em
`getComputedStyle` que `.wrapper` tem `background-color: rgb(18,10,24)`, a URL do fundo,
`no-repeat`, `fixed`, que `--itchio_*` baterem com o formulário, que `h2` está em
`"Grenze Gotisch"` dourado e que o iframe do embed continua em
`html-classic.itch.zone/html/19879347/`. O save em si se confirma pelo corpo da resposta
(`{"success":true}`), porque o banner de "salvo" da página fica velho.

Última nota: as sete capturas da galeria têm o HUD do jogo queimado na imagem, então **não**
servem como arte de tema — daí o upload das cenas cruas de `assets/`, que são as mesmas salas
sem a sobreposição da UI.

---

## 13. O arquivo de Android — medido em 2026-10-19

O alvo Android (`preset.3` no `export_presets.cfg`) não é um `.zip`: a itch.io lê a extensão
`.apk` para marcar a plataforma sozinha, e um `.zip` de Android vira "Downloadable" sem selo
de sistema. As três decisões do arquivo, conferidas com `aapt2 dump badging` no APK final:

| Campo | Valor medido | Por quê |
|---|---|---|
| pacote | `br.com.shininoobi.succubusshop`, `versionCode 1`, `versionName 0.1.0` | nome invertido do jogo; o `versionName` é o `config/version` truncado no núcleo (três números) |
| arquiteturas | `native-code: arm64-v8a` (só) | 76,79 MB com um `.so` de 71 MB dentro; adicionar x86_64 dobraria o arquivo para instalar em dois aparelhos que quase ninguém tem |
| orientação | `android.hardware.screen.landscape` no manifesto | `screen/orientation=0` — o jogo é 1280×720 deitado, e retrato aqui é tela preta com uma faixa |
| SDK | `minSdkVersion 24`, `targetSdkVersion 36` | 24 é Android 7.0 e é o piso do template 4.7.2; o alvo 36 vem do template, não deste repo |
| texturas | ETC2/ASTC (`texture_format/etc2_astc=true`, s3tc desligado) | DXT não existe em GPU de celular; ligar os dois só incha o pacote |
| assinatura | v2 + v3, **sem** v1 | com `minSdk 24` o verificador do Android exige v2 a partir de 7.0; v1 (JAR) é o que o Play usa para compatibilidade antiga |

**A assinatura não é do Godot, e não é capricho.** Medido na primeira tentativa:
`--export-release "Android"` chega até `Assinando APK de lançamento`, imprime
`WARNING: Assinatura de Código: O keystore de lançamento não foi encontrado` e morre com
`ERROR: Project export for preset "Android" failed` — deixando o APK no disco, completo e
`DOES NOT VERIFY: Missing META-INF/MANIFEST.MF`. A senha do keystore de release só entra pela
janela do editor, e a linha de comando não tem janela. Escrever a senha no
`export_presets.cfg` seria commitar a chave do jogo. Então:

- o preset fica com `package/signed=false` e `signing/keystore=""` (assinatura nenhuma,
  `exit 0`, o arquivo sai alinhado);
- `tools/build_itch.sh --only android` faz `zipalign -p 4` → `apksigner sign` →
  `apksigner verify --print-certs`, lendo `SS_KEYSTORE`, `SS_KEYSTORE_PASS` e `SS_KEY_ALIAS`
  do **ambiente** (`--ks-pass env:`, nunca `:file:` nem linha de comando);
- o par fica fora do repo, em `D:/android-dev/keystores/`. **Este keystore é a identidade do
  aplicativo:** perder o arquivo ou a senha significa não poder mais atualizar o APK instalado
  em nenhum aparelho, porque a assinatura nova não bate com a velha. Não há segunda cópia e
  não haverá recuperação.

O caminho do `apksigner` e do `zipalign` não é adivinhado: `ANDROID_BUILD_TOOLS` (padrão
`D:/android-dev/sdk/build-tools/35.0.0`) e o `ANDROID_HOME`/`JAVA_HOME` apontando para o SDK e
o JDK 17 instalados para o export. O Godot lê os dois de
`%APPDATA%/Godot/editor_settings-4.7.tres` (`export/android/android_sdk_path` e
`export/android/java_sdk_path`) — por isso **o export usa o APPDATA real**: com o `APPDATA`
descartável das sondas, nem os templates nem o SDK são achados. O save do jogador não é
tocado pelo export; a asserção continua sendo o hash conferido antes e depois.

Sonda do layout de toque: `tools/probes/toque.gd` (§ regras em `main.gd::_fit_touch`).

### O APK subiu — 2026-10-19

O arquivo está na página como **`Android (arm64-v8a) — v0.1.0-alpha.6`**, plataforma marcada
`p_android`, tipo *Executable*, posição 5 (última). A itch.io reporta **73 mb** do mesmo
arquivo que mede 76.789.272 bytes: a casa arredonda em MiB, e 73,2 MiB é o número certo — não
há truncamento. Conferido na página pública: o selo **Download for Android** aparece ao lado
do botão.

Duas armadilhas do editor web, medidas na subida:

- **O `<input type=file>` não existe antes do clique.** `document.querySelectorAll('input[type=file]')`
  devolve lista vazia na página de edição; o botão **Choose files** (`.add_file_btn_outer button.button`)
  cria o input na hora e o solta dentro de `.add_file_btn_outer`, escondido. Automação que procura
  o input antes de clicar não acha nada. O botão errado é o `.external_file_btn`, que abre a linha
  de *External file* — e uma linha dessas, vazia, fica pendurada na página como upload fantasma.
- **Apagar upload tem dupla confirmação.** O modal exige a caixa *"I confirm I want to delete"* e só
  então libera **Delete**; sem marcar a caixa o botão fica inerte e o script acha que apagou.
  `qoder-pipeline-probe.zip` (148 bytes, resíduo da conferência de pipeline) e a linha externa vazia
  foram removidos assim — a página fica com os quatro arquivos.

## 14. O que ainda não dá para sair desta máquina

- **iOS nativo (.ipa) não existe e não pode existir aqui.** A frase da documentação oficial é
  literal: *"You must export for iOS from a computer running macOS with Xcode installed."*
  Falta o macOS, falta o Xcode, falta o Apple Developer Program (US$ 99/ano) e falta o
  `codesign`. O que dá para fazer daqui é preparar o preset e a lista de arquivos, e rodar o
  export numa máquina Apple. **O Android não tinha essa barreira** — o APK saiu do Windows e
  está na itch (73 MiB, arm64-v8a).
- **A itch.io não tem tipo de arquivo iOS — medido no DOM vivo do editor em 2026-10-20.** Cada
  linha de upload oferece seis caixas de tipo: `p_windows`, `p_linux`, `p_osx`, `p_android`,
  `embed`, `hidden`. **Não existe `p_ios`.** Mac tem linha própria; iPhone não tem, e não é
  limitação desta máquina — não há o que marcar. O campo `game[app_store_url]` existe no
  formulário (é o botão *Apple App Store* da seção de links externos) e continua vazio de
  propósito: preencher exigiria uma página real na App Store, e link mentiroso na vitrine é pior
  que link nenhum. A lista pública de downloads reflete isso: Windows, Linux e
  "Android (arm64-v8a)" — três linhas, nenhuma de iPhone.
- **O que se publica, então, é o caminho do iPhone na página — e ele foi publicado em
  2026-10-20.** O `.ipa` nunca foi o único caminho: o build **Web** que já está no ar é
  single-threaded de propósito, e é exatamente esse modo que a doc da Godot cita como o que
  *"works very well on macOS and iOS too, where it always had compatibility issues with multiple
  threads exports"*. Um jogador de iPhone abre a página da itch em Safari, toca em *Click to
  launch* e joga, sem app e sem loja. Texto gravado nos dois campos: `game[instructions]` ganhou
  o parágrafo "No iPhone e no iPad", `game[description]` ganhou o mesmo em PT e EN e a ficha
  técnica passou a ler "navegador (incluindo Safari em iPhone e iPad)". Conferência tripla: o corpo
  da resposta XHR (`{"success":true}`), uma recarga nova com os dois campos lidos do servidor, e a
  página pública exibindo os quatro trechos. Ver §8, item "Mobile".
- **GOG.** A loja não aceita submissão self-service: é formulário de candidatura com revisão
  humana, e a FAQ coloca *"Adult sexual content"* entre os itens não elegíveis — a nossa zona
  cinzenta (tema adulto, zero nudez) precisa de uma resposta deles antes de qualquer
  investimento. Lido agora até o fim (as 17 perguntas): **o formulário não pergunta nada sobre
  conteúdo**, então não há como descobrir a posição deles respondendo campo a campo — a triagem
  é curadoria humana, depois. É Typeform público, sem login. O Developer Portal, onde se sobe
  build, é por convite. A lista completa está em [`gog-epic.md`](gog-epic.md).
- **Epic Games Store.** Autocadastro que aceita pessoa física (18+, com verificação de
  documento), **US$ 100 por produto** — não por estúdio —, entrevista fiscal que gera o
  formulário W-8 e build sobe pela BuildPatch Tool, não pelo `.zip` da itch. Nada disso pode
  ser aberto por automação sem que a pessoa assuma a identidade fiscal atrás da conta; o
  checklist e as medidas exatas dos assets estão em [`gog-epic.md`](gog-epic.md).

### Correção de copy na página — 2026-10-19

A descrição em inglês afirmava *"...seven endings (six by faction plus ruin)"*. **Estava
errada**, e o erro era nosso, não da ferramenta: `endings.gd` declara sete finais — cinco com
`faction` preenchida (`guildas`, `nobres`, `aventureiros`, `mercadores`, `submundo`), mais
`casa` e `ruina` com `faction: ""`. O português já dizia o certo ("cinco de facção, o da casa
e o da ruína"). Corrigido no editor web para *"five by faction, the house one and the ruin"* e
conferido na página pública depois do reload do formulário de edição.

---

## 15. MacBook e Linux por arquitetura — medido em 2026-10-20

A pergunta foi "versão macbook e outras versões de linux, caso a publicada só abranja um tipo de
distro". A premissa de distro não se sustenta, e a de Mac sim — as duas coisas abaixo foram lidas
na documentação do motor e confirmadas no artefato.

### Linux: quem escolhe é a CPU, não a distribuição

A doc de export Linux lista **sete arquiteturas** (`x86_64`, `x86_32`, `arm64`, `arm32`, `rv64`,
`ppc64`, `loongarch64`), default `x86_64`, e diz que todo Intel/AMD moderno é `x86_64`. Não existe
eixo "distro": um binário `x86_64` roda em Ubuntu, Fedora, Arch, Mint e no Steam Deck (que é
`x86_64`) exatamente pelo mesmo motivo — a ABI, não o gerenciador de pacotes. O único buraco real
de cobertura era **arm64** (Raspberry Pi OS 64 bits, laptops ARM), e ele foi fechado:

| Item | Medido |
|---|---|
| Preset | `[preset.5]` `name="Linux (arm64)"`, `binary_format/architecture="arm64"` |
| Binário extraído | 113.825.896 B, `e_machine = 183` (AArch64) — lido no cabeçalho ELF, não chutado |
| Zip da vitrine | `Succubus-Shop-0.1.0-alpha.6-linux-arm64.zip` 75.070.219 B, binário com modo `0755` |
| Teto da itch | 200 MB por arquivo **extraído** → 113,8 MB passa com folga |

`x86_32` ficou de fora de propósito: é o único outro alvo plausível e não há quem o peça — e cada
preset a mais é um upload de ~70 MB para validar em aparelho que ninguém tem.

### Mac: exporta daqui, mas o Gatekeeper continua no caminho

Diferente do iOS (ver §14), o export de macOS **não exige** uma máquina com macOS: a própria doc
tem o ramo *"If you do not have an Apple Developer ID Certificate"* → assinatura *Built-in (ad-hoc
only)* e *Notarization = Disabled*. O que isso custa ao jogador:

- **Sem assinatura de Developer ID e sem notarização, o macOS bloqueia o app baixado de "fonte
  desconhecida"** — e a itch é uma fonte desconhecida. A página precisa ensinar o
  botão-direito → *Abrir* (ou `xattr -d com.apple.quarantine`), senão o download vira "não abre"
  sem mensagem nossa.
- **`.app` solto exportado do Windows perde o bit de execução** (frase da doc: *"Due to file system
  limitations, .app bundles exported from Windows lack the executable flag and won't run on
  macOS. Projects exported as .zip are not affected"*). Por isso o preset entrega `.zip`, e a
  ferramenta confere o modo de cada entrada.
- **DMG não dá**: a empacotamento é caminho de macOS. Zip é o formato da vitrine.

### Universal 2: provado no binário, não no texto da doc

A doc promete um binário único "Universal 2" (x86_64 + arm64) nos templates oficiais. Conferido no
cabeçalho Mach-O gordo do executável exportado:

| Slice | Offset | Tamanho |
|---|---|---|
| `x86_64` (Intel) | 32.768 | 87.608.528 B |
| `arm64` (Apple Silicon) | 87.654.400 | 83.309.248 B |

Executável: 170.963.648 B extraídos, modo `0755`; bundle com 7 entradas; zip 106.742.830 B.
**O rótulo de tamanho não é uma régua:** o editor mostra `102mb` e a página pública, `101 MB` para o
mesmo arquivo — as duas colunas arredondam MiB de jeitos diferentes (e o `linux.zip` de x86_64, que é
2 MB maior que o de arm64, sai com `72mb` nos dois por acaso). A conferência é byte de disco contra
byte de disco. **Folga de só ~29 MB no teto de
200 MB por arquivo extraído** — é a margem que qualquer alta de textura ou áudio come, e por isso o
verificador abaixo é obrigatório antes do upload, não opcional.

`tools/check_macho_fat.py` é quem mede isso no artefato: formato do zip, `Info.plist`
(`CFBundleIdentifier` / `CFBundleName` / `CFBundleShortVersionString`), modo de execução do
binário, as duas fatias do Mach-O gordo e o teto da itch. Roda dentro do `tools/build_itch.sh
macos`.

### A porta que quebrou no caminho

O gate de fim de `exportar()` conferia `basename "$APK_ANDROID"` para **todo** preset — ou seja,
para Windows/Linux/web ele procurava o nome do APK e, como o teste era `[ -f ]` de um caminho que
não existia, reprovaria. Medido pelos mtimes: o gate entrou em vigor no commit `0c82b87`
(2026-10-19 15:57) e os zips de mesa são das 12:34–12:35 do mesmo dia, **antes** dele — nunca
rodou contra um alvo de mesa. Agora o `export_path` é lido do próprio `export_presets.cfg` por
`awk`, e o gate cobra o arquivo que aquele preset declarou.

### O que a publicação mediu (2026-10-20)

As duas linhas estão no ar: `macOS (Intel + Apple Silicon) — v0.1.0-alpha.6` (upload
`19907096`, tipo `p_osx`) e `Linux (arm64) — v0.1.0-alpha.6` (`19907642`, tipo `p_linux`). A
página pública passou a listar seis arquivos e o banner de update confirmou os dois nomes novos.
Quatro coisas que só apareceram na execução:

- **Um dispatch não é um upload.** O primeiro envio do arm64 devolveu
  `{"bytes":75070219,"parts":5,"dispatched":true}` — os bytes conferidos, o evento entregue — e a
  linha **nunca existiu** no servidor: o reload seguinte mostrou 5 linhas, sem ela. A régua é a
  linha escrita `· Success` com o tamanho certo, lida depois de esperar a barra; `dispatched` não
  prova nada.
- **A itch adivinha o tipo de macOS e não adivinha o de Linux.** A linha do `.zip` do Mac nasceu
  com `p_osx` já marcado (ela lê o `Succubus Shop.app` dentro do pacote); a do arm64 nasceu **sem
  plataforma nenhuma**, porque por fora é um `.zip` igual aos outros. Conferir checkbox por
  checkbox, linha por linha, é o passo, não a suposição.
- **A linha nova nem sempre vem escondida.** A do macOS veio com `hidden` marcado (o previsto); a
  do arm64 veio **desmarcada**, ou seja: se alguém salvasse o formulário antes de olhar, o build
  teria ido ao ar com tipo vazio e sem nome de exibição. A caixa de esconder não é um padrão
  garantido, é um estado a ler.
- **O `code.set()` do Redactor responde no tick seguinte.** `code.get()` logo depois do `set()`
  devolve o texto **velho** — o que lê como "não aplicou" e convida a aplicar de novo. Na segunda
  tentativa os padrões antigos já não existem, e isso é a prova de que a primeira funcionou, não de
  que falhou. A régua certa é recarregar o editor e ler o campo vindo do servidor.

## 16. API antes do navegador — medido em 2026-10-20

A rota padrão agora é a API; o navegador (§11 a §15) virou segunda opção, usada só para o que
nenhuma API cobre. A descoberta que custou a sondagem errada: **a API atual da itch não mora em
`itch.io/api/1/...`, e sim em `api.itch.io`**, com `Authorization: Bearer <chave>`. Batendo no
endereço antigo, todo caminho devolve `{"errors":["invalid api endpoint"]}` e a leitura parece
"não existe API". Existe — e é só leitura.

| Chamada | O que devolve |
|---|---|
| `GET https://api.itch.io/credentials/info` | `{"type":"key"}` — chave válida, sem escopo (as geradas na conta têm acesso a tudo o que a API tem) |
| `GET https://api.itch.io/profile` | usuário dono da chave |
| `GET https://api.itch.io/profile/games` | título, `published`, `min_price`, `traits`, `embed`, contadores |
| `GET https://api.itch.io/games/5186495` | a ficha do projeto, mesma forma |
| legado `https://itch.io/api/1/key/*` | `credentials/info`, `me`, `my-games`, `game/<id>/purchases`, `download_keys` |

Medido no projeto real: `traits: ["p_windows","p_linux","p_osx","p_android"]` — é a prova de que os
quatro tipos de plataforma ficaram marcados, lida sem abrir o editor. `PUT /api/1/shininoobi/
projects/5186495` responde **404**: não há endpoint de escrita de página nem de upload. As duas
referências oficiais (a atual e a legada) listam só `credentials`, `profile`, `games`,
`download_keys`, `purchases`, `claimed-rewards`, `ownership`, coleções e `wharf/latest`. O
substituto natural seria o `butler`, que **não está instalado** e cuja URL de download pública não
resolveu daqui — e baixar CLI de terceiro é decisão do autor, não do agente. Então a divisão fica:
**conferir pela API, gravar pelo navegador.**

A página pública também não precisa mais de navegador para conferência: `curl` na URL lê as linhas
de download como HTML server-rendered. Medido em 2026-10-20, cinco linhas — Windows 80 MB,
Linux 72 MB, Android 73 MB, macOS 101 MB, Linux arm64 71 MB (o build de navegador não é linha de
download, é o embed da linha 0, §11).

**GitHub é o oposto:** a REST API faz tudo o que o navegador fazia, inclusive escrita. Sem `gh`
CLI, o token sai de `git credential fill` para `github.com` (40 caracteres, mantido só em variável
de shell, nunca impresso nem commitado) e vale contra `https://api.github.com`. Medido nesta
rodada: `POST https://uploads.github.com/repos/GMGuimaraes/succubus-shop/releases/416907533/assets?name=<arquivo>`
com `--data-binary @<arquivo>` subiu os cinco alvos que faltavam na release da alpha.6 (macOS,
Linux x86_64, Linux arm64, navegador, APK), cada um voltando `state: "uploaded"` com o tamanho de
disco, e o `Content-Length` da URL pública bateu com `stat -c%s` nos cinco arquivos.

Uma armadilha própria do console, não da API: ao verificar texto acentuado, `json.load(sys.stdin)`
decodifica pelo codepage do Windows e **inventa mojibake**. A descrição do repositório pareceu ter
`Ã­`/`Ã©` onde deveria haver `í`/`é`; salvo em arquivo e lido com `decode("utf-8")` explícito, ela
estava correta o tempo todo. A régua é bytes crus, nunca o que o terminal mostra.
