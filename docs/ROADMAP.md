# Roteiro

O status de cada item fica nas issues e nos PRs do GitHub; aqui só a ordem e o porquê. Detalhes da sessão atual: [HANDOFF.md](HANDOFF.md).

## Fase 1: Ficha de Implantação no ar ✅ (2026-10-09)
- [x] Ficha fiel ao docx, com status, travas, histórico, impressão e "Enviar por e-mail" (ADRs 0003, 0005, 0006).
- [x] Produção na porta 8090, rede interna, sem login.
- [x] Backup diário do banco.

## Operação (em andamento)
- [ ] Deploy por Release com o seguidor no servidor (ADR-0004) — PR #20 + instalação do timer.
- [ ] Primeira Release `v1.0.0`.
- [ ] Dependabot em dia (PRs #15, #16, #17, #19).
- [ ] Apagar o CNAME solto `propostas.neoguard.com.br` (aguardando OK).

## Gerador de Propostas como módulo
- [ ] Cadastro real vindo do artefato do C.O → servidor (ADR-0001; procedimento em [SINCRONIZAR-ARTEFATO.md](SINCRONIZAR-ARTEFATO.md)).
- [ ] Histórico central de propostas emitidas, com quem emitiu.
- [ ] Pedido de cadastro de CCT com upload do PDF, em vez de e-mail.

## Fase 2: login e acesso externo
- [ ] Login pelo AD local (LDAPS), com perfis por grupo (Comercial, Técnico, CCON, Admin). Aguardando os dados do AD.
- [ ] MFA (app autenticador) para acesso de fora da rede, com limite de tentativas.
- [ ] HTTPS público por proxy reverso (hostname a definir).
- [ ] Fechar a porta 8090 **só quando o Alan disser que o projeto terminou** (ADR-0003).

## Final do projeto
- [ ] Tela "Configurações → E-mail de envio" (só admin; senha só de escrita e criptografada; botão de teste) — ADR-0006.
- [ ] Exportação DOCX da ficha preenchida; alertas de prazo das pendências; integração com CRM/ERP (anexo E do docx).
