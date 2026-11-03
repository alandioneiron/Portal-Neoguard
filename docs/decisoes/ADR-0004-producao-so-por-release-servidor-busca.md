# ADR-0004 - Produção só por Release; o servidor busca as Releases

- **Data:** 2026-10-09
- **Status:** Aceito
- **Decisores:** Tech Lead + Alan

## Contexto
A regra do Alan desde o início: toda mudança entra por PR com testes, o merge na `main` não publica, e a produção só muda quando ele abre uma Release. O servidor fica na rede interna, onde o GitHub Actions não chega.

## Decisão
- O fluxo é PR → 5 checks obrigatórios → merge na `main` → Release `vX.Y.Z` (só com o OK do Alan).
- O servidor consulta a última Release a cada 5 minutos (`portal/deploy/seguir-release.sh` com timer systemd) e implanta a tag.
- Antes de implantar, ele confere o formato da tag, se o commit está na `main` e se a tag contém o Portal.
- Deploy manual só em emergência, e sempre com `--ref`.

## Alternativas consideradas
- Runner self-hosted no servidor: daria ao GitHub acesso de execução a uma máquina que divide espaço com sistemas de hardware.
- Deploy por SSH a partir do Actions: exigiria abrir acesso de entrada ao servidor.

## Consequências
- Não há credencial do servidor no GitHub.
- Uma Release ruim volta com uma Release de correção ou pelo rollback descrito em `portal/deploy/README.md`.
- Até o timer ser instalado (pendente do merge do PR #20), o deploy é manual.
