# Kit de publicação — GOG e Epic Games Store

O que falta para o **Succubus Shop** sair da itch.io e entrar em duas vitrines de PC.
Diferente de [`docs/itch-io.md`](itch-io.md), este documento **não termina em "clique aqui"**:
as duas lojas pedem conta no nome do autor, dados fiscais e (na Epic) dinheiro. Nada disso
sai desta máquina. O que sai daqui é a lista do que pedir, o que já está pronto e o que
precisa ser feito antes de qualquer cadastro.

Dimensões e pesos de arquivo abaixo foram **medidos nesta máquina em 2026-10-19**
sobre a árvore real do repo. Requisitos de loja vieram das páginas públicas de cada uma e
estão marcados com a fonte; o que **não** se conseguiu ler está dito como não lido, e é
exatamente o que precisa ser conferido logado.

---

## 1. As três portas, e por qual passar primeiro

| Loja | Conta | Custo | Bloqueio real |
|---|---|---|---|
| itch.io | existe, no ar | grátis | **nenhum** — alpha.6 publicada com os quatro arquivos |
| Epic Games Store | autocadastro, aceita pessoa física | **US$ 100 por produto** | US$ 100 + documento de identidade + entrevista fiscal |
| GOG | formulário de candidatura, revisão humana | grátis | **elegibilidade de conteúdo adulto** e o estágio alpha |

A ordem importa. A Epic é burocracia paga e previsível: você sobe, preenche, espera a
revisão. A GOG é julgamento humano, e a resposta deles para conteúdo como o nosso pode ser
"não" — descobrir isso **depois** de pagar a Epic é dinheiro gasto duas vezes.

**Recomendação:** candidatar à GOG primeiro (é grátis) e tratar o "não" como informação
barata. Enquanto a resposta não vem, produzir os assets que as duas lojas compartilham
(§4) — nada do que a GOG pede é desperdiçado se ela recusar, porque a Epic pede os mesmos
tipos de imagem em outras proporções.

---

## 2. GOG — o estado da arte lido desta máquina

### O formulário

Aberto em `https://www.gog.com/indie` (~15 perguntas, sem taxa, com revisão humana).
Medido aqui: `partner.gog.com` **não resolve** por DNS neste ambiente, e
`gog.com/submit-your-game` renderiza o formulário dentro de um iframe que devolve
`iframe_loading_error` — ou seja, **as perguntas exatas do formulário não foram lidas**.
Quem for preencher tem de fazer isso logado, no navegador, e conferir campo a campo.

### O que a documentação pública diz

- **Sem taxa, mas com curadoria.** A GOG avalia jogo por jogo; não é loja de autosserviço.
  O Developer Portal (onde se sobe build) é **por convite**, depois da aprovação.
- **Eles pedem jogo pronto.** A FAQ desaconselha candidatar jogo em desenvolvimento inicial
  e manda submeter "quando reaches the final stage". Estamos em **v0.1.0-alpha.6**.
  Isso é um choque direto com o nosso rótulo, e é a segunda razão para a ordem da §1.
- **DRM-free é regra, não opção.** Sem launcher próprio, sem checagem online, sem
  ativação. Nosso build já é exatamente isso: `.exe` + `.pck`, save em `user://`, nenhuma
  rede. Nada a fazer.
- **Depot por sistema operacional.** Windows e Linux em arquivos separados — o mesmo par
  que a itch.io já hospeda (§ itch-io.md).
- **Instalador:** nomes de arquivo não podem conter `~ # % *`. Nossos nomes
  (`succubus-shop-0.1.0-alpha.6-windows.zip`) passam.
- **Key art / logo:** mínimo 1920×1080, e a GOG pede **PSD em camadas** para o material
  principal. Nós não temos PSD de nada (as capas saem de HTML renderizado — §4).
- **GOG GALAXY SDK é opcional**, e **nuvem de save** é opcional; se usada, o save vai em
  subpasta com teto de 200 MB. Nosso save é um `.cfg` de alguns kilobytes.

