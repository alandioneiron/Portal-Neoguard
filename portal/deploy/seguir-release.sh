#!/usr/bin/env bash
# Portal Neoguard — implanta sozinho a última Release publicada no GitHub (deploy por "pull").
#
# O servidor fica na rede interna e o GitHub não consegue entrar nele. Por isso é o servidor que
# pergunta, a cada 5 minutos (portal-neoguard-release.timer), qual é a última Release. Se a tag
# for diferente da que está implantada, ele roda "deploy.sh --ref <tag>".
#
#   bash /opt/portal-neoguard/repo/portal/deploy/seguir-release.sh     # roda uma vez, agora
#
# Garantias:
#   - consulta só leitura, sem token (o repositório é público);
#   - nunca roda duas vezes ao mesmo tempo (flock);
#   - só implanta tag vX.Y.Z cujo commit esteja na main e que contenha portal/deploy/;
#   - API fora do ar, sem Release ainda ou resposta estranha: só registra e sai com 0;
#   - só mexe no projeto Docker "portal-neoguard" (quem faz isso é o deploy.sh).
#
# Arquivos em /opt/portal-neoguard (PORTAL_BASE):
#   versao-implantada   última tag que este script implantou com sucesso (uma linha: vX.Y.Z)
#   deploy.log          registro com data (eventos + a saída do deploy.sh); gira em 5 MB
#   .seguir-release.*   trava (lock) e último estado registrado (evita repetir a mesma linha)
#
# Variáveis (todas opcionais; existem para teste):
#   PORTAL_BASE         pasta do Portal no servidor            (padrão /opt/portal-neoguard)
#   PORTAL_API_URL      endereço da "última release"           (padrão: API do GitHub deste repositório)
#   PORTAL_BRANCH       ramo que precisa conter a tag          (padrão main)
#   PORTAL_API_TIMEOUT  segundos máximos da consulta à API     (padrão 30)
#
# Rollback e instalação do timer: portal/deploy/README.md.
set -euo pipefail

# O systemd e o cron rodam com PATH mínimo.
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${PATH:-}"
# Se o git um dia pedir senha, falha em vez de ficar esperando um terminal que não existe.
export GIT_TERMINAL_PROMPT=0

BASE="${PORTAL_BASE:-/opt/portal-neoguard}"
REPO="${BASE}/repo"
BRANCH="${PORTAL_BRANCH:-main}"
API_URL="${PORTAL_API_URL:-https://api.github.com/repos/alandioneiron/Portal-Neoguard/releases/latest}"
API_TIMEOUT="${PORTAL_API_TIMEOUT:-30}"

ARQ_VERSAO="${BASE}/versao-implantada"
ARQ_ESTADO="${BASE}/.seguir-release.estado"
LOCK="${BASE}/.seguir-release.lock"
LOG="${BASE}/deploy.log"
LOG_MAX_BYTES=$((5 * 1024 * 1024))
DEPLOY_SH="${REPO}/portal/deploy/deploy.sh"

TMP=""
TAG=""

# ---- registro ---------------------------------------------------------------------------------
# A saída padrão vai para o journal (journalctl -u portal-neoguard-release); o deploy.log recebe
# só o que importa, com data.
linha() { printf '%s [seguir-release] %s\n' "$(date '+%Y-%m-%d %H:%M:%S%z')" "$*"; }

# Evento: vai para o journal e para o deploy.log.
log() {
  local l
  l="$(linha "$*")"
  printf '%s\n' "$l"
  printf '%s\n' "$l" >> "$LOG" 2>/dev/null || true
}

# Situação repetitiva (sem Release, API fora do ar, "já está em dia"): o journal recebe sempre,
# mas o deploy.log só ganha uma linha quando a situação MUDA. Assim o log não enche de linhas
# iguais a cada 5 minutos.
estado() {
  local msg="$*" anterior=""
  if [ -f "$ARQ_ESTADO" ]; then anterior="$(cat "$ARQ_ESTADO" 2>/dev/null || true)"; fi
  if [ "$msg" = "$anterior" ]; then
    linha "$msg"
  else
    log "$msg"
    printf '%s\n' "$msg" > "$ARQ_ESTADO" 2>/dev/null || true
  fi
}

msg_em_dia() { printf 'Em dia: a Release %s está implantada.' "$TAG"; }

# Texto vindo da internet só entra no log depois de limpo.
limpo() { local s="${1//[^A-Za-z0-9._-]/?}"; printf '%.40s' "$s"; }

rotacionar_log() {
  local tamanho=0
  if [ -f "$LOG" ]; then tamanho="$(stat -c %s "$LOG" 2>/dev/null || echo 0)"; fi
  if [ "$tamanho" -gt "$LOG_MAX_BYTES" ]; then mv -f "$LOG" "${LOG}.1"; fi
}

