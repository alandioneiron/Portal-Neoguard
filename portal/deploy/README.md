# Portal Neoguard — deploy

Tudo para colocar o Portal (Ficha de Implantação + Gerador de Propostas) no ar no servidor `172.16.100.35`, com Docker Compose. Contrato técnico: [`docs/portal/ESPEC-FASE1.md`](../../docs/portal/ESPEC-FASE1.md).

## O que sobe

| Serviço | Imagem | O que faz |
|---|---|---|
| `db` | `postgres:16-alpine` | Banco das fichas. Volume nomeado `portal-neoguard_pgdata`. Sem porta publicada. |
| `api` | `Dockerfile.api` (Python 3.12) | FastAPI. Ao subir roda `alembic upgrade head`. Sem porta publicada. |
| `web` | `Dockerfile.web` (Nginx 1.27) | SPA do portal em `/`, API em `/api/`, Gerador em `/propostas/`. **Única porta publicada: `8090`.** |

Roteamento do Nginx (`nginx.conf`):

| Caminho | Destino |
|---|---|
| `/` | SPA (`index.html` sem cache; `assets/` com hash e cache de 1 ano) |
| `/api/` | `api:8000`, repassando o caminho completo |
| `/propostas/` | Gerador estático (sempre revalida o cache) |
| `/propostas/data/` | Cadastro real, vindo do volume do servidor, `Cache-Control: no-store`. Só `config.json`, `ccts.json`, `municipios.json` e `site.json` são servidos. |

### Isolamento do Access-Control

A VM também roda o Access-Control (portas 3001 e 3443), que aciona hardware real. O Portal não pode encostar nele:

- projeto Compose `portal-neoguard` (o `name:` do arquivo já fixa isso), rede `portal-neoguard_portal` e volume `portal-neoguard_pgdata` próprios;
- **sempre** `-p portal-neoguard` e `-f portal/deploy/docker-compose.yml` nos comandos (o `deploy.sh` já faz);
- sem `container_name` fixo, sem `docker system prune`, sem `docker compose down` fora do projeto;
- única porta publicada: `8090` (a `3001` e a `3443` ficam como estão).

## Publicar uma versão em produção

Merge na `main` **não** publica. Produção só muda quando uma **Release `vX.Y.Z`** é publicada no GitHub. O servidor fica na rede interna e o GitHub não consegue entrar nele, então o deploy é **por *pull***: o servidor consulta as Releases a cada 5 minutos e implanta a tag nova sozinho (`seguir-release.sh`, disparado por um timer systemd; veja *Instalar o deploy automático*, mais abaixo).

1. Confirme que a `main` tem o que você quer publicar e que o CI dela está verde.
2. No GitHub: **Releases → Draft a new release** (`https://github.com/alandioneiron/Portal-Neoguard/releases/new`).
3. Em **Choose a tag**, digite a tag nova no formato `vX.Y.Z` (exemplo: `v1.0.0`) e escolha **Create new tag on publish**. Em **Target**, deixe `main`.
4. Preencha o título e as notas (**Generate release notes** monta a lista dos PRs). Deixe **Set as a pre-release** **desmarcado**: pré-lançamento é ignorado, tanto pelo GitHub Actions quanto pelo servidor.
5. Clique em **Publish release**.
6. O workflow **Release → Produção** confere a tag e roda a bateria de testes inteira. Ele **não** acessa o servidor.
7. **Em até 5 minutos** o servidor vê a Release, busca a tag e roda `deploy.sh --ref vX.Y.Z`.

O servidor só implanta uma tag que (a) siga `vX.Y.Z`, (b) aponte para um commit que esteja na `main` e (c) contenha `portal/deploy/docker-compose.yml`. O resto ele ignora e registra o motivo. Ele **não espera** o workflow da Release terminar: o commit da tag já passou nos checks do PR para entrar na `main`. Se o workflow falhar mesmo assim, trate como incidente e faça o rollback (seção Rollback).

### Acompanhar a implantação

No servidor:

