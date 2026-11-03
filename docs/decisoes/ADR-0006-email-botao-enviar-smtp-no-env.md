# ADR-0006 - E-mail: botão "Enviar por e-mail" e SMTP só no `.env` do servidor

- **Data:** 2026-10-09
- **Status:** Aceito
- **Decisores:** Tech Lead + Alan

## Contexto
O Alan pediu que o Comercial, ao terminar a ficha, tenha um botão para enviá-la a ti@, suporte@ e aux.ti@. O envio usa a conta de e-mail da empresa. O repositório é público.

## Decisão
- Ação `enviar-email`: envia na hora a ficha completa, com o layout do docx no corpo HTML.
  - O Reply-To é quem preencheu, e o envio fica no histórico.
  - Se falhar, a tela mostra o erro e nada é registrado.
- Avisos automáticos só nas transições de status (o `criou` não envia, para não gerar ruído).
- A configuração do SMTP, inclusive a senha, fica **só** em `/opt/portal-neoguard/.env` (chmod 600), nunca no repositório.
- Para trocar a senha, use `portal/deploy/trocar-senha-smtp.sh`: ele pede a senha sem eco, testa o login antes de gravar e recria só a API.
- **No final do projeto:** criar a tela "Configurações → E-mail de envio", restrita ao grupo admin do AD, com a senha só de escrita e criptografada, para o Alan trocar a senha por ela.

## Alternativas consideradas
- Senha no repositório ou na imagem: proibido (ADR-0001).
- Tela de configuração já na Fase 1: sem login, qualquer pessoa da rede poderia trocar o e-mail.

## Consequências
Em 2026-10-28, uma troca de senha no cPanel quebrou o envio ("535 Incorrect authentication data"). O script resolveu. Toda troca de senha no cPanel precisa ser repetida no Portal.