### O que NÃO foi possível verificar

Dimensões exatas de cápsulas, processo de classificação etária, nomes de arquivo de
arquivo/executável, dados fiscais e de pagamento. A GOG publica isso dentro do portal do
desenvolvedor, que é por convite. **Não escrever números aqui só para ter número.**

### O risco que decide tudo

A lista de conteúdo não elegível da FAQ da GOG inclui **"Adult sexual content"**. Nosso
jogo é exatamente a zona cinzenta dessa linha: tema adulto, **nenhuma nudez**, flerte e
insinuação, e um botão que muda o tom sem mover número. Duas leituras possíveis:

1. "Adult sexual content" = nudez/ato sexual → **elegível**, e o copy precisa dizer isso
   com a mesma clareza da página da itch ("Sensual content is a tone switch, not nudity").
2. "Adult sexual content" = qualquer conteúdo sexualmente sugestivo, com ou sem nudez →
   **não elegível**, e a GOG está fora.

Não existe como resolver isso por interpretação da documentação pública. É a primeira
pergunta do formulário, e a resposta deles é a única evidência que vale. Se vier "não", o
custo total da aposta foi uma hora de preenchimento.

---

## 3. Epic Games Store — a lista conferida

Onboarding é autocadastro em `https://dev.epicgames.com/portal/`. Aceita **pessoa física**
(não exige empresa) e exige **18 anos ou mais**, com **verificação de documento** — nome,
endereço e país; passaporte é o que eles recomendam. Isso é trabalho do autor, não desta
máquina.

### Dinheiro e receita

- **US$ 100 por produto** (não por estúdio; e nenhum desconto por usar outro motor — o
  abatimento da Unreal não se aplica a um jogo Godot). Taxa paga **na abertura do produto**.
- **Repartition:** 100% dos primeiros US$ 1 000 000 de receita líquida por produto por ano,
  88/12 depois, a favor do dev.
- **Pagamento:** via Hyperwallet, na moeda local — ou seja, conta bancária em nome do autor.
- **Fiscal:** a entrevista fiscal dentro do portal gera o formulário da série **W-8** para
  quem não é dos EUA. Não é algo que se adiante preenchendo na mão.

### Build

- Sobe com a **BuildPatch Tool (BPT)** — utilitário de linha de comando da Epic, com
  repositório de build local e arquivamento em chunks. Não é o `.zip` da itch.io: é um
  fluxo próprio, e um `.bat`/script nosso teria de chamá-la.
- **Sandboxes:** Product → Dev / Stage / Live. Publica no `Live` quando a loja aprova.
- **Plataformas:** ativa só as que você suporta. **Windows-only é aceito** — o que resolve
  o problema do build de Linux, nunca executado numa máquina Linux (§5).
- **EOS (Epic Online Services) não é obrigatório** para jogo single-player. Não integrar.
- **Sem DRM exigido.** O launcher faz a entrega; não há wrapper a aplicar.

### Assets da vitrine — os números exatos

| Item | Especificação | Teto |
|---|---|---|
| Logo | 960 × 540 PNG | 1 MB |
| Imagens de vitrine **paisagem** | 2560 × 1440 | 4 MB cada |
| Imagens de vitrine **retrato** | 1200 × 1600 | 4 MB cada |
| — mínimo | ≥1 paisagem **e** ≥1 retrato de uso geral, mais ≥1 de cada para biblioteca | |
| Carrossel | ≥1 imagem **1920 × 1080**, recomendado ≥5 | 4 MB |
| Carrossel em vídeo | MP4 1920 × 1080, 30 ou 60 fps, AAC estéreo 48 kHz 320 kbps | 300 MB |
| Bloco "About" | ≥1 texto + ≥1 imagem de largura ≥700 px | 4 MB |
| Imagens extras do "About" | até 20 em 1920 × 1080 | **1 MB cada** |
| Prévia social | 1200 × 1200 | 4 MB |
| Descrição curta | **280 caracteres**, em cada idioma cadastrado | |