```bash
tail -f /opt/portal-neoguard/deploy.log              # eventos com data + a saída completa do deploy.sh
cat /opt/portal-neoguard/versao-implantada           # última tag que o timer implantou
curl -fsS http://localhost:8090/api/saude            # o campo "versao" é o commit completo em produção
git -C /opt/portal-neoguard/repo rev-parse vX.Y.Z    # deve ser igual ao "versao" acima
systemctl list-timers portal-neoguard-release.timer  # quando é o próximo disparo
journalctl -u portal-neoguard-release.service -n 50 --no-pager
```

O fim de uma implantação boa no `deploy.log`:

```
2026-10-09 14:03:12-0300 [seguir-release] Release nova: v1.0.0 (implantada: nenhuma). Atualizando o repositório local.
2026-10-09 14:03:15-0300 [seguir-release] Implantando v1.0.0 (commit 1a2b3c4). Saída completa a seguir.
... saída do deploy.sh ...
2026-10-09 14:05:40-0300 [seguir-release] Deploy concluído: v1.0.0 (commit 1a2b3c4).
```

O `deploy.log` só recebe uma linha quando a situação **muda** (não uma a cada 5 minutos) e gira sozinho ao passar de 5 MB (`deploy.log.1`). O `journalctl` mostra todas as execuções.

| Mensagem no log | O que significa |
|---|---|
| `Nenhuma Release publicada ainda (a API respondeu 404)` | Normal antes da primeira Release. |
| `Em dia: a Release vX.Y.Z está implantada` | Nada a fazer. |
| `AVISO: não consegui consultar a API...` / `respondeu HTTP 403` | GitHub inacessível ou limite de consultas sem token (60 por hora por IP). Tenta de novo no próximo ciclo; nada é derrubado. |
| `AVISO: ... não está em origin/main. Ignorada.` | A Release foi criada a partir de outro ramo. Apague a Release e a tag e publique de novo a partir da `main`. |
| `AVISO: ... não contém portal/deploy/docker-compose.yml` | Tag de antes do Portal. Ignorada de propósito (implantá-la derrubaria o Portal). |
| `ERRO: o deploy de vX.Y.Z falhou` | Veja a saída do `deploy.sh` logo acima no `deploy.log`. A versão registrada não muda e o timer tenta de novo a cada 5 minutos. Se a causa for o código da Release, faça o rollback. |

## Primeira instalação no servidor

Entre na VM por SSH com o usuário que usa o Docker (grupo `docker`).

```bash
# 1. Pastas
sudo mkdir -p /opt/portal-neoguard/{cadastro,backups}
sudo chown -R "$USER":"$USER" /opt/portal-neoguard

# 2. Código
git clone https://github.com/alandioneiron/Portal-Neoguard.git /opt/portal-neoguard/repo

# 3. Configuração (fica FORA do repositório; tem senhas)
cp /opt/portal-neoguard/repo/portal/deploy/.env.example /opt/portal-neoguard/.env
chmod 600 /opt/portal-neoguard/.env
nano /opt/portal-neoguard/.env      # preencha ao menos POSTGRES_PASSWORD (openssl rand -hex 24)

# 4. Cadastro real do Gerador (veja a seção abaixo)
cp /opt/portal-neoguard/repo/portal/deploy/cadastro-vazio/*.json /opt/portal-neoguard/cadastro/   # só para começar

# 5. Subir (só na primeira vez: sobe a main; depois disso as versões entram por Release)
bash /opt/portal-neoguard/repo/portal/deploy/deploy.sh

# 6. Backup diário (02:30). No servidor de produção a linha está no cron do root (sudo crontab -l).
( crontab -l 2>/dev/null; echo '30 2 * * * bash /opt/portal-neoguard/repo/portal/deploy/backup-db.sh >> /opt/portal-neoguard/backups/backup.log 2>&1' ) | crontab -
bash /opt/portal-neoguard/repo/portal/deploy/backup-db.sh   # teste manual: deve criar um .sql.gz em /opt/portal-neoguard/backups
```

Em seguida, ative o deploy automático por Release (seção *Instalar o deploy automático*). Depois abra `http://172.16.100.35:8090` (de outro computador da rede) e confira a versão no topo do Gerador em `/propostas/` (aparece `portal-<commit>`).

