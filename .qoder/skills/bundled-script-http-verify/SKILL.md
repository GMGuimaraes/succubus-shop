---
name: bundled-script-http-verify
description: "Harness reproduzível para validar em black-box um servidor HTTP local (loopback) empacotado num skill — sobe o servidor, prova GET/OPTIONS/POST, o ramo de erro (corpo acima do limite devolve 413 com JSON, não code=000), path traversal em três formas, ausência de arquivo parcial na saída e shutdown limpo. Use quando criar ou revisar um skill que traga um servidor Node em 127.0.0.1 (ponte CORS, file bridge, proxy), quando 'Failed to fetch' numa aba logada precisar ser separado de erro real do servidor, ou quando faltar uma prova reproduzível de que o script do skill funciona em Windows/Git Bash."
when_to_use: Validar em black-box um servidor local empacotado num skill (ponte CORS em 127.0.0.1) antes de afirmar que ele funciona.
---

# Validação preto-e-branco de um servidor embutido num skill

## Overview

`scripts/verify-http-blackbox.sh` sobe o servidor do skill numa porta sorteada pelo SO, dispara
todas as asserções contra ele e derruba o servidor **na mesma chamada de shell**, imprimindo
`PASS`/`FAIL` por asserção e saída 0 apenas se todas passaram. É a prova de que o script do skill
responde — inclusive no ramo de erro — sem depender de navegador nem de estado entre chamadas.

## Quando usar

- Skill novo ou revisado que traz um servidor Node/`127.0.0.1` próprio (ponte CORS, file bridge, proxy local).
- Uma aba logada mostra `TypeError: Failed to fetch` e é preciso separar "servidor respondeu erro"
  de "servidor derrubou a conexão" antes de culpar o CORS.
- Antes de escrever "testado e funcionando" no SKILL.md de outro skill.

## Contrato mínimo do servidor coberto

O harness assume que o servidor (a) imprime uma linha `READY port=<n>` no stdout, (b) aceita
`OPTIONS` com 204, (c) grava `POST /<nome>` num diretório de saída, (d) devolve **413 com corpo
JSON** quando o corpo excede o limite, (e) devolve 404 para path traversal, (f) tem uma rota de
encerramento. Fora disso, ajuste `READY_PREFIX`, `SHUTDOWN_URL_PATH`, `REQUIRE_PRIVATE_NETWORK`,
`MAX_BYTES` — ou reescreva as asserções 2/4/7, não o resto.

## Como rodar

```bash
SERVER_LAUNCH='node "C:/caminho/scripts/srv.cjs" --dir "$VERIFY_IN" --out "$VERIFY_OUT" --max-bytes "$VERIFY_MAX_BYTES"' \
  bash scripts/verify-http-blackbox.sh; echo "HARNESS_EXIT=$?"
```

O harness cria `<cwd>/_http_verify_<pid>` com `in/` (PNG válido de 70 bytes, corpo de 5 bytes),
`out/` e `srv.log`, expõe `VERIFY_IN` / `VERIFY_OUT` / `VERIFY_MAX_BYTES` para o `SERVER_LAUNCH`
e remove tudo ao sair. `KEEP_TMP=1` preserva a pasta para inspeção. Node é obrigatório.

## As armadilhas (é isto que o harness pega)

1. **Estado de shell não persiste entre chamadas `Bash`.** PID e exit code não podem viver em
   variável: o servidor sobe em background com `... > srv.log 2>&1; echo "exit=$?" >> srv.log`
   dentro do mesmo comando, e o `exit=0` é lido do log.
2. **A porta vem do SO.** Extraia da linha `READY port=` (`sed -n 's/.*READY port=\([0-9]*\).*/\1/p'`);
   reimprimir uma porta fixa deixa o teste flaky quando ela já está ocupada.
3. **`code=000` não é 413.** No `curl -w %{http_code}`, 000 significa socket caído — o servidor
   fechou a conexão em vez de responder. Numa aba, o mesmo sintoma vira `TypeError: Failed to fetch`
   e faz caçar o culpado errado (CORS). O harness aborta se o POST grande der 000.
4. **`--path-as-is` é obrigatório no traversal.** Sem ele o curl normaliza `../` antes de sair e o
   teste passa sem nunca atingir o servidor. Três formas: `../SKILL.md`, `%2e%2e%2fSKILL.md`,
   `..%5C..%5CSKILL.md` → todas 404.
5. **Prove a ausência de arquivo parcial.** Liste `out/` depois do 413: o nome do corpo grande não
   pode existir e nenhum arquivo pode passar de `MAX_BYTES` — servidor que abre o stream e estoura
   no meio deixa lixo de 0 bytes.
6. **Servidor vivo depois do erro.** Um `POST` pequeno logo após o 413 ainda deve dar 200; se ele
   morrer no erro, o próximo request da aba falha por motivo completamente diferente.
7. **Shutdown verificado, não presumido.** `GET /shutdown` → 200, `exit=0` no log e a mesma porta
   recusando conexão (`code=000` **aqui** é o esperado). Servidor órfão segura a porta e contamina
   a próxima execução.

## Resultado medido

Rodado em 2026-10-19 contra `browser-canvas-image-reencode/scripts/cors_file_server.cjs`
(`--max-bytes 40`, porta sorteada 56901): **16 de 16 asserções PASS**, saída 0.
O POST grande devolveu `{"ok":false,"error":"too large","limit":40,"seen":500}` com `code=413`,
`out/` ficou sem arquivo parcial, os três traversals deram 404 e o log terminou com `exit=0`.
O cleanup roda: a saída imprime `cleanup ... _http_verify_<pid> removido` e nenhum `_http_verify*`
sobra no cwd da chamada.

## Recursos

- `scripts/verify-http-blackbox.sh` — harness completo, parametrizado só por variáveis de ambiente.