Idioma: só o **inglês é obrigatório**; PT-BR é opcional (temos as seis tabelas prontas).

### Classificação etária (IARC)

O questionário IARC é **grátis e fica dentro do próprio portal**, e respondê-lo é o caminho
normal. Pular a classificação deixa o produto como "unrated", com alcance restringido.
Conteúdo sexual sugestivo **é permitido** se rotulado, classificado e com bloqueio etário.
**Jogos AO (Adults Only) não podem ser distribuídos**, e a arte usada nos posições de
destaque da loja **não pode exceder IARC 12 / ESRB Teen** — ou seja, as cápsulas com a
succubus em pose provocante provavelmente precisam de **variante contida**, usada só nos
banners de destaque. Na Austrália, desde 2026-09-09, R18+ exige verificação de idade.

Nossa posição é confortável aqui: o jogo não tem nudez, e o toggle de tom não corta
progressão. É a mesma frase que já está na página da itch, e ela vira a resposta do
questionário.

---

## 4. O gap real: o que existe vs o que as duas lojas pedem

Medido nesta árvore em 2026-10-19:

| Precisam | Existe | Falta |
|---|---|---|
| Carrossel 1920×1080 (Epic) | **feito**: `capa-A-{pt,en}-1920x1080.jpg`, 284/280 KB | — |
| Vitrine paisagem 2560×1440 (Epic) | **feito**: `capa-A-{pt,en}-2560x1440.jpg`, 448/444 KB | — |
| Vitrine retrato 1200×1600 (Epic) | **feito**: `capa-A-{pt,en}-1200x1600.jpg`, 216/218 KB | — |
| Prévia social 1200×1200 (Epic) | **feito**: `capa-A-{pt,en}-1200x1200.jpg`, 188/190 KB | — |
| Descrição curta ≤ 280 caracteres (Epic) | **feito**: PT 265 caracteres / 270 bytes, EN 277 / 277 (§4.1) | — |
| Logo 960×540 (Epic) / key art 1920×1080 em camadas (GOG) | `icon.svg` (128×128) | gerar PNG nas duas medidas; o **PSD em camadas da GOG não existe** e HTML renderizado não produz camadas |
| Trailer MP4 1920×1080 (Epic, recomendado) | nada | gravar do jogo em janela; sem gravação automática no repo |
| Galeria de screenshots | **feito**: sete capturas em 1920×1080, PNG (1,20–3,75 MB) e JPG (236–756 KB), em `marketing/itch/out/galeria-1920/` | — |
| Build Windows | `.exe` 153,67 MB, zip 82,10 MB | nenhum |
| Build Linux | x86_64 `0755` no zip, 73,35 MB | **nunca executado** em Linux real |

### 4.1 O pacote que já saiu — renderizado e conferido a olho em 2026-10-19

`marketing/itch/renderar.sh` ganhou as oito linhas de medida da Epic (PT e EN) e a coluna de
extensão. **As artes de loja saem em JPG, não PNG**: o PNG de 2560×1440 pesa 4,36 MB e o teto
da Epic para imagem de vitrine é 4 MB; o JPG do mesmo quadro são 448 KB, com o texto nítido
conferido no olho nas quatro proporções, nos dois idiomas. Os arquivos estão em
`marketing/itch/out/` (fora do git):

```
capa-A-pt-2560x1440.jpg  455.721 B   capa-A-en-2560x1440.jpg  454.137 B
capa-A-pt-1920x1080.jpg  287.961 B   capa-A-en-1920x1080.jpg  286.501 B
capa-A-pt-1200x1600.jpg  218.249 B   capa-A-en-1200x1600.jpg  217.837 B
capa-A-pt-1200x1200.jpg  190.044 B   capa-A-en-1200x1200.jpg  189.122 B
```