### `.env`

Modelo completo e comentado em [`.env.example`](.env.example).

| Variável | Para quê |
|---|---|
| `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB` | Banco. **Só letras e números na senha** (ela entra numa URL). A senha só vale na criação do volume: trocar depois no `.env` não troca no banco. |
| `PORTAL_URL` | Base dos links dos e-mails (`PORTAL_URL/fichas/<id>`). |
| `PORTAL_PORTA` | Porta publicada (padrão `8090`). |
| `CADASTRO_DIR` | Pasta do cadastro real (padrão do exemplo: `/opt/portal-neoguard/cadastro`). |
| `NOTIFICAR_PARA` | Destinatários dos avisos, separados por vírgula. |
| `SMTP_HOST`, `SMTP_PORT`, `SMTP_USUARIO`, `SMTP_SENHA`, `SMTP_REMETENTE`, `SMTP_TLS` | E-mail. Com `SMTP_HOST` vazio o portal funciona, mas não envia e-mail (registra "e-mail não configurado" no log). Depois de preencher: `deploy.sh` de novo (ou `docker compose ... up -d api`). |

### Cadastro real do Gerador

O cadastro (parâmetros Neoguard, CCTs e municípios) **nunca vai para o git nem para a imagem**. Ele vive só no servidor, em `CADASTRO_DIR`, e o Nginx o lê por volume somente leitura:

```bash
# do seu computador, com os 4 arquivos gerados pelo importador do Gerador:
scp config.json ccts.json municipios.json site.json usuario@172.16.100.35:/opt/portal-neoguard/cadastro/
ssh usuario@172.16.100.35 'chmod 644 /opt/portal-neoguard/cadastro/*.json'
```

- Atualizar o cadastro **não exige deploy nem reinício**: o Nginx responde com `no-store`, então a próxima abertura do Gerador já usa os arquivos novos.
- A pasta precisa ser legível pelo Nginx (arquivos `644`, pasta `755`).
- Deixe na pasta só esses 4 arquivos. Qualquer outro nome devolve 404 de propósito.
- Sem os arquivos reais, o Gerador abre, mas avisa "Parâmetros Neoguard ainda não cadastrados" e não calcula nada.

## Instalar o deploy automático (timer systemd)

Uma vez só, no servidor, com um usuário que tenha `sudo`. O timer chama `seguir-release.sh` a cada 5 minutos; as units estão em [`systemd/`](systemd/).

```bash
# 1. Trazer os arquivos novos para o servidor (a main precisa ter este PR mesclado)
cd /opt/portal-neoguard/repo && git switch main && git pull --ff-only
ls portal/deploy/seguir-release.sh portal/deploy/systemd/

# 2. O serviço roda como o DONO do repositório (o mesmo usuário, do grupo docker, que já roda o
#    deploy.sh). Não use root: o git recusa um repositório de outro dono ("dubious ownership").
USUARIO="$(stat -c %U /opt/portal-neoguard/repo)"
echo "O serviço vai rodar como: ${USUARIO}"      # confira; tem de estar no grupo docker: id "$USUARIO"

# 3. Instalar as units (a do serviço recebe o usuário no lugar do marcador User=)
UNITS=/opt/portal-neoguard/repo/portal/deploy/systemd
sed "s/^User=.*/User=${USUARIO}/" "$UNITS/portal-neoguard-release.service" \
  | sudo tee /etc/systemd/system/portal-neoguard-release.service > /dev/null
sudo install -m 0644 "$UNITS/portal-neoguard-release.timer" /etc/systemd/system/portal-neoguard-release.timer

# 4. Ativar
sudo systemctl daemon-reload
sudo systemctl enable --now portal-neoguard-release.timer

# 5. Conferir: o timer aparece com o próximo disparo, e uma execução manual deve terminar sem erro
systemctl list-timers portal-neoguard-release.timer
sudo systemctl start portal-neoguard-release.service
journalctl -u portal-neoguard-release.service -n 20 --no-pager
tail -n 5 /opt/portal-neoguard/deploy.log
```

