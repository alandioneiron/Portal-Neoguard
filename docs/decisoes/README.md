# Registro de Decisões (ADR)

Toda decisão de arquitetura, processo ou segurança vira um ADR aqui. Para uma decisão nova: copie o modelo do fim desta página, use o próximo número, acrescente a linha na tabela e cite o ADR no PR que a aplica. Datas no formato `AAAA-MM-DD`. ADR aceito não se edita: se a decisão mudar, crie um novo e marque o antigo como "Substituído por ADR-XXXX".

| ADR | Data | Decisão | Status |
|---|---|---|---|
| [ADR-0001](ADR-0001-repositorio-publico-cadastro-fora-do-git.md) | 2026-10-09 | Repositório público; cadastro real fora do git e do artefato | Aceito |
| [ADR-0002](ADR-0002-portal-mesma-stack-do-access-control.md) | 2026-10-09 | O repositório vira o Portal, com a mesma stack do Access-Control | Aceito |
| [ADR-0003](ADR-0003-fase-1-sem-login-rede-interna.md) | 2026-10-09 | Fase 1 sem login, só rede interna, porta 8090 no ar até o fim do projeto | Aceito |
| [ADR-0004](ADR-0004-producao-so-por-release-servidor-busca.md) | 2026-10-09 | Produção só por Release; o servidor busca as Releases | Aceito |
| [ADR-0005](ADR-0005-ficha-fiel-ao-docx.md) | 2026-10-09 | A Ficha digital é fiel ao docx (o Google Forms foi rejeitado) | Aceito |
| [ADR-0006](ADR-0006-email-botao-enviar-smtp-no-env.md) | 2026-10-09 | E-mail: botão "Enviar por e-mail" e SMTP só no `.env` do servidor | Aceito |
| [ADR-0007](ADR-0007-adotar-tech-lead-vault.md) | 2026-11-03 | Adotar o método tech-lead-vault no modo Adotar | Aceito |

## Modelo

```markdown
# ADR-XXXX - <título da decisão>

- **Data:** AAAA-MM-DD
- **Status:** Proposto / Aceito / Substituído por ADR-YYYY
- **Decisores:** Tech Lead + Alan

## Contexto
Qual o problema e as forças em jogo?

## Decisão
O que foi decidido.

## Alternativas consideradas
- A - prós/contras
- B - prós/contras

## Consequências
Impactos positivos e negativos; o que passa a valer.
```
