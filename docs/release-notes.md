# Succubus Shop — alpha jogável (v0.1.0-alpha.6)

Build de **mesa** para Windows 10/11 64 bits. O jogo é portátil: extraia o ZIP e execute
`Succubus Shop.exe`. Não precisa de Godot instalado, não instala nada no sistema, e o
progresso fica em `%APPDATA%\Godot\app_userdata\Succubus Shop\`.

Dentro do jogo, o rodapé de qualquer tela do menu (☰ ou ESC) mostra `Versão:
0.1.0-alpha.6` — é por esse número, e não pelo nome do arquivo, que você confere se está
rodando este build. O arquivo extraído pesa **153.665.336 bytes** (153,67 MB) e o `.zip`,
**83.343.752 bytes** (83,34 MB).

## Requisitos

- Windows 10 ou posterior, 64 bits.
- GPU com OpenGL 3.3 (o build usa o renderizador **GL Compatibility**). Em máquina sem
  GPU dedicada, comece com a janela pequena e a escala de interface em 1.
- 4 GB de RAM e um dual-core são a estimativa atual; ainda não há benchmark publicado.

## O que há nesta alpha

- **Loja completa em loop diurno**: catálogo, produção, qualidade por lote, estoque
  perecível com conservas, preços que reagem a oferta, procura, clima e hora.
- **Casa que cresce em arte real** por faixa de progresso, com fundos próprios para
  recepção, biblioteca, forja, santuário e sala de expedições.
- **Livro de Fiado** — venda a crédito que cobra, jura e risca; **clientes VIP** com
  pedido próprio; **cartaz do combo** pagando sequência no mesmo dia.
- **Expedições** com batedores que evoluem por rota, forja com cronômetro e taxa de
  sucesso, alquimia experimental de bancada.
- **Invasões, cela, vândalos, maid e concorrência na praça**; facções com capítulos
  próprios e finais alternados; cartas evolutivas com bônus de conjunto.
- **Reencarnação (prestígio)** com herança de vínculo, não de caixa; placar por temporada.
- **Onboarding**: painel *COMO SE JOGA* e o cartaz do primeiro dia.
- **Seis idiomas** — português, inglês, espanhol, francês, italiano e alemão — com as
  **228 chaves** do catálogo conferidas por sonda.
- **Registros da casa** no menu: oito seções que só leem e mostram a porta de cada marco.
- **Cem conquistas**, save com exportação/importação e reinício com confirmação.

## Limites honestos

- É **alpha**: falta balanceamento fino, e a aprovação visual de chão, oclusão e timing de
  animação ainda não foi feita por um olho humano.
- Sem multiplayer, sem Steam neste build (o executável pode ser adicionado à biblioteca da
  Steam como jogo não-Steam).
- Se o jogo fechar torto, o log fica em `app_userdata\Succubus Shop\logs\godot.log` —
  vale anexar no relatório. O menu tem **🐞 Relatar um problema**.

## Como sair

ESC abre o menu em camada: ☰ → *Continuar a loja* volta para a rua; *Salvar agora* grava
na hora.

---

*Alpha de mesa. Build web e Linux estão prontos e medidos no repositório
(`docs/itch-io.md`) e serão publicados na itch.io.*
