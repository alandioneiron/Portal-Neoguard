# Promover para produção (Release)

Só com o **OK explícito do Alan** (ADR-0004). Copie esta lista para a issue ou o PR da Release e marque item a item. Detalhes técnicos em [`portal/deploy/README.md`](../../portal/deploy/README.md).

## Antes
- [ ] OK do Alan registrado (na conversa ou na issue)
- [ ] Tudo o que vai sair está na `main`, por PR, com os 5 checks verdes
- [ ] `CHANGELOG.md`: a seção "Não publicado" vira `## [vX.Y.Z] - AAAA-MM-DD`
- [ ] Versão SemVer escolhida: patch = correção; minor = função nova; major = mudança de modelo ou de método
- [ ] Migração de banco nova? Backup manual feito antes (`portal/deploy/backup-db.sh`)

## Publicar
- [ ] GitHub → Releases → *Draft a new release* → tag nova `vX.Y.Z` a partir da `main` → notas → **Publish**
- [ ] Workflow "Release → Produção" verde

## Depois (até 5 min)
- [ ] `/api/saude` mostra o commit da tag
- [ ] `/opt/portal-neoguard/versao-implantada` igual à tag, e `deploy.log` sem erro
- [ ] Teste rápido na tela: lista de fichas abre, uma ficha abre, "Enviar por e-mail" funciona
- [ ] Linha no `docs/LOG-SESSOES-IA.md` e `docs/HANDOFF.md` atualizado ("Em produção agora")

## Se der errado
- [ ] Rollback pela opção do `portal/deploy/README.md` (Release de correção, ou voltar à tag anterior segurando o timer)
- [ ] Registrar a falha no log, com honestidade: o que quebrou e como voltou
