# Definição de Pronto (DoD)

Nada está "concluído" até todos os itens estarem marcados. Vale para qualquer pessoa ou agente. Marque item a item à medida que cada um termina, não todos de uma vez no fim.

- [ ] Requisito ou critério de aceite atendido e demonstrado (teste ou evidência)
- [ ] Testes escritos e passando (ou ausência justificada):
  - [ ] Gerador: `npm test`, `npm run test:e2e`, `npm run validate`
  - [ ] Portal: `python -m pytest` em `portal/backend`; `npm test -- --run` e `npm run build` em `portal/frontend`
- [ ] Código revisado pelo Tech Lead. Mudanças de segurança, dados ou dinheiro (SMTP, cadastro, travas, cálculo) passam por uma revisão independente.
- [ ] Sem segredos em código, commits ou logs (repositório público; ADR-0001)
- [ ] Documentação viva atualizada na mesma tarefa:
  - [ ] `CHANGELOG.md`, seção "Não publicado"
  - [ ] Contrato `docs/portal/ESPEC-FASE1.md`, se mudou campo, status, trava, API ou e-mail
  - [ ] `README.md`, `CONTRIBUTING.md`, `portal/deploy/README.md` ou guias, se mudou fluxo ou configuração
- [ ] Decisões registradas como ADR em `docs/decisoes/`, se houve alguma
- [ ] PR com os 5 checks verdes (mesclar na `main` não publica)
- [ ] Uma linha no `docs/LOG-SESSOES-IA.md`
- [ ] `docs/HANDOFF.md` reescrito no fim da sessão
