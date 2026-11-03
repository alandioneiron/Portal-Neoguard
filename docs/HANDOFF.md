# Último Agente — Handoff

> Arquivo vivo: a última sessão o reescreve no fim do trabalho. É a primeira nota a ler, depois do [`CLAUDE.md`](../CLAUDE.md). O histórico fica no [Log de Sessões de IA](LOG-SESSOES-IA.md) e no [`CHANGELOG.md`](../CHANGELOG.md). O repositório é público: nada de senhas, dados de clientes ou detalhes de acesso aqui.

## Última atualização
- **Quando:** 2026-11-03
- **Quem:** Tech Lead (Claude Opus)
- **Sessão:** adoção do método tech-lead-vault (modo Adotar)

## Em produção agora
- **Ficha de Implantação de Alarme Monitorado**, no ar desde 2026-10-09, na porta 8090 do servidor interno (endereço no `CLAUDE.md`). Sem login (ADR-0003). Os vendedores já usam.
- **Versão em produção:** commit `d69c0d9` (PR #14), implantado à mão, antes do seguidor de Releases. Ainda não há Release publicada.
- **E-mail de envio funcionando:** a senha foi trocada em 2026-10-28 com `trocar-senha-smtp.sh` (ADR-0006).
- **Backup do banco:** todo dia às 02:30 no servidor, com retenção de 14 dias.

## Em andamento
- **PR #20** (`portal/operacao`), **verde nos 5 checks**, aguardando o OK do Alan para o merge. Traz o deploy por Release, o `trocar-senha-smtp.sh`, o frontend com dependências atualizadas e ajuste para tablet, e documentação.
- **Branch `docs/tech-lead-vault`**, criada sobre a `portal/operacao`, com esta adoção do método. Ainda sem PR; vira PR depois do merge do #20.

## Esperando o Alan
1. OK para mesclar o PR #20.
2. OK para instalar o timer do seguidor de Releases no servidor e publicar a Release `v1.0.0`.
3. Se pode apagar o CNAME `propostas.neoguard.com.br` na HostGator (solto desde que o GitHub Pages foi desligado).
4. Dados do AD para a Fase 2: controlador de domínio, domínio, LDAPS (porta 636), grupos e faixas da rede interna.
5. OK para o lado GitHub do método: quadro do Projects, labels de área e prioridade, milestones.
6. Quando o C.O avisar "pronto para o GitHub": sincronizar o artefato e levar o cadastro ao servidor (procedimento no `CLAUDE.md`).

## Próximos passos (na ordem)
1. Com o OK: mesclar o #20 → abrir o PR da `docs/tech-lead-vault` → instalar o timer → Release `v1.0.0`.
2. Fechar o PR #16 do Dependabot (configure-pages; o Pages saiu) e avaliar o #15 (upload-artifact 7), o #17 (setup-python 7) e o #19 (Playwright 1.64.1).
3. Fase 2: login pelo AD (LDAPS), MFA fora da rede e HTTPS público. Depois, a tela de configuração do e-mail (ADR-0006).
4. Gerador como módulo de verdade: cadastro no servidor, histórico central de propostas e upload de CCT.

Roteiro completo: [ROADMAP.md](ROADMAP.md).
