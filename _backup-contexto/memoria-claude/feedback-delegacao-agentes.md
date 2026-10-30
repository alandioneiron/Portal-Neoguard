---
name: feedback-delegacao-agentes
description: Como delegar tarefas entre modelos no projeto DVR — papéis da "Sala dos Agentes" (Tech Lead Opus, Devs Sonnet, QA/Documentador Haiku)
metadata:
  node_type: memory
  type: feedback
  originSessionId: 8e81f45f-c56b-43ae-8fcf-3c54a697b1b5
  modified: 2026-10-07T20:54:55.949Z
---

Organizar o trabalho como na **Sala dos Agentes** (mod `sala-agentes@neoguard-mods`, painel do app): **Tech Lead = Opus** (eu: arquitetura, P/Invoke/SDK, revisão, integração, deploy, testes reais); **Dev Backend / Dev Frontend / Dev Infra = Sonnet** (componentes bem especificados); **Dev QA E2E = Sonnet** (suíte automática ponta a ponta contra o servidor real, papel criado em 2026-10-07 a pedido do usuário; equipe do projeto em `.claude/sala-agentes.json`); **QA e Documentador = Haiku** (testes, checklists, docs).

**Why:** o usuário quer gastar menos tokens sem perder qualidade (custo output Opus 5× : Sonnet 3× : Haiku 1×) e acompanha os agentes pelo painel da Sala (pedido de 2026-10-07: "tentar usar essa ordem").

**How to apply:** ao disparar um agente, passar `model` (sonnet/haiku) e **começar o prompt nomeando o papel** ("Você é o Dev Backend…", "Você é o QA…", "Você é o Documentador…", "Você é o Dev Infra…", "Você é o Dev QA E2E…") — a Sala senta o agente na mesa pelo papel citado (regex em `~/.claude/mods/sala-agentes/hooks/room.ts`). Regra "delegar ≈ fazer": tarefa pequena, ambígua ou de alto risco o Tech Lead faz direto.
