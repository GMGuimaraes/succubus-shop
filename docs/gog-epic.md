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

### O formulário — as 17 perguntas, lidas uma por uma

Medido em 2026-10-20, e a leitura anterior estava errada no ponto que importava: **o
formulário não é da GOG**. A cadeia real é três páginas, não uma:

| Passo | O que é | Medido |
|---|---|---|
| `https://www.gog.com/indie` | só um atalho | **HTTP 302** → `/submit-your-game` (13,2 s) |
| `https://www.gog.com/submit-your-game` | casca da loja, carrega o resto | 200, 433.144 bytes; dentro, um `<iframe>` |
| `src` do iframe: `https://lp.gog.com/submit-your-game/en` | página de campanha | 200, 356.491 bytes; dentro, **outro** `<iframe>` |
| `src` desse: `https://form.typeform.com/to/jtPGIqWl` | **o formulário de verdade — um Typeform** | 17 campos lidos pela definição pública `api.typeform.com/forms/jtPGIqWl` |

O `iframe_loading_error` que a versão antiga desta seção registrou é o **texto-fallback
escrito pela própria GOG dentro do `<iframe>`** (`<p>iframe_loading_error</p>` está no HTML
de `gog.com/submit-your-game`, como conteúdo do elemento que aponta para a `lp.gog.com` — não
é mensagem do navegador). Aberto como **página de topo**, o mesmo Typeform renderiza e aceita
resposta. Conclusão operacional: **não se passa pelo `gog.com/submit-your-game`; abre-se
`https://form.typeform.com/to/jtPGIqWl` direto.**

E não havia bloqueio nenhum a liberar. `partner.gog.com` devolve
`Non-existent domain` do resolver — o domínio **não existe**, não está censurado — e
`gog.com` resolve nos IPs normais da Fastly (`151.101.129.241` &c). O que falhava era a
montagem de iframe aninhado dentro da visualização incorporada, não a saída de rede.

As perguntas, na ordem e com o tipo:

| # | Pergunta | Tipo | Resposta |
|---|---|---|---|
| 1 | Your email address | email | **é seu** — é por onde eles respondem |
| 2 | Developer's name | texto | quem assina: seu nome ou o codinome de dev |
| 3 | Country of residency | lista | **é seu** (Brasil está na lista) |
| 4 | Do you own a business? | sim/não | decide o caminho fiscal |
| 5 | Do you have a company registered in Poland? | escolha | existe opção **"No — it's just me ("osoba fizyczna")"** |
| 6 | Do you have NIP (Polish Tax ID)? | sim/não | **é seu** |
| 7 | Is your company registered in Russia/Belarus? | sim/não | não |
| 8 | (statement) "unable to process payments to your country" | texto puro | só aparece em país bloqueado |
| 9 | Game title | texto | Succubus Shop |
| 10 | Is your game already released? | sim/não | depende do que você chama de lançado (a alpha está no ar) |
| 11 | Link to your game | URL | `https://shininoobi.itch.io/succubus-shop` |
| 12 | Planned release date | data | **é seu** — só você tem o cronograma |
| 13 | Development status | lista | **Pre-Alpha / Alpha / Beta / Ready to go** |
| 14 | Do you plan to release in Early Access? | sim/não | **é seu** |
| 15 | In-game gameplay | URL | **não temos** — pede vídeo jogável (§ embaixo) |
| 16 | A few words about your game | texto longo | redigível agora |
| 17 | Data processing | aceite jurídico | **é seu** — é consentimento em nome de quem assina |

Duas coisas essa lista muda na leitura que estava aqui:

1. **A pergunta 13 tem "Alpha" como opção.** A FAQ desaconselha candidatar cedo, mas o
   formulário aceita o estado atual do projeto sem mentir. Submeter hoje custa zero e a
   resposta deles é a única evidência que vale (§ "O risco que decide tudo").
2. **Não exige empresa.** O caminho "é só eu" está previsto no campo 5, então a ausência de
   CNPJ/PJ não bloqueia a candidatura — o que bloqueia, se bloquear, é o conteúdo (§ risco).

O que **não** dá para adiantar é tudo o que está marcado "é seu" na tabela: identidade,
fisco, cronograma e o consentimento de tratamento de dados, que se assina em nome de quem
preenche. Dá para adiantar as respostas 9, 11, 13 e 16 — e a 16 é texto que se escreve agora.

### O que a documentação pública diz

