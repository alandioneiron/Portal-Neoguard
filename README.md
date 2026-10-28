# Portal Neoguard

Portal interno da Neoguard Facilities, com as ferramentas do Comercial, da equipe técnica e da CCON.

- **Acesso:** http://172.16.100.35:8090
- **Funciona só na rede da Neoguard.** Nesta fase não há login: quem preenche informa nome e e-mail.
- **Repositório:** https://github.com/alandioneiron/Portal-Neoguard

> **Repositório público.** Nunca coloque aqui dados de clientes reais, propostas emitidas, planilhas internas ou o cadastro real (BDI, encargos, CCTs). Um dado enviado ao git fica no histórico, mesmo depois de apagado.

---

## Módulos

| Módulo | Situação |
|---|---|
| **Ficha de Implantação de Alarme Monitorado** (`/fichas`) | No ar (Fase 1). Guia para usuários: [docs/portal/GUIA-RAPIDO-FICHA.md](docs/portal/GUIA-RAPIDO-FICHA.md) |
| **Gerador de Propostas** (`/propostas/`) | No ar, aguardando o cadastro real no servidor para calcular |
| Login pelo AD, MFA e acesso pela internet | Fase 2. Quando entrar, a porta 8090 deixa de ser a entrada |

## Estrutura

```
portal/                 o Portal
  backend/              API da ficha (FastAPI + SQLAlchemy + PostgreSQL)
  frontend/             telas da ficha (React + Ant Design)
  deploy/               Docker Compose, Nginx, deploy e teste de fumaça
docs/portal/            contrato da Fase 1 (ESPEC-FASE1.md) e guia rápido da ficha
docs/                   configuração do GitHub e sincronização com o artefato do C.O
index.html, js/, assets/, data/, scripts/, tests/
                        o Gerador de Propostas (site estático, servido em /propostas/)
upstream/               última versão sincronizada do artefato do C.O
.github/                CI, release e modelos de PR e issue
```

## Rodar localmente

Pré-requisitos: Python 3.12 ou mais novo, Node.js 22 e Docker (só para o teste de fumaça da pilha).

**Portal**

- Backend (FastAPI): veja [portal/backend/README.md](portal/backend/README.md). Em resumo: `alembic upgrade head` e `uvicorn app.main:app --port 8000`.
- Frontend (React): veja [portal/frontend/README.md](portal/frontend/README.md). `npm run dev` abre em http://localhost:5173; `npm run dev:mock` roda sem o backend.
- Pilha completa em Docker e teste de fumaça: veja [portal/deploy/README.md](portal/deploy/README.md).

**Gerador de Propostas**

```
npm ci
npm start              # http://localhost:8080, lendo data/ (esqueleto vazio, sem cadastro real)
npm run start:teste    # http://localhost:8080, com dados fictícios de tests/fixtures
npm run start:local    # http://localhost:8080, com o cadastro real em cadastro-local/ (se você tiver a cópia)
```

## Servidor

O Portal roda em Docker no servidor `172.16.100.35`, na mesma VM do Access-Control. Por isso os comandos Docker usam sempre o projeto `portal-neoguard`. A atualização acontece por Release (`vX.Y.Z`). Detalhes em [portal/deploy/README.md](portal/deploy/README.md).

## Contribuir

Toda mudança entra por branch e Pull Request. A `main` é protegida e merge na `main` não publica. Só uma Release `vX.Y.Z` atualiza o servidor. O passo a passo, os checks obrigatórios e as regras de versão estão em [CONTRIBUTING.md](CONTRIBUTING.md).

Regras do repositório e instruções para o Claude Code estão em [CLAUDE.md](CLAUDE.md). O histórico de mudanças está em [CHANGELOG.md](CHANGELOG.md).

---

## Gerador de Propostas

O Gerador calcula a proposta de serviços com o preço pela convenção coletiva, o ISS e o vale-transporte cadastrados para o município. Ele gera:

- a **proposta**, em PDF (pronta para o cliente) e em .docx (para editar);
- a **memória de cálculo**, em .xlsx. É uso interno: não envie ao cliente.

**Para vendedores, em resumo:** informe cliente e município, adicione os postos (a página preenche piso, kit e ISS), confira os itens marcados como "a conferir" e baixe a proposta quando aparecer "Tudo conferido. Pode emitir." Se o município não estiver cadastrado, a página não calcula e oferece um pedido de cadastro.

**Para quem mantém:**

- o cadastro (parâmetros, convenções e municípios) não fica no git: veja a seção "Cadastro" do [CONTRIBUTING.md](CONTRIBUTING.md);
- o conteúdo vem do artefato mantido pelo C.O: veja [docs/SINCRONIZAR-ARTEFATO.md](docs/SINCRONIZAR-ARTEFATO.md);
- trocar o modelo da proposta e outras mudanças do Gerador: veja o [CONTRIBUTING.md](CONTRIBUTING.md).
