---
name: feedback-docs-changelog
description: Toda mudança no Gerador de Propostas atualiza a documentação viva do repo (CHANGELOG, CONTRIBUTING/README quando afetados) e vai por PR
metadata:
  type: feedback
---

O usuário exige que a documentação e os logs sejam atualizados a cada mudança, para o contexto nunca se perder entre sessões e agentes (regra de origem: [[feedback-docs-logs-obrigatorio]] no projeto DVR).

**Why:** a documentação viva é o mecanismo de coordenação entre o usuário, o S.O e os agentes de IA.

**How to apply:** neste repo, registrar cada mudança em `CHANGELOG.md` (seção "Não publicado"). Ajustar `CONTRIBUTING.md`, `README.md` e `docs/` quando a mudança afetar fluxo, campos do cadastro ou configuração. Tudo entra por PR, porque a main é protegida. Ver [[projeto-gerador-propostas]].