Sem nenhuma Release ainda, o esperado no passo 5 é `Nenhuma Release publicada ainda (a API respondeu 404)`.

Detalhes que ajudam:

- **Primeira Release.** O arquivo `/opt/portal-neoguard/versao-implantada` não existe no começo, então a primeira Release publicada é implantada. Se você já implantou uma tag à mão e quer que o timer a considere em dia, grave-a: `echo vX.Y.Z > /opt/portal-neoguard/versao-implantada`.
- **Atualizar o próprio script.** As units chamam `repo/portal/deploy/seguir-release.sh`. Depois de cada deploy o repositório do servidor fica na tag implantada, então o script (e o `deploy.sh`) são sempre os da Release em produção. Mudou uma unit (`systemd/`)? Copie de novo e rode `sudo systemctl daemon-reload`; elas não se atualizam sozinhas.
- **Rollback para uma tag muito antiga.** Se a tag não tiver `seguir-release.sh` (anterior à instalação do timer), a pasta `repo` fica sem o script e o timer falha com "No such file". Volte para a `main` (`git -C /opt/portal-neoguard/repo switch main`) para recuperá-lo.
- **Pausar.** `sudo systemctl stop portal-neoguard-release.timer` (volta com `start`). Desinstalar: `sudo systemctl disable --now portal-neoguard-release.timer` e apague as duas units de `/etc/systemd/system`.
- **Segurança.** Quem pode publicar uma Release no GitHub decide o que roda no servidor. Mantenha o repositório com poucos colaboradores com permissão de escrita.

## Dia a dia

Atalho para os comandos abaixo (cole no terminal do servidor):

```bash
alias portal='docker compose -p portal-neoguard -f /opt/portal-neoguard/repo/portal/deploy/docker-compose.yml --env-file /opt/portal-neoguard/.env'
```

### Deploy manual (exceção)

O caminho normal é publicar uma Release (seção *Publicar uma versão em produção*): o timer cuida do resto. À mão, só em emergência e **sempre com `--ref`**:

```bash
bash /opt/portal-neoguard/repo/portal/deploy/deploy.sh --ref v1.2.0     # implanta a tag
```

O script busca as tags, faz o checkout do `--ref` (sem `pull`), reconstrói as imagens com o commit atual (`GIT_SHA`), sobe o que mudou, mostra o status e testa `http://127.0.0.1:8090/api/saude` por até 60 s. Se o teste falhar, mostra os logs da `api` e do `web` e sai com erro. É o mesmo comando que o `seguir-release.sh` roda.

> **Não rode `deploy.sh` sem `--ref` com o timer ativo.** Sem argumento ele faz `git pull` na `main` e implanta o que estiver lá, inclusive o que ainda não virou Release. O timer não corrige isso (a Release mais recente continua igual à registrada em `versao-implantada`). Se aconteceu, volte com `deploy.sh --ref <tag em produção>`.
>
> Um deploy manual de uma tag diferente da Release mais recente também é desfeito pelo timer em até 5 minutos. Para segurar uma versão, veja *Rollback*.

As migrações do banco rodam sozinhas na subida da `api` (`alembic upgrade head`).

### Trocar a senha do e-mail de envio (SMTP)

Depois de trocar a senha de `envio@neoguard.com.br` no cPanel, atualize o Portal (enquanto a tela de configuração do e-mail não existe):

```bash
ssh -t root@172.16.100.35 "bash /opt/portal-neoguard/repo/portal/deploy/trocar-senha-smtp.sh"
```

O script:
1. pede a senha nova duas vezes, sem mostrá-la;
2. testa o login no servidor de e-mail e só continua se a senha for aceita;
3. grava `SMTP_SENHA` no `.env`, com backup `.env.bak-<data>`;
4. recria **só** a `api`, sem derrubar o site.

Sintoma de senha desatualizada: o botão "Enviar por e-mail" mostra "usuário ou senha do SMTP foram recusados pelo servidor" (o servidor responde `535 Incorrect authentication data`).

