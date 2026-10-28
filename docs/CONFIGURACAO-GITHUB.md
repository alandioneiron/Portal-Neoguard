# Configuração do GitHub

Estado do repositório `alandioneiron/Portal-Neoguard` (antes `Gerador-de-Processo`; o GitHub redireciona o nome antigo). Tudo abaixo já está configurado; este documento serve para conferir ou refazer.

## Ruleset "Proteção da main"
**Settings → Rules → Rulesets**:
- **Alvo:** a branch padrão (`main`).
- **Bloqueios:** exclusão e force push.
- **Pull request obrigatório:** 0 aprovações enquanto só o Alan mantém o projeto. Quando outra pessoa (ex.: o C.O) passar a contribuir, mude para 1.
- **Status checks obrigatórios**, com a branch atualizada:
  - **Validação e testes unitários**
  - **Testes E2E**
  - **Portal — backend**
  - **Portal — frontend**
  - **Portal — imagens Docker**
- **Sem bypass:** nem o administrador pula os testes.

O nome de cada check é o `name` do job em `.github/workflows/ci.yml`. Se renomear um job, atualize o ruleset junto, senão os PRs ficam bloqueados esperando um check que não existe mais.

## Demais ajustes
- **Settings → General:** "Automatically delete head branches" ligado e "Allow auto-merge" ligado.
- **Settings → Actions → General → Workflow permissions:** "Read repository contents".
- **Dependabot:** `.github/dependabot.yml` (GitHub Actions, npm da raiz, npm do `portal/frontend` e pip do `portal/backend`).
- **Rótulos:** `dependências` e `cadastro-cct`.

## Publicação (produção)
O Portal roda no servidor da rede interna (`172.16.100.35:8090`). O GitHub não alcança esse servidor, por isso **o servidor busca as Releases**:

```
PR → checks verdes → merge na main (não publica) → Release vX.Y.Z → o servidor implanta em até 5 min
```

Detalhes, rollback e acompanhamento estão em [`portal/deploy/README.md`](../portal/deploy/README.md).

## GitHub Pages: desativado
O Pages foi usado no começo do projeto e **foi desligado em 09/10/2026**: o Gerador e o cadastro (BDI, encargos) não podem ficar públicos.
- O domínio de verificação `neoguard.com.br` continua cadastrado na conta do GitHub (TXT `_github-pages-challenge-alandioneiron`), mas aparece como "Unverified".
- O CNAME `propostas.neoguard.com.br` → `alandioneiron.github.io` ainda existe na HostGator e deve ser apagado. Sem site no Pages, ele fica solto: outra conta do GitHub poderia tentar usar esse subdomínio.
- O endereço público do Portal (HTTPS, com login pelo AD) é assunto da Fase 2.