O retrato 1200×1600 **funciona sem layout próprio**, e a razão é estrutural: `capa.html` fixa
o canvas em 1280 de largura e deixa a altura seguir a proporção pedida
(`stage.style.height = (H / s)` + `transform: scale(s)`), então o retrato ganha um quadro mais
alto em vez de esticar — o texto fica no topo, o balcão preenche o pé da imagem e a linha de
rodapé desce para a borda. O quadrado 1200×1200 é o que fica melhor das quatro. O que **não**
existe é a classe `compact` para essas proporções (`H / W < 0,55` só liga em faixa larga), e
não é preciso: nenhuma das duas medidas corta texto.

**Descrições curtas nas medidas da Epic** (o limite é de 280 caracteres por idioma):

PT — 265 caracteres / 270 bytes:
> Simulador de gestão em fantasia sombria. Você é a succubus que herdou uma loja de relíquias
> e precisa fazer ela pagar: forjar, vender, fiar, expedir, defender a porta e escolher onde
> gastar talento. Sete capítulos, sete desfechos e clientes que lembram do seu nome.

EN — 277 caracteres / 277 bytes:
> A management sim in dark fantasy. You are the succubus who inherited a relic shop and has to
> make it pay: forge, sell, extend credit, send expeditions, defend the door and choose where
> every talent point goes. Seven chapters, seven endings, and regulars who remember your name.

As duas versões longas que estavam na itch.io (PT 315, EN 312 caracteres) continuam valendo lá
— a itch não tem esse teto — e o que mudou aqui foi só a poda para a vitrine da Epic.

### 4.2 As sete capturas de dentro do jogo, em 1920×1080 — e os 19 px que quase passaram

`project.godot` tem `viewport 1280×720`, `stretch/mode="canvas_items"`,
`stretch/aspect="expand"`. Capturar em 1920×1080 é a **mesma proporção 16:9**, então o fator
sobe de 1,0 para 1,5 e todo o layout escala junto: sem reflow, sem texto cortado, o mesmo
quadro mais nítido — conferido no olho na primeira captura. `tools/probes/galeria.gd` ganhou
um argumento depois de `--` para isso (`-- 1920`), que também muda a pasta de saída para
`galeria-1920/` e não toca no comportamento padrão de 1280×720.

O que **não** era óbvio é que pedir a medida não é receber a medida. Medido nesta tela de
1920 × 1080 com área útil de 1920 × 1032:

| Gesto | Janela | Textura salva |
|---|---|---|
| `window_set_size(1920, 1080)` antes do boot | 1920 × 1061 | **1920 × 1061** |
| idem + `WINDOW_MODE_FULLSCREEN` antes do boot | 1920 × 1061 | **1920 × 1061** |
| `window_set_size` + tela cheia **depois** do `_ready()` | 1920 × 1080 | **1920 × 1080** |

Duas causas, uma em cima da outra. A primeira é do Windows: uma janela com barra de título não
comporta 1080 de conteúdo numa tela de 1080, e o motor aceita o pedido devolvendo 1061 — sem
aviso. A segunda é do nosso código: `_apply_player_settings()` (main.gd) reaplica o modo
gravado durante o `_ready()`, então a tela cheia pedida antes de montar a loja é desfeita
depois. A sonda hoje troca a janela **depois** do boot e imprime
`← FORA DA MEDIDA PEDIDA` em qualquer captura que sair do tamanho pedido — sem essa linha no
log, as sete fotos teriam ido para a Epic 19 px mais baixas e ninguém ia notar antes da rejeição.

```
marketing/itch/out/galeria-1920/  PNG  01_recepcao 3,75 MB · 02_balanco 1,80 MB · 03_forja 3,14 MB
                                       04_fiado 3,29 MB · 05_combo 3,34 MB · 06_conquistas 1,20 MB
                                       07_estrada 3,28 MB
                          JPG (0,92)  754 KB · 314 KB · 600 KB · 735 KB · 756 KB · 236 KB · 657 KB
```

Os PNG passam nos **4 MB do carrossel**. As sete também saem em JPG do mesmo `save_png` da
sonda — é o caminho para o bloco "About", que aceita uma imagem de até 4 MB e mais vinte de
até **1 MB**: em PNG seis das sete estouravam o MB, em JPG a maior são 756 KB, com o texto
nítido conferido no olho.

