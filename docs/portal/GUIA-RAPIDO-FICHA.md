# Ficha de Implantação de Alarme Monitorado: guia rápido

Para vendedores (Comercial), equipe técnica e CCON (central de monitoramento). Este guia explica como usar o portal sem termos técnicos.

**Endereço:** http://172.16.100.35:8090

O portal funciona **só na rede da Neoguard**. Se não abrir, confira se o computador está na rede da Neoguard e, se continuar sem abrir, fale com o TI.

---

## 1. Entrar e se identificar

Nesta fase o portal não tem senha. Na primeira vez que for salvar ou fazer uma ação, ele pede **nome** e **e-mail**. Esses dados ficam guardados neste navegador, aparecem no histórico da ficha e são o destino das respostas dos e-mails.

Se o computador for de outra pessoa, clique em **Trocar**, no topo da página, antes de preencher.

## 2. Criar e encontrar fichas

- Em **Fichas de Implantação**, clique em **Nova ficha**. A ficha ganha um código (por exemplo, FI-2026-0007) e começa em *Cadastro em preenchimento*.
- Para achar uma ficha, use a busca (cliente, vendedor, código ou CPF/CNPJ) e o filtro por status.

## 3. As etapas e quem preenche

A faixa no topo da ficha mostra em que etapa ela está: **Venda fechada → Cadastro → Instalação/configuração → Testes → Validação CCON → Ativo/monitorado**.

| Etapa (aba) | O que preenche | Quem preenche |
|---|---|---|
| **Etapa 1: Cadastro** (seções 1.1 a 1.8) | Dados do cliente, contatos para ocorrência, usuários do alarme, áreas, ambientes, rotina, particularidades e orientações para a CCON | Comercial |
| **Etapa 2: Instalação** (seções 2.1 a 2.6) | Central, comunicação, zonas, partições, confirmação dos usuários na central e configurações | Equipe Técnica |
| **Etapa 3: Testes e ativação** | 3.1 testes técnicos: Equipe Técnica. 3.2 testes com a CCON: CCON. 3.3 validação: CCON | Técnica e CCON |

Cada etapa tem o botão **Salvar** no rodapé. Quando uma etapa não pode mais ser alterada no status atual, a tela fica somente leitura e mostra o motivo.

## 4. Salvar

- Ao alterar algo, aparece **Alterações não salvas**. Clique em **Salvar**.
- O portal avisa se você tentar sair da ficha com alterações não salvas.
- Se aparecer o aviso de que a ficha foi alterada por outra pessoa, clique em **Recarregar** e confira a ficha antes de continuar.

## 5. Enviar por e-mail

Use o botão **Enviar por e-mail** (no topo da ficha ou no rodapé da Etapa 1) para mandar a ficha ao TI. Ele pode ser usado em qualquer status.

1. Se houver alterações não salvas, o portal pergunta *Salvar antes de enviar?*. Escolha **Salvar e enviar**.
2. Confira os destinatários (ti@neoguard.com.br, suporte@neoguard.com.br e aux.ti@neoguard.com.br), escreva uma mensagem se quiser e envie.
3. O e-mail leva a ficha completa e tem o assunto *[Ficha FI-2026-0007] Ação — Cliente*. A resposta de quem receber vai direto para o seu e-mail.

Se o envio falhar, o portal mostra o motivo e a ficha não registra o envio. Avise o TI.

## 6. Liberar, concluir e validar

Estas três ações mudam a ficha de etapa. O botão só fica habilitado quando o que falta está preenchido. Antes de clicar, a lista **Falta resolver antes de …** mostra o que ainda falta.

**Liberar para instalação** (Comercial, na Etapa 1)

Exige:
- razão social, endereço completo, telefone, vendedor e data prevista;
- pelo menos 1 contato com nome e telefone principal;
- pelo menos 1 usuário com nome e permissão (arma e desarma, ou só arma);
- para quem usa o aplicativo, o e-mail para o convite.

