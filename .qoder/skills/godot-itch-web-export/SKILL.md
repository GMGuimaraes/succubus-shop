---
name: godot-itch-web-export
description: "Prepare a Godot 4 project for itch.io publishing (Web + Linux + Windows) with measured pitfalls. Use when configuring or validating export_presets.cfg for itch.io, building the web export, checking the zip shape (index.html at root, extracted file under 200 MB) or the texture/.pck budget, restoring save import/export broken by the missing FileDialog on web, or when export fails because export templates are missing."
---

# Godot → itch.io: preparação de export com armadilhas medidas

## Visão geral

Cadeia reproduzível de preparação de um projeto Godot 4 para a itch.io. Cada passo tem
asserção verificável por script — não confiar em memória nem em estimativa. Comandos de
referência usam o Godot CLI em `C:\Users\gmore\godot\godot` (adaptar por projeto).

## Ordem dos passos

1. Presets → 2. Flags do build web → 3. Guarda de FileDialog → 4. Orçamento de textura →
5. Forma do zip → 6. Templates de export → 7. Fontes de símbolo no navegador.

## 1. Os três presets e os campos Windows-only

- Presets `Windows Desktop`, `Linux`, `Web`; todos exportam para dentro de `.export/`,
  que fica fora do git.
- **A string do Linux é `platform="Linux/X11"`.** Medido no Godot 4.7.2: com `Linux/*BSD`
  ou `Linux/bsd` o `export_presets.cfg` carrega sem nenhum erro no boot do editor, o preset
  é **descartado em silêncio**, e o export responde `Invalid export preset name: Linux`
  citando como detectados só os outros dois. Não há aviso — só um alvo que sumiu. Rode os
  candidatos um por um se duvidar; a asserção fica na sonda de presets.
- `application/file_version` e `application/product_version` **só existem no preset
  Windows**. Escrevê-los nos outros dois presets é o erro que a sonda pega:
  `python scripts/check_export_presets.py <export_presets.cfg>` ASSERTA presença em
  `preset.0` e AUSÊNCIA nos presets de Linux e Web.
- O `file_version` do `.exe` deve ser o núcleo de `config/version` do `project.godot`:
  o explorador Windows mostra a versão do `.exe`, não a do jogo — discordarem é o jogador
  jurando que roda o build velho. Em Linux e navegador quem anuncia o número é o próprio
  jogo (créditos e o nome do `.zip` que sobe).
- No Web, confira também `variant/extensions_support=false` se não há extensões.

## 2. `variant/thread_support=false`

Sem threads, o build web não exige SharedArrayBuffer, e a hospedagem (inclusive a da
itch.io) serve a página sem cross-origin isolation. O script acima ASSERTA que o preset
Web crava `thread_support=false`.

## 3. Web não tem FileDialog — a porta de save sai de cena

- No build web, `ACCESS_FILESYSTEM` só enxerga `/home/web_user`: não há `FileDialog` para
  exportar/importar save. Os botões de importar/exportar saem de cena e um aviso entra no
  lugar — **sem mover nenhum número do jogo**.
- Provar sem mover valor: corrida A/B headless de 200 tiques na mesma semente, desktop vs
  web; resultado idêntico. Isolar o user dir (`APPDATA` apontando para um tmp) para não
  sobrescrever o save real.
- A flag de plataforma tem de existir **antes de `add_child`**: é `_ready()` de cada nó
  quem a lê. Loja web montada com a flag depois nasce com a porta de save viva.

## 4. Orçamento de textura: medir, não estimar

- `python scripts/measure_png_budget.py <dir dos assets>` conta pixels lendo só o IHDR de
  cada PNG (sem decodificar).
- Estimativa antes da medida não é confiável: a primeira conta (≈155 MB) ficou na metade da
  medida real (274,87 MB em disco).
- Antes da WebP, os PNGs re-encodeados por classe davam **667 PNG, 169,60 Mpx, 274,87 MB**
  em disco (só `assets`: 659 PNG / 162,23 Mpx / 263,1 MB). Re-medidos nesta rodada após o
  corte em WebP: **602 PNG** (61,81 Mpx / 97,9 MB) **+ 66 WebP** (107,79 Mpx / 13,2 MB).
- `vram_texture_compression/for_desktop` E `for_mobile=true` no MESMO preset web embarca
  dois conjuntos de compressão e **dobro o `.pck`**. Deixar os dois ligados é decisão
  consciente, não padrão.