### Status e logs

```bash
portal ps                              # status e saúde dos 3 serviços
portal logs -f --tail=100 api          # logs da API (idem: web, db)
curl -fsS http://localhost:8090/api/saude
```

Os logs usam o `json-file` com rotação (5 arquivos de 10 MB por serviço).

### Rollback

O timer sempre persegue a **Release mais recente** do GitHub. Por isso o rollback precisa mexer na Release (opções A e B) ou avisar o timer (opção C), senão ele reimplanta a versão ruim em até 5 minutos.

**A. Tirar a Release ruim do ar (a mais simples; o servidor volta sozinho).** No GitHub, em **Releases**, edite a Release ruim, marque **Set as a pre-release** e salve (ou exclua a Release). A "última Release" passa a ser a anterior e, em até 5 minutos, o servidor implanta essa tag. Se a Release ruim trouxe migração do banco, use a opção C: o código troca sozinho aqui, antes de você voltar o banco (veja a atenção abaixo). Antes de confiar, confira a resposta da API:

```bash
curl -s https://api.github.com/repos/alandioneiron/Portal-Neoguard/releases/latest | grep '"tag_name"'   # deve mostrar a tag boa
```

**B. Release de correção (o caminho normal).** Corrija na `main` por PR e publique `vX.Y.(Z+1)`. O servidor implanta sozinho.

**C. Voltar agora, à mão, e segurar o timer.** Útil quando não dá para esperar o ciclo de 5 minutos:

```bash
cd /opt/portal-neoguard/repo && git tag --sort=-creatordate | head      # ache a tag boa
bash /opt/portal-neoguard/repo/portal/deploy/deploy.sh --ref v1.0.0     # a tag BOA
echo v1.1.0 > /opt/portal-neoguard/versao-implantada                    # a Release MAIS RECENTE (a ruim)
```

A segunda linha é o que impede o timer de reimplantar: ele compara a última Release do GitHub (`v1.1.0`) com o arquivo e, sendo iguais, considera tudo em dia. **Grave a tag da Release ruim, não a tag boa**; gravar a boa faria o timer implantar a ruim de novo. Daí em diante o arquivo deixa de dizer o que está rodando (confira em `/api/saude`) e volta a valer na próxima Release publicada (`v1.1.1`), que o timer implanta normalmente. Prefira publicar a correção ou usar a opção A assim que possível, para o servidor e o GitHub ficarem de acordo.

Use tags a partir da instalação do timer (veja *Instalar o deploy automático*).

> **Atenção com o banco.** O rollback do código **não desfaz migrações**. Se a versão que você quer abandonar criou uma migração, volte o banco junto: restaure o último backup (abaixo) ou rode `portal exec api alembic downgrade <revisão>` **antes** de trocar o código. Sem migração nova no meio, o rollback é seguro.

### Backup e restauração

O backup roda sozinho: no servidor de produção ele está no **cron do root**, todo dia às **02:30** (`sudo crontab -l` mostra a linha; o resultado vai para `/opt/portal-neoguard/backups/backup.log`). O deploy automático por Release não mexe nisso.

`backup-db.sh` grava `portal-AAAAMMDD-HHMMSS.sql.gz` em `/opt/portal-neoguard/backups` e apaga os de mais de 14 dias. Copie esses arquivos para fora da VM de vez em quando (o backup na mesma máquina não protege contra perda do disco).

Restaurar (apaga os dados atuais do banco do Portal):

```bash
portal stop web api
gunzip -c /opt/portal-neoguard/backups/portal-AAAAMMDD-HHMMSS.sql.gz \
  | portal exec -T db sh -c 'psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB"'
portal start api web
```

### Parar tudo

```bash
portal down        # para e remove os contêineres do Portal; os dados (volume) ficam
```

**Nunca** use `down -v` no servidor: apaga o banco. Esse comando só é usado no teste local (abaixo).

## Fase 2: fechar a porta 8090

Na Fase 2 entram o login pelo AD (LDAPS), o MFA fora da rede e o HTTPS público. Quando isso entrar, a porta `8090` deixa de ser a porta de entrada:

1. Coloque um proxy HTTPS na frente (Nginx/Traefik do servidor ou do firewall) apontando para o contêiner `web`.
2. Em `docker-compose.yml`, troque `ports: "${PORTAL_PORTA:-8090}:80"` por `expose: ["80"]` (ou `127.0.0.1:${PORTAL_PORTA}:80`, se o proxy rodar na própria VM).
3. Ajuste `PORTAL_URL` no `.env` para o endereço novo e rode `deploy.sh`.
4. Confirme de outro computador que `http://172.16.100.35:8090` não responde mais.

Observação: o Docker publica portas direto no `iptables` e **ignora o `ufw`**. Bloquear a 8090 só no `ufw` não adianta; é preciso tirar o `ports:` do compose (ou filtrar na cadeia `DOCKER-USER`).

## Testar na sua máquina

Precisa de Docker com Compose v2 e `curl`. Da raiz do repositório:

```bash
bash portal/deploy/smoke.sh
```

Sobe a pilha num projeto descartável (`portal-neoguard-teste`, porta `18090`, volumes próprios), testa `/`, `/api/saude` e `/propostas/`, e derruba tudo com `down -v`. O CI roda o mesmo script. Para validar só o compose:

```bash
POSTGRES_PASSWORD=teste docker compose -f portal/deploy/docker-compose.yml --env-file portal/deploy/.env.example config -q
```

Para testar o `seguir-release.sh` (sem Docker e sem internet; monta um servidor de mentira numa pasta temporária, com repositório git, `deploy.sh` falso e API de Releases falsa em `127.0.0.1`):

```bash
bash portal/deploy/teste-seguir-release.sh        # Linux (precisa de bash, git, curl, python3 e flock)
# No Windows, dentro de um contêiner Linux:
docker run --rm -v "$PWD/portal/deploy:/deploy:ro" node:20 bash /deploy/teste-seguir-release.sh
```

Cobre: sem Release (404), API com erro 500 / fora do ar / lenta, tag inválida, tag igual à implantada, tag nova (inclusive lida de `file://`), deploy que falha, tag fora da `main`, tag anterior ao Portal, tag inexistente e duas execuções ao mesmo tempo.

## Arquivos

| Arquivo | Para quê |
|---|---|
| `docker-compose.yml` | Pilha `db` + `api` + `web`. |
| `Dockerfile.api` | API: Python 3.12, usuário sem privilégios, migra e sobe o Uvicorn, healthcheck em `/api/saude`. |
| `Dockerfile.web` | Build do frontend (Node 22) + Nginx com a SPA e o Gerador (sem `data/`); grava `propostas/version.json`. |
| `nginx.conf`, `nginx-seguranca.conf` | Roteamento, cache e cabeçalhos de segurança. |
| `.env.example` | Modelo do `.env` do servidor (o `.env` real nunca vai para o git). |
| `cadastro-vazio/` | Cadastro "em branco" usado quando `CADASTRO_DIR` não está definido. |
| `deploy.sh` | Atualiza e sobe a pilha no servidor. Com `--ref <tag ou sha>` implanta aquela versão (é o que o `seguir-release.sh` roda); sem argumento implanta a `main`. |
| `seguir-release.sh` | Deploy por *pull*: consulta a última Release no GitHub e, se for nova, roda `deploy.sh --ref <tag>`. Escreve em `/opt/portal-neoguard/deploy.log` e `versao-implantada`. |
| `systemd/portal-neoguard-release.service`, `.timer` | Units que rodam o `seguir-release.sh` a cada 5 minutos. Copiar para `/etc/systemd/system` (veja *Instalar o deploy automático*). |
| `teste-seguir-release.sh` | Teste do `seguir-release.sh` com servidor, repositório e API de mentira. |
| `backup-db.sh` | `pg_dump` compactado com retenção de 14 dias (cron do root, 02:30). |
| `smoke.sh` | Teste de fumaça (local e CI). |
| `../../.dockerignore` | Mantém `node_modules`, `.git`, `tests/`, `data/` etc. fora do contexto de build. |
