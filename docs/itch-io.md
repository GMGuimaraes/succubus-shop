# Kit de publicação — itch.io

Copy, avisos honestos e o passo a passo para subir o **Succubus Shop** na itch.io.
Os números abaixo não são chutes: foram medidos em 2026-10-18 com
`tools/probes/publicar.gd` (60 conferências, 0 quebras), `tools/probes/idioma.gd`
(228/228 chaves nas cinco tabelas traduzidas), `tools/probes/menu.gd` (100 definições
de conquista) e uma varredura PNG da árvore `assets/`.

---

## 1. Estado real — o que ainda bloqueia o botão de publicar

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
| Descrição "About" do repositório GitHub | não alterada | sem `gh` CLI neste ambiente — edição manual na web |

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
| Massa de arte | **667 PNG** na árvore: 169,60 Mpx, 274,87 MB. O corte com perdas por classe (`tools/set_texture_budget.py`, `compress/mode=1`) embarca **41,46 MB de `.ctex`** — 21,81 MB das 57 opacas + 19,65 MB das 610 com alfa — e fecha o `.pck` do navegador em 43,47 MB, que viram **48,61 MB** com as fontes e **48,05 MB** depois de as 72 sondas de desenvolvimento saírem do pacote com as duas fontes de símbolo (§8) |
| Download do build web | **57,81 MB** compactado. Dentro dele `.pck` 48,05 MB e `.wasm` 39,51 MB descompactado — o `.wasm` é o motor, fixo, não depende da arte |
| Download dos builds de mesa | Windows **82,10 MB** (um `.exe` de 153,67 MB descompactado, `.pck` embutido); Linux **73,35 MB** (binário `x86_64` de 118,06 MB, `.pck` embutido). Os dois passam o limite de 200 MB por arquivo descompactado. As fontes do §8 **não** embarcam neles: `exclude_filter` com `fonts/*.ttf`, conferido no binário |

Regra da itch.io que aperta aqui: cada arquivo **descompactado** tem de caber em 200 MB.
O `.pck` sem perdas media 207,33 MB e era reprovado; hoje cabe com folga. Ver §6.

---

## 3. Título, tagline, descrição curta

**Título:** `Succubus Shop`

**Tagline (a linha curta embaixo do título — 116 e 110 caracteres, cabe no campo):**

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
| Genre / Tags | Simulation, Strategy, RPG, Indie; tags: `godot`, `management`, `shop-sim`, `dark-fantasy`, `incremental`, `female-protagonist`, `story-rich`, `portuguese` |
| Content warning | **Adults Only – Sexual Themes** (marque "sexual themes"; **não** marque nudez: o jogo não tem) |
| Status | **In Progress** |
| Multiplayer | nenhum |
| Inputs | mouse + teclado (ESC abre o menu) |
| Language | Portuguese, English, Spanish, French, Italian, German |
| Keyboard accessibility | o menu todo é clicável com mouse; ESC abre e fecha |
| Cover image | 625×322 — use `screenshots/gallery_reception.png` recortada; o selo do projeto é `icon.svg` |
| Banner | 690×415 (opcional, mesma arte) |
| Thumbnail | 16:9 |
| Screenshots / gallery | os sete `screenshots/gallery_*.png` + `screenshots/current-build.png` |
| Release name | `v0.1.0-alpha.6` — o número vai no nome do zip e, dentro do jogo, em `config/version` |
| Notes no arquivo | escreva "alpha em desenvolvimento; save no navegador fica no armazenamento do site" |
| Available platforms | Windows, Linux, HTML5 |
| Pricing | "Pay what you want" com mínimo 0 (ou o mínimo que você escolher) — a itch.io cobra 10% por padrão |

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
total do navegador é **58,35 MB compactados** (`.zip` de 58.352.045 bytes; hoje **57,81 MB**, `.zip` de 57.811.416, com as sondas excluídas) — eram 53,45 MB
antes delas, e o `.pck` é o que cresce: 43.469.492 → 48.607.204 → 48.049.800 bytes. Um build honesto
para o navegador: o maior arquivo extraído (o `.pck`, 48,05 MB) cabe 4,2× no teto de 200 MB
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
- **Nota no mobile.** O build web usa `gl_compatibility` e roda, mas a UI foi desenhada
  para 1280×720 com mouse. Não marque "mobile friendly".
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

### Medido no build desta rodada (2026-10-19)

| Arquivo | Bytes | MB |
|---|---|---|
| `Succubus-Shop-0.1.0-alpha.6-windows.zip` | 82.098.382 | 82,10 |
| `.export/windows/Succubus Shop.exe` (extraído, `.pck` embutido) | 153.665.336 | 153,67 |
| `Succubus-Shop-0.1.0-alpha.6-linux.zip` (após gravar o modo unix) | 73.351.720 | 73,35 |
| `Succubus-Shop-0.1.0-alpha.6-web.zip` | 57.811.416 | 57,81 |
| `.export/web/index.pck` | 48.049.800 | 48,05 |

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