- **Sem taxa, mas com curadoria.** A GOG avalia jogo por jogo; não é loja de autosserviço.
  O Developer Portal (onde se sobe build) é **por convite**, depois da aprovação.
- **Eles pedem jogo pronto — e o formulário mesmo assim aceita alpha.** A FAQ desaconselha
  candidatar jogo em desenvolvimento inicial e manda submeter "quando reaches the final
  stage". Mas o campo 13 do Typeform lista **Pre-Alpha / Alpha / Beta / Ready to go** como
  opções. Estamos em **v0.1.0-alpha.6**: submeter hoje não exige mentir no estado, só assume
  o risco de uma triagem antecipada. Fica registrado como escolha, não como impedimento.
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

### O que continua NÃO verificado

Ler as 17 perguntas não lê o resto. Dimensões exatas de cápsulas, processo de classificação
etária, exigências do instalador, dados fiscais e de pagamento continuam dentro do portal do
desenvolvedor, que é **por convite, depois da aprovação** — nada disso é acessível desta
máquina hoje. **Não escrever números aqui só para ter número.** O que também não se mediu: o
comportamento do Typeform quando uma resposta é inválida, e se a GOG responde por e-mail ou
só convida — isso só se sabe submetendo.

### O risco que decide tudo

A lista de conteúdo não elegível da FAQ da GOG inclui **"Adult sexual content"**. Nosso
jogo é exatamente a zona cinzenta dessa linha: tema adulto, **nenhuma nudez**, flerte e
insinuação, e um botão que muda o tom sem mover número. Duas leituras possíveis:

1. "Adult sexual content" = nudez/ato sexual → **elegível**, e o copy precisa dizer isso
   com a mesma clareza da página da itch ("Sensual content is a tone switch, not nudity").
2. "Adult sexual content" = qualquer conteúdo sexualmente sugestivo, com ou sem nudez →
   **não elegível**, e a GOG está fora.

Não existe como resolver isso por interpretação da documentação pública — e agora sabe-se
que **tampouco existe como perguntar**: das 17 perguntas lidas, **nenhuma é sobre conteúdo**.
O formulário não tem campo de nudez, violência ou classificação etária; ele pergunta e-mail,
país, fisco polonês, título, link, data, estado de desenvolvimento, Early Access, um link de
gameplay e "a few words". Ou seja: a triagem de conteúdo acontece **depois**, por curadoria
humana, e o formulário não dá nenhum indício antecipado.

Isso piora a aposta e ao mesmo tempo a barateia. Piora porque não há como saber a resposta
antes de submeter. Barateia porque o custo de submeter é preencher 17 campos, e a resposta
deles — um convite ou um silêncio — continua sendo a única evidência que vale.

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

`marketing/` entrou no git como **fonte** (`capa.html`, `renderar.sh`, `descricao-itch.md`,
`.gdignore`); a saída renderizada fica fora — `marketing/*/out/` está no `.gitignore`. Os
PNGs de 5,5 MB (1,26 MB no maior) são artefato reproduzível, não material versionável.

---

## 5. O que bloqueia, dito sem rodeios

1. **iOS nativo não dá desta máquina — e não é o que segura o iPhone.** A documentação
   oficial da Godot ("Exporting for iOS → Requirements") é uma linha: *"You must export for
   iOS from a computer running macOS with Xcode installed."* Sem Mac, sem Xcode, sem
   `--export-pack` de iOS em Windows, e sem o certificado de code signing + Apple Developer
   (US$ 99/ano). O `.ipa` não existe e não vai existir a partir daqui. O paralelelo do Android
   saiu e está no ar (APK na itch, 73 MiB, arm64-v8a, assinado com o keystore do projeto); o
   do iPhone é outra máquina, não outro comando.
   **Mas o iPhone já tem caminho**, e ele não é o `.ipa`: o preset `Web`
   (`export_presets.cfg`, `variant/thread_support=false`) exporta **single-threaded**, que é
   o modo que a mesma documentação descreve como o que *"works very well on macOS and iOS
   too, where it always had compatibility issues with multiple threads exports"*. Por isso o
   toggle SharedArrayBuffer da itch fica **desligado** (medido: `embed[cdn_type]` = false) —
   ligá-lo é que quebraria o Safari.
