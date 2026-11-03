# ADR-0001 - Repositório público; cadastro real fora do git e do artefato

- **Data:** 2026-10-09
- **Status:** Aceito
- **Decisores:** Tech Lead + Alan

## Contexto
O Gerador de Propostas calcula preços a partir de um cadastro sensível (BDI, encargos, CCTs, ISS por município). Esse cadastro vinha do banco do artefato do C.O. O repositório no GitHub é público, e manter a proteção da `main` num repositório privado exigiria um plano pago.

## Decisão
O repositório continua público. O cadastro real nunca entra no git nem é publicado no artefato público:
- `data/*.json` guarda só o esqueleto vazio, e um teste (`tests/unit/cadastro-fora-do-git.test.mjs`) garante isso;
- o importador grava o cadastro em `cadastro-local/`, pasta ignorada pelo git;
- em produção, o cadastro fica em `/opt/portal-neoguard/cadastro/`, montado no contêiner como somente leitura.

O chat do C.O entrega o `cadastro.json` só para download, por canal interno.

## Alternativas consideradas
- Repositório privado + GitHub Pro: tudo privado, mas tem custo mensal.
- Repositório privado sem Pro: grátis, mas a `main` fica sem proteção.

## Consequências
- O CI, a proteção da `main` e o fluxo de PR continuam grátis.
- Toda contribuição precisa respeitar a regra.
- O cadastro chega ao servidor por um passo manual, que é responsabilidade do Tech Lead.
