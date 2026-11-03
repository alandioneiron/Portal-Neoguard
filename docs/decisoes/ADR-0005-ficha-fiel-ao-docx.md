# ADR-0005 - A Ficha digital é fiel ao docx (o Google Forms foi rejeitado)

- **Data:** 2026-10-09
- **Status:** Aceito
- **Decisores:** Tech Lead + Alan

## Contexto
A primeira tentativa de digitalizar a Ficha de Implantação foi um Google Forms gerado por Apps Script. O Alan rejeitou: "muita página sem necessidade, muito diferente do que mandei". O Forms não tem tabelas, e a ficha virou 32 seções.

## Decisão
A Ficha no Portal reproduz o docx original:
- as mesmas seções e numeração (1.1 a 3.3, 9, 10), com os mesmos rótulos e colunas;
- as tabelas continuam tabelas editáveis, com "+ Adicionar linha";
- os checkboxes ficam lado a lado, na grade do docx;
- cada etapa ocupa uma tela;
- o visual é o do documento: marinho #1B2A4A, dourado #B8963E e fonte Arial.

As recomendações do anexo do docx viraram regras: campos condicionais, travas por etapa, preenchimento único da 1.3 na 2.5, status ATIVO só com a aprovação da CCON e histórico.

## Alternativas consideradas
- Formulário genérico (Forms ou similar): rejeitado pelo usuário.

## Consequências
Mudanças no docx de referência exigem ajuste na tela, no contrato (`docs/portal/ESPEC-FASE1.md`) e nos testes.