## 5. Forma do zip web (regra medida da itch.io)

- `index.html` na **RAIZ** do zip: zipar de dentro do diretório exportado
  (`cd .export/web && zip -r ../../web.zip .`), nunca o caminho inteiro.
- Cada arquivo extraído ≤ 200 MB — na prática é o `.pck` que estoura. Com
  `embed_pck=false` o `.pck` fica solto no zip e o limite é dele; se estourar, a alavanca
  é textura (passo 4), não o zip.
- **Zip feito no Windows perde o bit de execução do binário Linux.** Medido com `zipinfo`:
  o `Succubus Shop.x86_64` saía `-rw----` (nem leitura para o grupo), e no Linux o jogador
  não consegue rodar o arquivo. `Compress-Archive` não tem como corrigir; reescreva as
  entradas com Python (`zipfile`), marcando `create_system = 3` (Unix) e
  `external_attr = (0o755 & 0xFFFF) << 16`. Custo medido: +0,85 MB no zip pelo re-deflate.
- Tamanho lógico, não o do disco: com compressão transparente de NTFS, `du -h` devolveu
  "71M" para um zip de 82.623.209 bytes. O número que a itch mostra é `stat -c %s`.

## 6. Export templates ausentes bloqueiam o export

- Sem `export_templates/` preenchido para a versão exata do editor, o export falha na
  hora e **não baixa os templates em silêncio**.
- Download (~1 GB) é decisão do usuário: confirmar antes de gastar banda/disco.
- Godot Editor → Editor → Manage Export Packages, ou baixar o `tpz` da versão do editor.
- **O exportador lê `$APPDATA/Godot/export_templates` — a mesma variável que as sondas
  trocam para não escrever no save real.** Com o `APPDATA` descartável do portão, o export
  morre com `Nenhum modelo de exportação encontrado no caminho esperado:
  D:/.../tmp-userdata/Godot/export_templates/...`. Export roda com o `%APPDATA%`
  verdadeiro; só as sondas mudam de pasta.
- O preflight tem de comparar a **versão curta**: `--version` devolve
  `4.7.2.stable.official.ed1daf0bf` e a pasta se chama `4.7.2.stable`. Exija também o
  `version.txt` dentro dela — assim o script para na porta em vez de deixar o export
  reclamar tarde.
- No 4.7.2 o conteúdo da pasta é **plano** (`linux_release.x86_64`, `web_release.zip`,
  `windows_release_x86_64.exe` direto na pasta da versão), sem subpasta por plataforma.
  Não procure `.../linux/` para concluir que falta template.

## 7. Fontes de símbolo no navegador (emoji colorido e glifos raros)

- O build web **não traz** as fontes de sistema do jogador. Sem cadeia de fallback, o
  navegador desenha caixas vazias (tofu) nos glifos que a fonte embarcada do motor não tem.
  No mesa isso é invisível: lá o SO fornece a fonte.
- Rota que mantém **cor**: `FontFile` COLR/emoji (Noto Color Emoji) + fonte de símbolos
  (DejaVu Sans) anexadas a `ThemeDB.fallback_font` **só no build web**, na ordem
  emoji → DejaVu → resto da cadeia. Emoji primeiro porque é o que tem cobertura de cor;
  DejaVu depois cobre setas/ícones de linha que o COLR não desenha.
- **Copie a cadeia existente antes de anexar**, e pule duplicatas — anexar por fora do que
  já estava lá derruba o fallback padrão do motor, e reexecutar a função acumula entradas
  repetidas. A função tem de ser idempotente.
- **Chame antes de `_build_ui()`**: é o `_ready()` de cada `Label` quem resolve a cadeia.
  Montar a UI e ligar a fonte depois deixa tudo que já existe em tofu.
- Arquivo oficial ~25,3 MB não é o que vai no build: desmonte a tabela `SVG ` (oCOLR só) e
  o embarque cai para ~5 MB. Medido: oficial 25.332.736 B → embarcado 5.044.436 B.
- **O `.pck` do navegador carrega a `.fontdata` importada E o `.ttf` fonte.** Não confie na
  soma da cache `.godot/imported`: o pacote cresce mais que ela. Medido: `.fontdata` do
  emoji 3.082.128 B + DejaVu 429.187 B, mas o `.pck` subiu 5.144.764 B.