### A fonte das capas continua sendo HTML, e isso é uma escolha

`marketing/itch/capa.html` + `renderar.sh` produzem qualquer W×H via Chrome headless, com
copy PT/EN do mesmo lugar. É reprodutível e versionável — mas **não produz PSD em camadas**,
que é o que a GOG pede para o material principal, e não produz o logo vetorial da Epic
(`icon.svg` é o único SVG real). Se a GOG aprovar, a entrega de key art deles vai pedir um
arquivo que este pipeline não faz; exportar o SVG em camadas para PSD é trabalho manual em
ferramenta de arte, e isso não existe nesta máquina.

`marketing/` está **fora do git** (árvore não rastreada, sem entrada em `.gitignore`). Os
PNGs renderizados — 5,5 MB, 1,26 MB no maior — não devem entrar; o que deve entrar são
`capa.html`, `renderar.sh`, `descricao-itch.md` e `.gdignore`, com `marketing/*/out/`
ignorado.

---

## 5. O que bloqueia, dito sem rodeios

1. **iOS não dá desta máquina.** Export de iOS no Godot exige **macOS + Xcode + certificado
   de code signing + Apple Developer (US$ 99/ano)**. Não há Mac aqui, não há Xcode, e
   `--export-pack` de iOS em Windows não existe. O APK de Android saiu (itch, 73 MiB,
   arm64-v8a, assinado com o keystore do projeto); iPhone vai ter de ser outra máquina.
2. **GOG e Epic pedem a conta do autor.** Nenhuma das duas está logada no navegador desta
   sessão. Não se pede senha a ninguém, e não se cria conta de loja em nome de outra pessoa.
3. **Epic custa US$ 100 antes de qualquer coisa**, e o valor é por produto.
4. **Documento de identidade, entrevista fiscal e conta Hyperwallet** são dados pessoais do
   autor. A Epic exige nome/endereço/país batendo com o documento.
5. **Elegibilidade de conteúdo na GOG** (§2) pode ser "não", e nenhuma leitura da doc pública
   resolve.
6. **Estágio alpha** contra a política da GOG de submeter jogo finalizado. Se a intenção é
   candidatar agora, o copy da candidatura precisa dizer o estágio com a mesma honestidade da
   página da itch — e aceitar que essa é a fraqueza do submission.

---

## 6. Checklist, na ordem em que dá para executar

**Andado desta máquina, sem conta nenhuma — 2026-10-19:**

- [x] Oito capas nas medidas da Epic (2560×1440, 1920×1080, 1200×1600, 1200×1200) em PT e EN,
      em JPG por causa do teto de 4 MB, conferidas a olho — §4.1.
- [x] Descrições curtas podadas para os 280 caracteres da Epic (PT 265, EN 277) — §4.1.
- [x] `marketing/` comitado como fonte, com `marketing/*/out/` fora do git.

- [x] Galeria em 1920×1080 pelo argumento novo de `tools/probes/galeria.gd` (`-- 1920`), em
      PNG e JPG, com a medida conferida no log — §4.2.

**Ainda desta máquina:**

- [ ] Gerar logo 960×540 e a key art 1920×1080 a partir das artes que já existem.
- [ ] Escrever as descrições longas nos formatos das duas lojas (a da itch não serve tal qual).
- [ ] Roteirizar o trailer e definir como ele é gravado.

**Com a conta aberta (trabalho seu):**

- [ ] `https://www.gog.com/indie` — ler as ~15 perguntas e responder a de conteúdo adulto.
- [ ] `https://dev.epicgames.com/portal/` — cadastro, documento, US$ 100.
- [ ] Abrir o produto na Epic, preencher IARC e subir o primeiro build no sandbox `Dev` com
      a BuildPatch Tool.

**Depois da resposta da GOG:** decidir se a key art em camadas PSD vale o esforço — se a
resposta for "não", a §2 inteira não precisa mais de atenção.