# ---- 1. descobrir a última Release ------------------------------------------------------------
# Preenche TAG. Retorna 1 (já registrando o motivo) quando não há o que implantar.
obter_ultima_tag() {
  local corpo="${TMP}/api.json" erro="${TMP}/curl.err" codigo rc=0 bruta

  codigo="$(curl -sS -L --connect-timeout 10 --max-time "$API_TIMEOUT" \
      -H 'Accept: application/vnd.github+json' \
      -H 'User-Agent: portal-neoguard-seguir-release' \
      -o "$corpo" -w '%{http_code}' "$API_URL" 2>"$erro")" || rc=$?

  if [ "$rc" -ne 0 ]; then
    estado "AVISO: não consegui consultar a API de Releases (curl código ${rc}: $(head -c 160 "$erro" | tr -c '[:print:]' ' ')). Tento de novo no próximo ciclo."
    return 1
  fi

  case "$codigo" in
    200|000) ;;  # 000: o curl não tem código HTTP em file:// (só nos testes)
    404)
      estado "Nenhuma Release publicada ainda (a API respondeu 404). Nada a implantar."
      return 1 ;;
    *)
      estado "AVISO: a API de Releases respondeu HTTP ${codigo}. Tento de novo no próximo ciclo."
      return 1 ;;
  esac

  bruta="$(grep -m1 -oE '"tag_name"[[:space:]]*:[[:space:]]*"[^"]*"' "$corpo" | sed -E 's/^.*:[[:space:]]*"(.*)"$/\1/' || true)"
  if ! [[ "$bruta" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    estado "AVISO: a última Release tem tag fora do formato vX.Y.Z ('$(limpo "$bruta")'). Ignorada."
    return 1
  fi
  TAG="$bruta"
}

# ---- 2. conferir a tag no repositório local e implantar ---------------------------------------
implantar() {
  local atual="$1" ref="refs/tags/${TAG}"

  log "Release nova: ${TAG} (implantada: ${atual:-nenhuma}). Atualizando o repositório local."
  if ! timeout 300 git -C "$REPO" fetch --tags --prune origin >> "$LOG" 2>&1; then
    estado "AVISO: git fetch falhou (veja ${LOG}). Tento de novo no próximo ciclo."
    return 0
  fi

  if ! git -C "$REPO" rev-parse -q --verify "${ref}^{commit}" > /dev/null; then
    estado "AVISO: a tag ${TAG} não existe no repositório depois do fetch. Tento de novo no próximo ciclo."
    return 0
  fi

  # Produção só com código que já passou por PR (mesma regra do release.yml).
  if ! git -C "$REPO" merge-base --is-ancestor "${ref}^{commit}" "refs/remotes/origin/${BRANCH}"; then
    estado "AVISO: a tag ${TAG} aponta para um commit que não está em origin/${BRANCH}. Ignorada."
    return 0
  fi

  # Tags antigas (de antes do Portal) não têm a pilha Docker: implantá-las derrubaria o Portal.
  if ! git -C "$REPO" cat-file -e "${ref}:portal/deploy/docker-compose.yml" 2> /dev/null; then
    estado "AVISO: a tag ${TAG} não contém portal/deploy/docker-compose.yml (Release anterior ao Portal?). Ignorada."
    return 0
  fi

  # O deploy.sh (e este script) passam a ser os da própria tag: o checkout acontece aqui, antes de
  # chamar o deploy.sh. O deploy.sh repete o checkout, sem efeito. Este script inteiro vive dentro
  # de funções e termina em "exit", então o bash não relê o arquivo depois da troca.
  if ! git -C "$REPO" checkout -q --detach "$ref" >> "$LOG" 2>&1; then
    log "ERRO: git checkout da tag ${TAG} falhou (alteração local no repositório?). Veja ${LOG}."
    return 1
  fi

  log "Implantando ${TAG} (commit $(git -C "$REPO" rev-parse --short HEAD)). Saída completa a seguir."
  # 9>&- fecha a trava nos processos filhos: o lock acaba junto com este script.
  if bash "$DEPLOY_SH" --ref "$TAG" >> "$LOG" 2>&1 9>&-; then
    if ! { printf '%s\n' "$TAG" > "${ARQ_VERSAO}.tmp" && mv -f "${ARQ_VERSAO}.tmp" "$ARQ_VERSAO"; }; then
      log "AVISO: o deploy de ${TAG} deu certo, mas não consegui gravar ${ARQ_VERSAO}; o próximo ciclo vai repetir o deploy."
    fi
    printf '%s\n' "$(msg_em_dia)" > "$ARQ_ESTADO" 2> /dev/null || true
    log "Deploy concluído: ${TAG} (commit $(git -C "$REPO" rev-parse --short HEAD))."
  else
    log "ERRO: o deploy de ${TAG} falhou (código $?). A versão implantada continua registrada como ${atual:-nenhuma}; tento de novo no próximo ciclo. Fim do log:"
    tail -n 20 "$LOG" || true
    return 1
  fi
}

main() {
  [ -d "$BASE" ] || { echo "ERRO: ${BASE} não existe (PORTAL_BASE)." >&2; return 1; }

  # Uma execução por vez (timer + execução manual).
  exec 9> "$LOCK"
  if ! flock -n 9; then
    linha "Outra execução em andamento; saindo."
    return 0
  fi

  TMP="$(mktemp -d)"
  trap 'rm -rf "$TMP"' EXIT
  rotacionar_log

  obter_ultima_tag || return 0

  local atual=""
  if [ -f "$ARQ_VERSAO" ]; then atual="$(tr -d '[:space:]' < "$ARQ_VERSAO")"; fi

  if [ "$TAG" = "$atual" ]; then
    estado "$(msg_em_dia)"
    return 0
  fi

  implantar "$atual"
}

main
exit $?
