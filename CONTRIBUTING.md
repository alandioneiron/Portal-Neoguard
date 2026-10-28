# Como contribuir

Este guia cobre o fluxo de mudança (branch, Pull Request, merge e release), o Portal, o cadastro do Gerador de Propostas e a troca do modelo da proposta. Para usar o Gerador, veja o [README](README.md).

## Fluxo em resumo

```
branch → Pull Request → checks verdes → merge na main → Release vX.Y.Z (atualiza o servidor)
```

- Toda mudança entra por Pull Request. A `main` é protegida.
- Os checks obrigatórios são cinco, listados na seção [Portal](#portal).
- Merge na `main` **não publica**.
- Produção só muda com uma **Release** com tag `vX.Y.Z`. Pré-release não publica.
- O Portal e o Gerador de Propostas vão juntos para o servidor: a release atualiza os dois, em até 5 minutos.

---

## 1. Criar a branch

Parta sempre da `main` atualizada:

```
git switch main
git pull
git switch -c dados/cct-sp-2027
```

Convenção de nomes (minúsculas, com hífen):

| Prefixo | Use para | Exemplo |
|---|---|---|
| `feat/` | função nova | `feat/filtro-historico` |
| `fix/` | correção | `fix/arredondamento-vt` |
| `dados/` | cadastro: município, CCT ou parâmetros (mudanças no cadastro vêm do artefato do C.O, veja a seção Cadastro) | `dados/municipio-campinas-sp` |
| `portal/` | Portal: backend, frontend ou deploy | `portal/ficha-validacao-ccon` |

## 2. Testar antes do Pull Request

```
npm ci               # primeira vez, ou quando package-lock.json mudar
npm run validate     # valida data/ (erro bloqueia)
npm test             # testes unitários
npm start            # http://localhost:8080, confira na tela o que mudou
npm run test:e2e     # testes no navegador (na primeira vez: npx playwright install chromium)
```

Para o Portal, rode também os testes da seção [Portal](#portal).

## 3. Commit e push

Adicione só os arquivos alterados:

```
git add index.html js/app.js
git commit -m "fix: texto do aviso de convenção vencida"
git push -u origin fix/aviso-convencao
```

Recomendado: mensagem com o prefixo do tipo (`feat:`, `fix:`, `dados:` ou `portal:`) e um resumo curto no imperativo.

## 4. Abrir o Pull Request

```
gh pr create --base main --fill
```

Ou pelo GitHub, que mostra o botão **Compare & pull request** logo após o push. Preencha o modelo de PR que aparece.

Os checks rodam sozinhos. O PR só pode ser mesclado com os checks obrigatórios verdes (lista na seção [Portal](#portal)) e com a branch atualizada em relação à `main`. Se um check falhar, abra a execução em **Actions**, leia o erro e corrija na mesma branch com um novo commit.

## 5. Merge e limpeza

Mescle pelo botão **Merge pull request**. Depois:

```
git switch main
git pull
git branch -d dados/municipio-campinas-sp
```

Merge na `main` não publica nada. A produção só muda com a release (seção 6).

## 6. Publicar uma release (produção)

Só a release muda o que a equipe usa. Antes de publicar, confirme:

- a `main` tem o que deve ir para produção e os checks estão verdes;
- o CHANGELOG tem a seção da nova versão (ver abaixo);
- o Alan pediu a publicação.

Pela interface do GitHub:

1. Abra o repositório, clique em **Releases** e depois em **Draft a new release**.
2. Em **Choose a tag**, digite a tag nova (por exemplo `v1.1.0`) e escolha **Create new tag: v1.1.0 on publish**.
3. Em **Target**, escolha `main`.
4. Em **Release title**, use a mesma tag (`v1.1.0`).
5. Clique em **Generate release notes** e revise o texto.
6. Deixe **Set as a pre-release** desmarcado. Pré-release não publica.
7. Clique em **Publish release**.

Depois da publicação, o servidor atualiza em até 5 minutos. Para conferir, abra http://172.16.100.35:8090/api/saude na rede da Neoguard: o campo `versao` mostra o commit da release.

Alternativa pelo terminal:

```
gh release create v1.1.0 --target main --title "v1.1.0" --generate-notes
```

Uma tag fora do formato `vX.Y.Z` faz o workflow de release falhar com "Tag inválida". Nesse caso, apague a release e a tag e publique de novo com uma tag válida.

### CHANGELOG antes da release

Antes de publicar, mova os itens da seção **Não publicado** do [CHANGELOG.md](CHANGELOG.md) para uma seção com a nova versão, por exemplo `## [1.1.0] - 2026-11-03`, e deixe **Não publicado** vazio. Pode ser num PR próprio ou junto da mudança.

---

## Regra de versão

| Tipo de mudança | Versão | Exemplos |
|---|---|---|
| Correção ou cadastro | patch (`v1.0.1`) | município novo, CCT nova, valor de piso ou kit, correção de texto |
| Função nova | minor (`v1.1.0`) | filtro no histórico, nova escala |
| Mudança de modelo ou de método | major (`v2.0.0`) | novo modelo de proposta, nova fórmula de cálculo |

---

## Cadastro (fora do git)

O cadastro real (parâmetros Neoguard, convenções e municípios) **não vai para o git**. O repositório guarda só o esqueleto vazio em `data/`, e um teste garante isso.

Onde ele fica:

- **Fonte:** o banco do artefato do C.O. Mudanças de cadastro são pedidas ao C.O, que as faz no artefato. A sincronização está em [docs/SINCRONIZAR-ARTEFATO.md](docs/SINCRONIZAR-ARTEFATO.md).
- **Cópia local:** `cadastro-local/`, ignorada pelo git, gerada pelo importador. Para testar com ela: `npm run start:local`.
- **Servidor:** `/opt/portal-neoguard/cadastro/`, servida pelo Nginx em `/propostas/data/`. Atualizar o cadastro no servidor não exige deploy nem reinício (ver [portal/deploy/README.md](portal/deploy/README.md), seção "Cadastro real do Gerador").

As tabelas abaixo descrevem os campos de cada arquivo. Valide a cópia local antes de copiar para o servidor:

```
node scripts/validate-data.mjs cadastro-local
```

### Regras gerais

- Arquivos em JSON válido, UTF-8.
- Número usa **ponto**: `0.05`, não `0,05`. Não coloque `%` nem aspas em número.
- **Percentuais são frações:** 5% é `0.05`; 100% é `1`. O validador pega o erro comum de digitar `5` no lugar de `0.05`, porque o limite não aceita.
- **Ids** (de convenção e de município) só têm minúsculas, números e hífen: `limpeza-sp-2027`, `campinas-sp`.
- Campos extras dentro de um objeto são ignorados. Chave extra no topo de `ccts.json` ou `municipios.json` vira um id e falha na validação (por exemplo, um `_aviso` no topo). Coloque observações no texto do PR, não no arquivo.
- Não cadastre valor chutado. Se um dado depende de confirmação (por exemplo, o ISS), registre em `alertas` do município. Assim a página exige a conferência do vendedor.
- Erros de validação bloqueiam. Avisos são lembretes: por exemplo, CCT sem `vigencia_fim` ou CCT vencida.

### `data/config.json`: parâmetros Neoguard

Um objeto só. Os valores valem para todos os municípios.

| Campo | O que é | Unidade | Exemplo (só formato) | Limite validado |
|---|---|---|---|---|
| `dias.5x2` | Dias trabalhados por mês na escala 5x2. Base do VT e do VR. | dias | `22` | 1 a 31 |
| `dias.6x1` | Dias trabalhados por mês na escala 6x1. Base do VT e do VR. | dias | `26` | 1 a 31 |
| `dias.12x36` | Dias trabalhados por mês na escala 12x36. Base do VT e do VR. | dias | `15` | 1 a 31 |
| `plant` | Plantões por mês de cada posto 12x36. Base do adicional noturno e do intervalo indenizado. | plantões/mês | `15` | 1 a 31 |
| `vtd` | Desconto de VT pago pelo colaborador, sobre o salário-base. | fração | `0.06` = 6% | 0 a 0.06 |
| `seg` | Seguro de vida por colaborador. | R$ por colaborador/mês | `10` | 0 a 2000 |
| `aso` | ASO por colaborador. Some já mensalizado. | R$ por colaborador/mês | `8` | 0 a 2000 |
| `trein` | Treinamento por colaborador. Some já mensalizado. | R$ por colaborador/mês | `15` | 0 a 2000 |
| `matind` | Materiais individuais por colaborador. | R$ por colaborador/mês | `20` | 0 a 2000 |
| `bdi_adm` | BDI de administração. | fração | `0.05` = 5% | 0 a 0.5 |
| `bdi_luc` | BDI de lucro. | fração | `0.08` = 8% | 0 a 0.5 |
| `pis` | PIS sobre o preço. | fração | `0.0165` = 1,65% | 0 a 0.05 |
| `cofins` | COFINS sobre o preço. | fração | `0.076` = 7,6% | 0 a 0.1 |
| `res` | Reserva técnica sobre o custo dos materiais. | fração | `0.1` = 10% | 0 a 0.5 |
| `amort` | Meses para amortizar os equipamentos. | meses (inteiro) | `24` | 1 a 120 |
| `manut` | Manutenção dos equipamentos, sobre a amortização. | fração | `0.1` = 10% | 0 a 0.5 |

Os valores de exemplo acima vêm do arquivo fictício de testes e servem só para mostrar o formato.

Os campos `aso`, `trein` e `matind` entram no custo de cada colaborador a cada mês. Se um custo for anual ou eventual, transforme em valor mensal antes de cadastrar.

### `data/ccts.json`: convenções coletivas

Um objeto por convenção. A chave é o id da convenção, por exemplo `limpeza-sp-2027`.

| Campo | O que é | Unidade | Limite validado |
|---|---|---|---|
| `nome` | Nome da convenção, como aparece na página e na memória. | texto | obrigatório |
| `registro` | Número de registro no MTE ou Mediador. Vai para o histórico. | texto | obrigatório |
| `vigencia` | Período de vigência, em texto livre, como aparece na página. | texto | obrigatório |
| `vigencia_fim` | Último dia de vigência. | `AAAA-MM-DD` | opcional, mas recomendado |
| `sm` | Salário mínimo. Base do adicional de insalubridade. | R$ | 500 a 20000 |
| `acumulo` | Adicional de acúmulo de função. | fração | 0 a 1 |
| `hnot` | Horas de trabalho no período noturno por plantão 12x36. Plantão das 19h às 7h tem 7 horas noturnas (22h às 5h). | horas por plantão | 0 a 12 |
| `adn` | Adicional noturno. | fração | 0 a 1 |
| `enc` | Encargos sociais sobre a remuneração. | fração | 0 a 1.5 |
| `vr` | Vale-refeição ou alimentação, valor total por dia. | R$/dia | 0 a 500 |
| `vr_desc` | Parte do VR descontada do colaborador. Não pode passar de `vr`. | R$/dia | 0 a 500 |
| `premio` | Prêmio de assiduidade. Só entra nos postos que marcam o prêmio. | R$/mês | 0 a 20000 |
| `cesta` | Cesta básica. | R$/mês | 0 a 20000 |
| `ppr` | PPR. Valor anual; a página usa 1/12 por mês. | R$/ano | 0 a 20000 |
| `social` | Benefício social. | R$/mês | 0 a 20000 |
| `saude` | Assistência à saúde. | R$/mês | 0 a 20000 |
| `intervalo_h` | Horas de intervalo intrajornada por plantão 12x36. Pago a 150% do valor da hora. | horas por plantão | 0 a 4 |
| `pisos` | Lista de funções da convenção. | lista | pelo menos uma |

Cada item de `pisos`:

| Campo | O que é | Unidade | Limite validado |
|---|---|---|---|
| `id` | Código da função. Tem de ser único dentro da convenção e não pode começar com `__`, que é reservado. | texto | obrigatório |
| `nome` | Nome da função no seletor. Na proposta sai sem o texto entre parênteses no fim, por exemplo `Porteiro (controle de acesso)` sai como `Porteiro`. O vendedor pode editar. | texto | obrigatório |
| `piso` | Salário-piso da função. | R$/mês | 500 a 50000 |
| `kit` | Kit de uniforme por mês. `null` significa que não há valor cadastrado, e o vendedor informa na hora. | R$/mês | `null`, ou 0 a 2000 |
| `tipo` | Enquadramento do ISS. `limp` é limpeza e conservação (item 7.10). `mo` é mão de obra e portaria (item 17.05). | texto | `limp` ou `mo` |
| `obs` | Observação que aparece só para o vendedor ao escolher a função. Não vai para a proposta. | texto | opcional |

### `data/municipios.json`: municípios

Um objeto por município. A chave é o id do município, por exemplo `campinas-sp`.

| Campo | O que é | Unidade | Limite validado |
|---|---|---|---|
| `nome` | Nome do município. | texto | obrigatório |
| `uf` | Estado. | duas letras maiúsculas | por exemplo `SP` |
| `cct` | Id da convenção em `ccts.json`. | texto | tem de existir em `ccts.json` |
| `iss_limp` | ISS do município para limpeza (item 7.10). | fração | 0.02 a 0.05 (LC 116/2003) |
| `iss_mo` | ISS do município para mão de obra (item 17.05). | fração | 0.02 a 0.05 (LC 116/2003) |
| `vt_dia` | Valor de VT por dia trabalhado, somando as conduções do dia. | R$/dia | 0 a 200 |
| `vt_obs` | Observação sobre o VT. Aparece só para o vendedor. | texto | opcional |
| `alertas` | Pontos a conferir antes de emitir. Cada texto vira uma caixa de "Conferi" obrigatória. Lista vazia ou campo ausente quando não há pendência. | lista de textos | opcional |

Regra de validação: ISS, PIS e COFINS somados têm de ficar abaixo de 100%.

### Cadastrar município novo

1. Confirme que a convenção do município já está no cadastro. Se não estiver, peça ao C.O que a inclua antes (ver próxima seção).
2. Peça ao C.O que inclua o município no artefato, com o id `cidade-uf`, o ISS e o VT conferidos na fonte: lei municipal do ISS e tarifa vigente. Se algo ainda não estiver confirmado, o município leva um texto em `alertas`.
3. Sincronize o artefato (veja [docs/SINCRONIZAR-ARTEFATO.md](docs/SINCRONIZAR-ARTEFATO.md)) e valide a cópia local com `node scripts/validate-data.mjs cadastro-local` até dar zero erros.
4. Copie os quatro arquivos para o servidor, como descrito em [portal/deploy/README.md](portal/deploy/README.md) (seção "Cadastro real do Gerador"). Não é preciso fazer deploy.
5. Abra `/propostas/` no servidor, escolha o município e confira o cálculo de um posto.

### Atualizar CCT do ano

- Peça ao C.O uma convenção nova com id novo (por exemplo `limpeza-sp-2027`). **Não sobrescreva a antiga**: o histórico guarda o registro da convenção usada em cada proposta. A convenção antiga pode ficar; só pode sair quando nenhum município apontar para ela, senão o validador acusa o `cct` inexistente.
- Os municípios que usam a convenção passam a apontar para o id novo no campo `cct`. Revise os `alertas` de cada um: retire os resolvidos e acrescente os que a convenção nova exige conferir.
- `vigencia_fim` é a data do último dia de vigência. Quando ela passa, o validador mostra um aviso, e a página mostra o alerta "A convenção cadastrada venceu em ..." e pede confirmação do vendedor, até o município apontar para a convenção nova. Se o campo estiver ausente, a página não consegue avisar o vencimento.
- Depois, siga os passos 3 a 5 de "Cadastrar município novo".

### Textos que vêm do cadastro

- A ajuda da seção 3 (materiais e equipamentos) é montada a partir de `res`, `amort` e `manut` do `config.json`. Mudou o cadastro, o texto acompanha; não há texto fixo para atualizar.

---

## Trocar o modelo da proposta

Os modelos ficam em `assets/`: `modelo-proposta.docx` e `modelo-proposta.pdf`. Trocar o modelo é mudança de modelo, então a versão é **major**.

O código procura trechos exatos nos arquivos. Se mudar um deles sem atualizar `js/app.js`, a troca falha em silêncio: o texto simplesmente não é substituído.

### Modelo DOCX

- **`Cliente: {{CLIENTE}}`** (capa): o código troca essa frase pelo nome do cliente. O marcador aparece duas vezes no modelo, e o código troca as duas. Ele tem de ser o último texto do seu parágrafo, e logo abaixo deve haver um parágrafo vazio: é nele que o código escreve `A/C:` quando o campo "Aos cuidados de" está preenchido.
- **`{{DATA_EXTENSO}}`** (assinatura): vira a data por extenso, por exemplo `3 de novembro de 2026.`
- **A primeira tabela do documento** é substituída inteira pela tabela de preços. O conteúdo de exemplo dela (com o marcador `{{FUNCAO_EXEMPLO}}`) é descartado, então não precisa ser preenchido.
- **Frases que o código procura** para ajustar o texto conforme a proposta tenha ou não materiais e encarregada. Se você mudar uma delas no modelo, atualize `js/app.js` junto:
  - `A presente proposta contempla exclusivamente` (início do parágrafo de observações: o código troca o texto a partir dessa frase, por isso mantenha a frase inteira num único trecho de texto, sem formatação no meio);
  - `Equipamentos profissionais` (vira `Procedimentos padronizados` quando não há materiais);
  - `Enceradeiras, lavadora de alta pressão e aspiradores industriais inclusos.` (vira `Rotinas de limpeza padronizadas, com checklists diários.` quando não há materiais);
  - `Encarregada dedicada, checklists e acompanhamento da gestão Neoguard.` (vira `Supervisão periódica e acompanhamento da gestão Neoguard.` quando não há encarregada).

### Modelo PDF

O PDF tem **12 páginas**, nesta ordem:

| Página | Conteúdo | Como o código usa |
|---|---|---|
| 1 | Capa | Escreve o cliente e o A/C |
| 2 | Institucional | Copiada sem alteração |
| 3 | Página da tabela de preços | Desenhada pelo código sobre a página do modelo |
| 4 | Em branco | Recebe a continuação da tabela quando ela não cabe na página 3 |
| 5 a 8 | Quatro variações da página "Limpeza e Conservação" | Escolhe uma delas: 5 = sem materiais e sem encarregada; 6 = sem materiais, com encarregada; 7 = com materiais, sem encarregada; 8 = com materiais e com encarregada |
| 9 e 10 | Par final, sem materiais | Usado quando não há materiais. A data vai na página 10. |
| 11 e 12 | Par final, com materiais | Usado quando há materiais. A data vai na página 12. |

Outros pontos do PDF:

- Cliente, A/C, tabela e data são escritos em **posições fixas** (coordenadas em `buildPdf`, `js/app.js`). Se o layout mudar, ajuste essas coordenadas.
- O texto escrito no PDF usa a fonte Helvetica. Caracteres fora dela, como emojis, são removidos. Use texto simples nos cadastros.
- `tests/unit/modelos.test.mjs` confere a quantidade de páginas e a ordem. Rode `npm test` depois de trocar o modelo.

### Passo a passo para trocar o modelo

1. Crie a branch `feat/novo-modelo-proposta` (ou o nome que combinar).
2. Substitua o arquivo em `assets/`, mantendo o mesmo nome.
3. Confira os marcadores e a ordem das páginas com a lista acima.
4. Rode `npm test` e `npm run test:e2e`.
5. Rode `npm run start:teste`, gere uma proposta de teste, baixe o PDF e o DOCX e abra os dois para conferir o layout.
6. Abra o PR, faça o merge e publique uma release **major**.

---

## Portal

O Portal (pasta `portal/`) roda em Docker no servidor `172.16.100.35`: a API (backend), a tela (frontend) e o Nginx que serve tudo. O contrato da Fase 1 está em [docs/portal/ESPEC-FASE1.md](docs/portal/ESPEC-FASE1.md).

### Checks obrigatórios

Os cinco checks precisam estar verdes para o merge:

| Check | O que roda |
|---|---|
| Validação e testes unitários | validação de `data/` e testes unitários do Gerador |
| Testes E2E | testes do Gerador no navegador |
| Portal — backend | `pytest` do backend |
| Portal — frontend | testes e build do frontend |
| Portal — imagens Docker | build das duas imagens e teste de fumaça da pilha |

Os checks do Portal rodam em todo PR, sem filtro de caminho, para nenhum check obrigatório ficar pendente.

### Fluxo do Portal

```
branch portal/<assunto> → Pull Request → 5 checks verdes → merge na main (não publica) → Release vX.Y.Z (atualiza o servidor em até 5 min)
```

Publique a release como na seção 6. O servidor acompanha as releases pelo seguidor (`portal/deploy/seguir-release.sh`, com timer). Comandos e o que fazer se algo falhar estão em [portal/deploy/README.md](portal/deploy/README.md).

### Testar antes do PR

```
cd portal/backend
python -m pytest                          # Python 3.12+; antes: pip install -r requirements-dev.txt

cd portal/frontend
npm test -- --run                         # antes: npm ci
npm run build

bash portal/deploy/smoke.sh               # pilha em Docker (precisa de Docker com Compose v2)
```

Antes de qualquer PR, rode também `npm test`, `npm run test:e2e` e `npm run validate` na raiz (seção 2).

### Regras do Portal

- Campo, status, trava ou rota novos: atualize `docs/portal/ESPEC-FASE1.md` no mesmo PR, junto com os testes.
- Mudança no modelo do banco: crie uma migração (`alembic revision --autogenerate -m "..."`, veja [portal/backend/README.md](portal/backend/README.md)). Um teste confere que a migração e os modelos batem.
- Variável de ambiente nova: atualize o `.env.example` da parte e o README correspondente.
- Nunca commite `.env`, senhas, tokens ou o cadastro real. O SMTP fica só no `.env` do servidor (`/opt/portal-neoguard/.env`).

### Servidor

- Rollback: `deploy.sh --ref <tag>`. Cuidado com o banco: o rollback do código não desfaz migrações (veja [portal/deploy/README.md](portal/deploy/README.md)).
- Nunca derrube a porta 8090 antes de o Alan dizer que o projeto terminou.
- A VM também roda o Access-Control. Nos comandos Docker, use sempre `-p portal-neoguard` e `-f portal/deploy/docker-compose.yml`. Não use `docker system prune` nem `docker compose down -v`.
