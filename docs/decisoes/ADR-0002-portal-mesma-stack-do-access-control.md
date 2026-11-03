# ADR-0002 - O repositório vira o Portal, com a mesma stack do Access-Control

- **Data:** 2026-10-09
- **Status:** Aceito
- **Decisores:** Tech Lead + Alan

## Contexto
O projeto começou como o Gerador de Propostas, um site estático convertido de um artefato do Claude. O Alan pediu uma plataforma interna com login pelo AD, reunindo a Ficha de Implantação de Alarme Monitorado e o Gerador.

## Decisão
- O repositório `Gerador-de-Processo` foi renomeado para `Portal-Neoguard` e o Gerador passou a ser um módulo, em `/propostas/`.
- Stack igual à do Access-Control: FastAPI + SQLAlchemy/Alembic + PostgreSQL 16, React + Ant Design, Nginx, Docker Compose.
- Roda no mesmo servidor, mas isolado: projeto `portal-neoguard`, rede e volumes próprios, e só a porta 8090 publicada.

## Alternativas consideradas
- Repositório novo: começaria sem histórico, sem CI e sem regras.
- VM separada: dá mais isolamento, mas exige outro servidor para manter.

## Consequências
- O histórico, o CI e o processo do C.O foram mantidos.
- Os comandos Docker no servidor precisam sempre de `-p portal-neoguard` e `-f`, porque o Access-Control aciona hardware real.
