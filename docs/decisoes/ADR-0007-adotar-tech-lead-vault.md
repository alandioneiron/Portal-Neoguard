# ADR-0007 - Adotar o método tech-lead-vault no modo Adotar

- **Data:** 2026-11-03
- **Status:** Aceito
- **Decisores:** Tech Lead + Alan (OK geral para adotar o método)

## Contexto
O projeto já tinha processo: `CLAUDE.md` com regras, `CHANGELOG.md`, `CONTRIBUTING.md`, contrato em `docs/portal/`, checklist no modelo de PR, CI com 5 checks obrigatórios e fluxo de Release. Faltavam:
- uma nota de handoff entre sessões;
- um registro de decisões;
- um log de sessões de IA;
- a Definição de Pronto explícita;
- o checklist de produção;
- o roteiro;
- o modelo de tarefa.

As sessões de IA começam sem contexto, e parte das decisões estava só no chat e na memória privada do Claude.

## Decisão
Adotar o método **tech-lead-vault** no modo **Adotar**: os nomes e as regras do projeto prevalecem, e o método só preenche as lacunas.
- **Vault:** a pasta `docs/`, que dá para abrir no Obsidian. As notas novas usam links Markdown, não `[[wikilinks]]`, para funcionarem no GitHub.
- **Notas novas:**
  - `docs/HANDOFF.md`;
  - `docs/decisoes/` (ADRs);
  - `docs/LOG-SESSOES-IA.md`;
  - `docs/ROADMAP.md`;
  - `docs/checklists/DEFINICAO-DE-PRONTO.md` e `docs/checklists/PROMOVER-PARA-PRODUCAO.md`;
  - `.github/ISSUE_TEMPLATE/tarefa.md`.
- **Mantidos como estão:** `CHANGELOG.md` faz o papel do Changelog e do Diário; `CONTRIBUTING.md` e `portal/deploy/README.md` fazem o papel do Fluxo de Desenvolvimento; `docs/portal/ESPEC-FASE1.md` é a spec do módulo.
- **Deliberadamente diferente do método:**
  - sem branch `dev`: o fluxo é branch → PR → `main` → Release;
  - sem quadro do GitHub Projects por enquanto, porque exige um OK do Alan;
  - a memória completa do Claude continua privada, fora do repositório público.

## Alternativas consideradas
- Modo Install, com vault numerado novo: duplicaria notas e quebraria os links já usados.
- Não adotar: o handoff e as decisões continuariam dependendo da memória privada de uma máquina.

## Consequências
- Toda sessão termina reescrevendo o `docs/HANDOFF.md` e acrescentando uma linha no `docs/LOG-SESSOES-IA.md`.
- Toda decisão vira um ADR.
- Ficam para o OK do Alan: quadro do Projects, labels de área e prioridade, e milestones.