Depois: a Etapa 1 fica somente leitura e a equipe técnica é avisada por e-mail. Para corrigir o cadastro depois, registre uma pendência cadastral.

**Concluir instalação** (Equipe Técnica, na Etapa 2)

Exige:
- modelo da central (se escolher "Outro", escreva qual) e número de série;
- comunicação principal;
- pelo menos 1 zona com ambiente e dispositivo;
- em 2.5, **Sim** para confirmar que os usuários da 1.3 foram cadastrados na central;
- se há áreas independentes (1.4 = Sim), o nome da área A (2.4).

Depois: a Etapa 2 fica somente leitura e a ficha segue para os testes da Etapa 3.

**Validar CCON** (CCON, na Etapa 3.3)

Para aprovar, exige:
- todos os testes da 3.1 e da 3.2 marcados. Não são exigidos: "comunicação de contingência", quando a contingência for "não possui"; e "aplicativo", quando nenhum usuário usa o app;
- operador, data e hora da validação;
- os 5 itens da 3.3 (Cadastro, Comunicação, Eventos, Contatos e Regras operacionais) marcados como **OK**.

O resultado pode ser:
- **Aprovado**: a ficha vira **ATIVO / MONITORADO** e fica somente leitura.
- **Reprovado**: a ficha volta para **Pendência técnica**.

## 7. Status da ficha

| Status | O que significa |
|---|---|
| Cadastro em preenchimento | Comercial preenche a Etapa 1 |
| Pendência cadastral | O cadastro precisa de correção |
| Liberado para instalação | Equipe técnica pode começar. Ao salvar a Etapa 2 pela primeira vez, passa a *Em instalação* |
| Em instalação | Equipe técnica preenche a Etapa 2 |
| Pendência técnica | Algo precisa de correção na instalação ou nos testes |
| Instalação concluída | Equipe técnica faz os testes da 3.1. Quando todos estiverem marcados, a ficha passa sozinha para a próxima linha |
| Aguardando testes com a CCON | CCON faz os testes da 3.2 e a validação da 3.3 |
| ATIVO / MONITORADO | Validada pela CCON. Somente leitura |

## 8. Pendências

Quando algo precisa de correção, clique em **Registrar pendência** no rodapé da etapa. Esse botão não aparece em ficha ativa.

- **Tipo**: *Cadastral* (volta o cadastro para correção) ou *Técnica* (instalação ou testes). O portal já sugere o tipo pelo status da ficha.
- **Descrição**: obrigatória. Responsável e prazo são opcionais.

Quando a pendência for resolvida, marque **Resolvido** na aba **Pendências** e clique em **Retomar**. A ficha volta ao fluxo: a pendência cadastral volta para *Cadastro em preenchimento*, e a técnica volta para *Em instalação* (ou para *Aguardando testes com a CCON*, se a instalação já tinha sido concluída).

## 9. Histórico e impressão

- **Histórico**: mostra quem fez cada ação, quando e o que mudou.
- **Imprimir / PDF** (topo da ficha): abre a ficha em A4, com o mesmo layout do formulário e o bloco de assinaturas (Comercial, Equipe Técnica e CCON). Na janela de impressão, escolha **Salvar como PDF**. A impressão usa o que está salvo, então salve antes.

## 10. O que NÃO colocar

- **Senhas** de nenhum tipo: do alarme, dos usuários, do aplicativo ou da rede. A tabela de usuários não tem campo de senha.
- **A palavra de segurança**: na 1.8, o portal só pergunta se o cliente quer uma. Não escreva a palavra em nenhum campo nem em observações.

## 11. Deu problema?

Fale com o TI (ti@neoguard.com.br). Informe o código da ficha (por exemplo, FI-2026-0007), o que você estava fazendo e, se aparecer, a mensagem de erro. Uma foto da tela ajuda.
