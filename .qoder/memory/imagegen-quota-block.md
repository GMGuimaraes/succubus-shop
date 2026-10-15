---
name: imagegen-quota-block
description: ImageGen can fail with 403 code 112 (account image quota); pivot to code-only backlog instead of retrying
metadata:
  type: project
---

Em 2026-10-14 o pipeline de arte parou: `ImageGen` passou a responder `403 {"code":"112","message":"{\"pricingUrl\":...}"}` em
todas as chamadas, inclusive em pedidos isolados de 1024x1024. Isso aconteceu depois de ~40 imagens geradas na mesma sessão
(retratos + folhas de 6 poses), então o gargalo é cota de geração de imagem da conta, não o prompt nem o formato.

**Why:** as folhas de poses são o único caminho para ampliar o elenco do salão; sem elas qualquer "novo personagem" fica sem
corpo e sem retrato, e o pedido do usuário de ~50 personagens não avança.

**How to apply:** quando `ImageGen` devolver 403/112, não insista em novas tentadas nem tente contornar com ferramentas de
imagem diferentes — avise o usuário que é cota da conta e use o resto da sessão no backlog que não precisa de arte
(mecânicas, diálogo, README, probes). Antes de parar, confirme se há folhas já geradas e não divididas em
`vibe_images/` para não perder trabalho: `tools/split_poses.gd` funciona offline.
