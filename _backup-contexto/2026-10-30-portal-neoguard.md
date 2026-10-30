# Backup de contexto — Portal Neoguard (30/10/2026)

Documento para continuar o projeto em outra máquina. O repositório é **público**: aqui não há senhas, valores de `.env` nem dados de clientes. Os detalhes de infraestrutura que já estão no `CLAUDE.md` e no `README.md` não se repetem aqui.

## Objetivo
Portal interno da Neoguard Facilities.
- **Ficha de Implantação de Alarme Monitorado** (no ar desde 09/10/2026): o Comercial preenche a Etapa 1; a Equipe Técnica, a Etapa 2 e os testes; a CCON valida. Status e travas são automáticos. O botão "Enviar por e-mail" manda a ficha para TI/Suporte.
- **Gerador de Propostas Facilities**, servido em `/propostas/`: aguarda o cadastro real (BDI, CCTs, municípios), que vem do artefato do C.O e fica só no servidor.
- **Fase 2:** login pelo AD local (LDAPS), MFA fora da rede, HTTPS público. No fim do projeto, uma tela de configuração do e-mail de envio, só para admin, onde o Alan troca a senha do SMTP.

## O que está pronto
- Backend FastAPI + PostgreSQL (287 testes), frontend React/Ant Design fiel ao docx (141 testes) e deploy Docker Compose + Nginx (porta 8090, rede interna, sem login nesta fase).
- Produção no servidor interno (endereço no `CLAUDE.md`), seguindo a `main` no commit do PR #14. Os vendedores já usam.
- E-mail: conta de envio configurada no `.env` do servidor. Em 28/10 a senha foi trocada pelo Alan, com o script `trocar-senha-smtp.sh`.
- Backup diário do banco às 02:30 (cron do root no servidor), com retenção de 14 dias.
- CI: 5 checks obrigatórios na `main`; Dependabot ativo.
- Processo de sincronização com o artefato do C.O: `docs/SINCRONIZAR-ARTEFATO.md`, `npm run importar-artefato` e `upstream/`.

## Em andamento
- **PR #20** (`portal/operacao`), **verde nos 5 checks**, aguardando o OK do Alan para o merge. O auto-merge foi negado pela checagem de permissões do Claude, então o merge é manual ou com a autorização dele. Conteúdo:
  - deploy por Release (`portal/deploy/seguir-release.sh` + timer systemd);
  - `release.yml` sem GitHub Pages;
  - `trocar-senha-smtp.sh`;
  - frontend com react-router 7, Vite 8 e Vitest 5 (`npm audit` limpo) e ajustes para tablet;
  - documentação.

## Próximos passos (na ordem)
1. Mesclar o PR #20 (com o OK do Alan).
2. Instalar o timer no servidor (comandos em `portal/deploy/README.md`, seção "Instalar o deploy automático").
3. Publicar a Release `v1.0.0` quando o Alan pedir: o servidor implanta em até 5 min.
4. Fechar o PR #16 do Dependabot (configure-pages; o Pages saiu) e avaliar os #15, #17 e #19.
5. Esperar o Alan responder:
   - se pode apagar o CNAME `propostas.neoguard.com.br` na HostGator (solto desde que o Pages foi desligado);
   - os dados do AD (controlador de domínio, domínio, LDAPS, faixas de rede) para a Fase 2.
6. Quando o C.O avisar "pronto para o GitHub": sincronizar o artefato (procedimento no `CLAUDE.md`) e copiar o cadastro para o servidor.

## Decisões e porquês
- **Repositório público, cadastro real fora do git:** o código pode ser aberto; BDI e encargos, não. Um teste garante que `data/` fica vazio.
- **Sem login na Fase 1, só rede interna:** o Comercial precisava da Ficha logo. A ficha tem dados sensíveis (mapa do alarme), por isso a porta não vai para a internet. **A porta 8090 fica no ar até o Alan dizer que o projeto acabou.**
- **Merge na `main` não publica; produção só por Release:** regra do Alan desde o início. Como o servidor está na rede interna e o GitHub não chega nele, o servidor é que busca as Releases.
- **Mesmo servidor do Access-Control, mas isolado:** projeto compose próprio, rede e volumes próprios, sempre `-p portal-neoguard`.
- **Visual da Ficha = docx original** (marinho #1B2A4A e dourado #B8963E): a versão em Google Forms foi rejeitada por não ser fiel ao documento.

## Como rodar e publicar
- Local: veja `README.md`, `portal/backend/README.md` e `portal/frontend/README.md`.
- Testes antes do PR: `npm test`, `npm run test:e2e`, `npm run validate`, `python -m pytest` em `portal/backend` e `npm test -- --run` + `npm run build` em `portal/frontend`.
- Publicar: PR → checks verdes → merge → Release `vX.Y.Z`. Detalhes em `CONTRIBUTING.md` e `portal/deploy/README.md`.

## Onde ficam os segredos (só caminhos)
- `.env` de produção (banco, SMTP): **no servidor**, em `/opt/portal-neoguard/.env` (chmod 600). Não está nesta máquina.
- Chave SSH de acesso ao servidor: em `~/.ssh/` do usuário nesta máquina, a mesma usada no projeto Access-Control.
- Login do GitHub CLI: no cofre de credenciais do Windows (`gh auth`). Na máquina nova, refazer com `gh auth login`.

## O que fica fora do git e precisa ser levado à mão
- A memória completa do Claude: `C:\Users\Alan\.claude\projects\D--Gerador-de-Processo\memory\` (veja `memoria-claude/README.md`).
- A chave SSH do servidor (pasta `~/.ssh/`).
- O GitHub CLI fica em `C:\Users\Alan\tools\gh\bin\gh.exe`: reinstale ou copie, depois faça `gh auth login`.
- Não precisam ir (são regeneráveis):
  - `node_modules/`, `portal/frontend/node_modules/`, `portal/backend/.venv/`: refaça com `npm ci` e `python -m venv` + `pip install -r requirements-dev.txt`;
  - `cadastro-local/`: ainda não existe; viria do C.O.

## Prompt para retomar (colar no Claude Code, na pasta do projeto na máquina nova)
```text
Estou retomando o Portal Neoguard (repo alandioneiron/Portal-Neoguard) numa máquina nova.
Leia o CLAUDE.md e o _backup-contexto/2026-10-30-portal-neoguard.md e confira:
1) git fetch e estado dos PRs abertos (o #20 estava verde aguardando meu OK);
2) se o gh está autenticado (gh auth status) e se a chave SSH do servidor funciona (ssh no servidor
   de produção indicado no CLAUDE.md, só um "hostname");
3) a saúde da produção (/api/saude).
Depois me diga o que falta da lista "Próximos passos" e siga pela ordem, pedindo meu OK para merge,
Release e qualquer mudança no servidor.
```
