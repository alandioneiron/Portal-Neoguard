# ADR-0003 - Fase 1 sem login, só rede interna, porta 8090 no ar até o fim do projeto

- **Data:** 2026-10-09
- **Status:** Aceito
- **Decisores:** Tech Lead + Alan

## Contexto
O Comercial precisava da Ficha de Implantação o quanto antes, e o login pelo AD depende de informações que ainda não chegaram (controlador de domínio, LDAPS, grupos). O Alan pediu acesso por porta, sem usuário e senha, enquanto o login não fica pronto. A ficha guarda dados sensíveis dos clientes: CPF/CNPJ, endereço, contatos e o mapa do alarme.

## Decisão
- A Fase 1 sai sem login, em `http://<servidor>:8090`, **só na rede interna**, sem NAT para a internet.
- Quem preenche se identifica com nome e e-mail, que ficam no histórico e no Reply-To.
- A porta 8090 fica no ar **até o Alan dizer que o projeto terminou**. Os acessos novos (AD, MFA, HTTPS público) entram sem derrubá-la.

## Alternativas consideradas
- Abrir para a internet sem senha: rejeitado, porque exporia os dados do alarme dos clientes.
- Esperar o AD: atrasaria o Comercial.

## Consequências
- Quem está em campo precisa de VPN até a Fase 2.
- Qualquer pessoa na rede interna consegue ver e editar as fichas. É um risco aceito temporariamente.
