# Log de Sessões de IA

Uma linha por sessão de IA: data — agente/modelo — tarefa — artefatos tocados. Registre também as falhas e os resultados parciais, não só o que deu certo.

- 2026-10-07 — Tech Lead (Opus) + Dev Infra (Sonnet), QA e Documentador (Haiku):
  - artefato do Claude convertido em site estático (Gerador), com cadastro em JSON, CI em PR/`main` e produção só por Release;
  - modelo DOCX higienizado (cliente de exemplo removido);
  - artefatos: repo inicial, PRs #8 a #12.
- 2026-10-07 — Tech Lead:
  - domínio propostas.neoguard.com.br configurado (CNAME e TXT); a verificação do GitHub ficou "Unverified";
  - processo de sincronização com o artefato do C.O (`upstream/`, importador);
  - PRs #9, #10 e #12.
- 2026-10-09 — Tech Lead:
  - nova direção: Portal com login AD (ADR-0002);
  - cadastro real fora do git e do artefato (ADR-0001, PR #13);
  - repositório renomeado para Portal-Neoguard;
  - Google Forms antigo enviado para a lixeira; GitHub Pages desligado.
- 2026-10-09 — Tech Lead + Dev Backend, Dev Frontend e Dev Infra (Sonnet):
  - Fase 1 da Ficha de Implantação: 287 testes no backend, 141 no frontend, Docker + Nginx e botão "Enviar por e-mail";
  - PR #14 mesclado e implantado na porta 8090 (ADRs 0003, 0005 e 0006);
  - backup diário agendado;
  - 5 checks obrigatórios na `main`.
- 2026-10-09 — Tech Lead + Dev Infra e Dev Frontend (Sonnet), Documentador (Haiku):
  - seguidor de Releases (ADR-0004), frontend sem vulnerabilidades, ajuste para tablet e documentação do Portal;
  - o relatório final do Dev Frontend não chegou: o Tech Lead conferiu à mão os testes, o build e o `npm audit` em 2026-10-28;
  - PR #20.
- 2026-10-28 — Tech Lead:
  - erro de envio de e-mail diagnosticado: a senha da conta de envio foi trocada no cPanel, e o servidor respondia 535;
  - criado `trocar-senha-smtp.sh`; o Alan trocou a senha e o envio voltou;
  - o auto-merge do PR #20 foi negado pela checagem de permissões do Claude;
  - artefatos: `portal/deploy/trocar-senha-smtp.sh`, PR #20.
- 2026-10-30 — Tech Lead:
  - backup de contexto para a mudança de máquina;
  - artefatos: branch `backup/maquina-nova-2026-10-30`, `_backup-contexto/`.
- 2026-11-03 — Tech Lead (Opus):
  - adoção do método tech-lead-vault no modo Adotar (ADR-0007);
  - artefatos: `docs/HANDOFF.md`, `docs/decisoes/` (ADRs 0001 a 0007), este log, `docs/ROADMAP.md`, `docs/checklists/`, `.github/ISSUE_TEMPLATE/tarefa.md` e a seção `## tech-lead-vault` no `CLAUDE.md`.