- Nos presets de mesa, `exclude_filter="*.tmp,*.bak,fonts/*.ttf"` tira o `.ttf` **e** o
  artefato importado dele. Provar com grep no binário, não com o tamanho: `.exe` de
  154.229.792 B e `x86_64` com **0** ocorrências de `NotoColorEmoji`. Licença `.txt` não é
  pega pelo filtro e embarca (+0,02 MB — aceitável, é o preço de distribuir a OFL).
- **Custo real do download, medido, não estimado:** prometi "~+10 MB" e a subida do zip
  web foi 53,45 → **58,36 MB** (+4,91 MB). Refazer a conta por projeto antes de prometer
  número ao jogador.
- Licença: Noto Color Emoji é OFL 1.1, DejaVu é licença própria (bitstream-ish) — os `.txt`
  entram no repo e no build.
- Limitação honesta: headless usa o renderizador dummy. A **matriz** de glifos dá para
  conferir pelo TextServer (`has_char`, `get_texture_count`, `get_texture_image`), mas o
  **resultado na tela** exige Chrome com `python -m http.server` (serve `.wasm` com o MIME
  certo). Atenção: Godot ignora `PointerEvent`/`KeyboardEvent` sintéticos — painel aberto
  por script no console **não** prova nada; só o clique humano alcança os menus.
- Armadilha correlata medida na mesma rodada: no Windows headless, adicionar um `Label`
  novo com glifos raros a uma árvore de jogo viva produce FATAL intermitente de text
  shaping **com ou sem** a cadeia embarcada (5/8 dos lados com fonte, 5/12 sem fonte
  nenhuma; 0/12 com texto ASCII, 0/12 sem a cena do jogo). É do motor, não da feature —
  a rota de publicação (jogo + UI real + 200 tiques com a cadeia) fechou 6/6 limpa com
  `MEDIDA` byte-idêntica ao controle. Triar por **frequência**, com matriz de controles,
  antes de mexer na fiação.

## Valores de referência (medidos numa sessão — ordem de grandeza, revalidar)

- Arte: **602 PNG** (61,81 Mpx / 97,9 MB) + **66 WebP** (107,79 Mpx / 13,2 MB) = 169,60 Mpx
  no total, depois do corte por classe. Antes do corte em WebP eram 667 PNG / 274,87 MB.
- Orçamento de textura por classe: 57 opacos = 123,99 Mpx em q=0,85; 610 com alfa =
  45,61 Mpx em q=0,92. BPP da projeção: lossless 1,07; lossy opaco **0,21**; lossy alfa
  **0,37**. A projeção bateu com o `.pck` real em 0,55 MB na conta sem fontes.
- Build com arte sem perdas: `.pck` 207,33 MB → **reprovado** (limite de 200 MB por arquivo
  descompactado). Com perdas por classe e **sem** fontes: `.pck` 43,47 MB, `.wasm` 39,51 MB
  (motor, fixo), zip web **53,45 MB**. Mesa: `.exe` 154,21 MB descompactado → zip 82,62 MB;
  binário Linux 118,60 MB → zip 73,88 MB.
- Mesmo build **com** a cadeia de símbolo do §7: `.pck` **48,61 MB** (+5,14 MB), zip web
  **58,36 MB** (58.358.890 bytes). Mesa: zip Windows **82,65 MB**, zip Linux **73,90 MB**
  (+0,02 MB cada um — só as licenças `.txt`; os `.ttf` ficam de fora, provado por grep).
- Limite da itch.io: arquivo extraído ≤ 200 MB, zip com `index.html` na raiz.
- A/B de 200 tiques na mesma semente: nenhum número do jogo muda quando a porta de save
  web sai de cena — nem quando a cadeia de fontes entra (mesa e navegador fecham com os
  mesmos `caixa 2357 • fama 0 • dia 11 • servidos 20 • decepções 167`).

## Verificação

- `python scripts/check_export_presets.py export_presets.cfg` → PASS em todas as asserções.
- `python scripts/measure_png_budget.py <assets>` → Mpx total e flag de dois conjuntos.
- `godot --headless --export-release "Web" <caminho>.export/web/index.html` só roda com
  templates instalados; antes disso, o checklist acima é o portão.
- Fontes (§7): `grep -c NotoColorEmoji` nos binários de mesa tem de dar **0**, e o mesmo
  nome tem de estar presente no `.pck` do navegador. Glifo colorido na tela só se confere
  em Chrome — headless é renderer dummy.