2. **O que faltava para o iPhone na itch era um checkbox, e ele foi marcado.** O editor de
   arquivos tinha `embed[mobile_friendly]` = **false**; sem ele, a documentação da itch diz
   que *"a warning will be displayed to the viewer that the game may not work"* em celular.
   Está em `true` desde 2026-10-20 (lido de volta do servidor depois do save), e com isso o
   celular passa a abrir o jogo em "clique para tela cheia". O que isto **não** prova: o
   jogo rodando de fato num iPhone real — WebGL 2.0 do Safari tem problemas que os outros
   navegadores não têm (mesma doc da Godot), e a verificação final é dedo em tela de iPhone.
3. **O formulário da GOG não pede conta nenhuma.** É um Typeform público
   (`form.typeform.com/to/jtPGIqWl`), então a candidatura não depende de login — depende só
   das respostas que são identidade, fisco e cronograma do autor. A **Epic** continua pedindo
   o cadastro dela, com documento.
4. **Epic custa US$ 100 antes de qualquer coisa**, e o valor é por produto.
5. **Documento de identidade, entrevista fiscal e conta Hyperwallet** são dados pessoais do
   autor. A Epic exige nome/endereço/país batendo com o documento.
6. **Nenhuma conta alheia foi jamais entregue a esta sessão.** Google e Steam: não há token,
   cookie, chave ou sessão de nenhuma das duas aqui — quem tem essas sessões é só o navegador
   em que você as abriu. E conta Steam de consumidor **não publica jogo**: publicação exige
   Steamworks Partner (AppID + US$ 100 por app + os mesmos dados fiscais). Se alguma credencial
   dessas foi colada em conversa, considera-a exposta e troca.
7. **Elegibilidade de conteúdo na GOG** (§2) pode ser "não", e agora sabe-se que o
   formulário não pergunta nada sobre conteúdo — não há como descobrir antes de submeter.
8. **Estágio alpha** contra a política da GOG de submeter jogo finalizado, contra o fato de o
   campo 13 aceitar "Alpha". Escolha, não impedimento — mas o copy da candidatura tem de dizer
   o estágio com a mesma honestidade da página da itch.

---

## 6. Checklist, na ordem em que dá para executar

**Andado desta máquina, sem conta nenhuma — 2026-10-19/20:**

- [x] Oito capas nas medidas da Epic (2560×1440, 1920×1080, 1200×1600, 1200×1200) em PT e EN,
      em JPG por causa do teto de 4 MB, conferidas a olho — §4.1.
- [x] Descrições curtas podadas para os 280 caracteres da Epic (PT 265, EN 277) — §4.1.
- [x] `marketing/` comitado como fonte, com `marketing/*/out/` fora do git.

- [x] Galeria em 1920×1080 pelo argumento novo de `tools/probes/galeria.gd` (`-- 1920`), em
      PNG e JPG, com a medida conferida no log — §4.2.
- [x] As 17 perguntas da GOG lidas uma a uma, com o URL direto do Typeform — §2.
- [x] iPhone liberado na itch: `embed[mobile_friendly]` marcado e SharedArrayBuffer
      confirmado desligado, no build que já nasce single-threaded — §5.1/5.2.

**Ainda desta máquina:**

- [ ] Gerar logo 960×540 e a key art 1920×1080 a partir das artes que já existem.
- [ ] Escrever as descrições longas nos formatos das duas lojas (a da itch não serve tal qual).
- [ ] Roteirizar o trailer e definir como ele é gravado. **Isso agora tem prazo interno:** é a
      pergunta 15 do formulário da GOG ("In-game gameplay", campo de URL) e a Epic pede o
      mesmo para o carrossel em vídeo. Sem link de gameplay, a candidatura da GOG se preenche
      até o fim e trava nesse campo.
- [ ] Redigir a resposta da pergunta 16 ("A few words about your game") — texto é nosso.

**Com a conta aberta (trabalho seu):**

- [ ] `https://form.typeform.com/to/jtPGIqWl` — abrir **direto**, não por
      `gog.com/submit-your-game` (o iframe aninhado é o que falhava). Responder e-mail, país,
      as três perguntas de fisco polonês, data de lançamento, Early Access e o aceite de dados.
- [ ] `https://dev.epicgames.com/portal/` — cadastro, documento, US$ 100.
- [ ] Abrir o produto na Epic, preencher IARC e subir o primeiro build no sandbox `Dev` com
      a BuildPatch Tool.
- [ ] Testar o jogo num iPhone real, em Safari. O checkbox diz "pode jogar"; só dedo confirma.

**Depois da resposta da GOG:** decidir se a key art em camadas PSD vale o esforço — se a
resposta for "não", a §2 inteira não precisa mais de atenção.
