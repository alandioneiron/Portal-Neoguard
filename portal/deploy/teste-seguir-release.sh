#!/usr/bin/env bash
# Portal Neoguard — teste do seguir-release.sh. Não usa Docker nem a internet e não toca em
# /opt/portal-neoguard: monta um "servidor" de mentira numa pasta temporária (repositório git com
# origin local, deploy.sh falso e uma API de Releases falsa em 127.0.0.1) e confere o que o script faz.
#
#   bash portal/deploy/teste-seguir-release.sh
#
# Precisa de Linux com bash, git, curl, python3 e flock (o runner do GitHub tem tudo). No Windows,
# rode dentro de um contêiner:
#   docker run --rm -v "$PWD/portal/deploy:/deploy:ro" node:20 bash /deploy/teste-seguir-release.sh
set -euo pipefail

AQUI="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="${AQUI}/seguir-release.sh"
PY="$(command -v python3 || command -v python)"

RAIZ="$(mktemp -d)"
BASE="${RAIZ}/portal"          # faz o papel de /opt/portal-neoguard
API="${RAIZ}/api"              # corpo e status que a API falsa devolve
mkdir -p "$BASE" "$API"

PID_API=""
limpar() { [ -n "$PID_API" ] && kill "$PID_API" 2>/dev/null || true; rm -rf "$RAIZ"; }
trap limpar EXIT

export GIT_AUTHOR_NAME=teste GIT_AUTHOR_EMAIL=teste@example.com
export GIT_COMMITTER_NAME=teste GIT_COMMITTER_EMAIL=teste@example.com
export GIT_CONFIG_GLOBAL=/dev/null GIT_TERMINAL_PROMPT=0

# ---- API falsa --------------------------------------------------------------------------------
# Devolve o conteúdo de api/corpo.json com o status de api/status (200, 404, 500...). Status 0 =
# demora 30 s para responder (teste de timeout).
cat > "${RAIZ}/api.py" <<'PY'
import http.server, sys, time
pasta = sys.argv[1]
class H(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        status = int(open(pasta + "/status").read().strip() or "200")
        if status == 0:
            time.sleep(30); status = 200
        corpo = open(pasta + "/corpo.json", "rb").read() if status == 200 else b'{"message":"Not Found"}'
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(corpo)))
        self.end_headers()
        self.wfile.write(corpo)
    def log_message(self, *a):
        pass
s = http.server.ThreadingHTTPServer(("127.0.0.1", 0), H)
open(pasta + "/porta", "w").write(str(s.server_port))
s.serve_forever()
PY
"$PY" "${RAIZ}/api.py" "$API" &
PID_API=$!
for _ in $(seq 1 100); do [ -s "${API}/porta" ] && break; sleep 0.1; done
[ -s "${API}/porta" ] || { echo "ERRO: a API falsa não subiu em 10 s." >&2; exit 1; }
URL="http://127.0.0.1:$(cat "${API}/porta")/repos/alandioneiron/Portal-Neoguard/releases/latest"

api() { # api <status> [tag]  — define o que a API devolve
  printf '%s' "$1" > "${API}/status"
  if [ -n "${2-}" ]; then
    printf '{\n  "url": "https://api.github.com/x",\n  "id": 1,\n  "author": {\n    "login": "alandioneiron"\n  },\n  "tag_name": "%s",\n  "name": "Versão",\n  "draft": false,\n  "prerelease": false,\n  "assets": []\n}\n' "$2" > "${API}/corpo.json"
  fi
}

# ---- repositório de mentira -------------------------------------------------------------------
ORIGEM="${RAIZ}/origem.git"
SEMENTE="${RAIZ}/semente"
git init -q --bare -b main "$ORIGEM"
git init -q -b main "$SEMENTE"
git -C "$SEMENTE" remote add origin "$ORIGEM"

commit() { git -C "$SEMENTE" add -A && git -C "$SEMENTE" commit -q -m "$1"; }

# v0.1.0: Release de antes do Portal (sem portal/deploy)
echo antigo > "${SEMENTE}/LEIAME"; commit "antes do portal"; git -C "$SEMENTE" tag v0.1.0

# v1.0.0: já com a pilha. O deploy.sh falso registra os argumentos, o commit onde o repositório
# estava e se a trava (fd 9) vazou para ele.
mkdir -p "${SEMENTE}/portal/deploy"
echo "services: {}" > "${SEMENTE}/portal/deploy/docker-compose.yml"
cat > "${SEMENTE}/portal/deploy/deploy.sh" <<'FAKE'
#!/usr/bin/env bash
raiz="$(cd "$(dirname "$0")/../.." && pwd)"
fd9=fechado; [ -e "/proc/$$/fd/9" ] && fd9=ABERTO
echo "$* | HEAD=$(git -C "$raiz" rev-parse HEAD) | fd9=${fd9}" >> "${PORTAL_BASE}/chamadas-deploy.txt"
echo "deploy falso rodou: $*"
exit "${FAKE_DEPLOY_EXIT:-0}"
FAKE
commit "pilha do portal"; git -C "$SEMENTE" tag v1.0.0
git -C "$SEMENTE" push -q origin main --tags

# O "servidor" começa na main, na v1.0.0 (como a instalação manual de hoje).
git clone -q "$ORIGEM" "${BASE}/repo"

# Tudo abaixo chega depois do clone: o script precisa buscar as tags novas sozinho.
echo 1 > "${SEMENTE}/mudanca"; commit "v1.1.0"; git -C "$SEMENTE" tag v1.1.0
echo 2 > "${SEMENTE}/mudanca"; commit "v1.2.0"; git -C "$SEMENTE" tag v1.2.0
git -C "$SEMENTE" push -q origin main --tags
git -C "$SEMENTE" switch -q -c outro
echo 3 > "${SEMENTE}/mudanca"; commit "fora da main"; git -C "$SEMENTE" tag v9.0.0
git -C "$SEMENTE" push -q origin outro v9.0.0
git -C "$SEMENTE" switch -q main

SHA_V110="$(git -C "$SEMENTE" rev-parse v1.1.0)"
SHA_V120="$(git -C "$SEMENTE" rev-parse v1.2.0)"

# ---- utilitários de teste ---------------------------------------------------------------------
total=0; falhas=0; RC=0
CHAMADAS="${BASE}/chamadas-deploy.txt"
LOGF="${BASE}/deploy.log"
VERSAO="${BASE}/versao-implantada"

rodar() { # rodar [VAR=valor ...] — roda o script; saída em saida.txt, código em RC
  RC=0
  env PORTAL_BASE="$BASE" PORTAL_API_URL="$URL" "$@" bash "$SCRIPT" > "${RAIZ}/saida.txt" 2>&1 || RC=$?
}
n_chamadas() { if [ -f "$CHAMADAS" ]; then wc -l < "$CHAMADAS" | tr -d ' '; else echo 0; fi; }
contem()     { grep -qF -- "$2" "$1"; }
nao_contem() { ! grep -qF -- "$2" "$1" 2>/dev/null; }
igual()      { [ "$1" = "$2" ]; }
verifica() { # verifica "descrição" comando...
  local desc="$1"; shift; total=$((total + 1))
  if "$@"; then printf 'ok      %s\n' "$desc"; else printf 'FALHOU  %s\n' "$desc"; falhas=$((falhas + 1)); fi
}
titulo() { printf '\n== %s\n' "$1"; }

# ---- 1. sem Release (API 404) -----------------------------------------------------------------
titulo "repositório sem Release (a API responde 404)"
api 404
rodar
verifica "sai com 0"                                 igual "$RC" 0
verifica "não chamou o deploy"                       igual "$(n_chamadas)" 0
verifica "registrou 'Nenhuma Release' no deploy.log" contem "$LOGF" "Nenhuma Release publicada"
rodar
verifica "segunda rodada continua com 0"             igual "$RC" 0
verifica "a mesma linha não se repete no deploy.log" igual "$(grep -cF 'Nenhuma Release' "$LOGF")" 1
verifica "mas o journal (saída) ganha a linha"       contem "${RAIZ}/saida.txt" "Nenhuma Release"

# ---- 2. API com problema ----------------------------------------------------------------------
titulo "API com erro 500, fora do ar, lenta ou com resposta estranha"
api 500
rodar
verifica "HTTP 500: sai com 0"                       igual "$RC" 0
verifica "HTTP 500: registrou o aviso"               contem "$LOGF" "HTTP 500"
rodar PORTAL_API_URL="http://127.0.0.1:1/x"
verifica "API fora do ar: sai com 0"                 igual "$RC" 0
verifica "API fora do ar: registrou o aviso"         contem "$LOGF" "não consegui consultar a API"
api 0
rodar PORTAL_API_TIMEOUT=2
verifica "API lenta: sai com 0 (timeout)"            igual "$RC" 0
verifica "API lenta: curl código 28"                 contem "$LOGF" "curl código 28"
for ruim in "latest" "v1.2" "1.2.3" "v1.0.0-rc1" 'v1.0.0; touch /tmp/PWNED-seguir-release'; do
  api 200 "$ruim"
  rodar
  verifica "tag '${ruim}': sai com 0 e ignora"       igual "$RC" 0
done
verifica "nada foi executado a partir da tag"        test ! -e /tmp/PWNED-seguir-release
printf '{"mensagem":"sem tag"}' > "${API}/corpo.json"; api 200
rodar
verifica "JSON sem tag_name: sai com 0"              igual "$RC" 0
verifica "nenhuma dessas rodadas chamou o deploy"    igual "$(n_chamadas)" 0
verifica "nenhuma gravou versao-implantada"          test ! -e "$VERSAO"

# ---- 3. tag igual à implantada ----------------------------------------------------------------
titulo "tag igual à implantada"
echo v1.0.0 > "$VERSAO"
api 200 v1.0.0
rodar
verifica "sai com 0"                                 igual "$RC" 0
verifica "não chamou o deploy"                       igual "$(n_chamadas)" 0
verifica "registrou 'Em dia'"                        contem "$LOGF" "Em dia: a Release v1.0.0"
verifica "versao-implantada continua v1.0.0"         igual "$(cat "$VERSAO")" v1.0.0

# ---- 4. tag nova (resposta lida de um arquivo file://) ----------------------------------------
titulo "tag nova (API simulada por file://)"
printf '{"tag_name":"v1.1.0","prerelease":false}' > "${RAIZ}/latest.json"   # JSON numa linha só
rodar PORTAL_API_URL="file://${RAIZ}/latest.json"
verifica "sai com 0"                                 igual "$RC" 0
verifica "chamou o deploy uma vez"                   igual "$(n_chamadas)" 1
verifica "deploy.sh recebeu --ref v1.1.0"            contem "$CHAMADAS" "--ref v1.1.0 "
verifica "o repositório já estava na v1.1.0"         contem "$CHAMADAS" "HEAD=${SHA_V110}"
verifica "a trava não vazou para o deploy.sh"        contem "$CHAMADAS" "fd9=fechado"
verifica "gravou a versão implantada"                igual "$(cat "$VERSAO")" v1.1.0
verifica "registrou 'Deploy concluído'"              contem "$LOGF" "Deploy concluído: v1.1.0"
verifica "a saída do deploy foi para o deploy.log"   contem "$LOGF" "deploy falso rodou: --ref v1.1.0"
verifica "a data aparece no log"                     grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9:]{8}[+-][0-9]{4} \[seguir-release\]' "$LOGF"
rodar PORTAL_API_URL="file://${RAIZ}/latest.json"
verifica "segunda rodada: não repete o deploy"       igual "$(n_chamadas)" 1
verifica "segunda rodada: sai com 0"                 igual "$RC" 0

# ---- 5. primeira implantação (sem arquivo de versão) ------------------------------------------
titulo "sem versao-implantada (primeira vez)"
rm -f "$VERSAO"
api 200 v1.1.0
rodar
verifica "implanta a tag"                            igual "$(n_chamadas)" 2
verifica "grava a versão"                            igual "$(cat "$VERSAO")" v1.1.0

# ---- 6. deploy que falha ----------------------------------------------------------------------
titulo "deploy.sh falha"
api 200 v1.2.0
rodar FAKE_DEPLOY_EXIT=1
verifica "sai com 1 (o serviço aparece como falho)"  igual "$RC" 1
verifica "registrou o erro"                          contem "$LOGF" "ERRO: o deploy de v1.2.0 falhou"
verifica "não gravou a versão nova"                  igual "$(cat "$VERSAO")" v1.1.0
rodar
verifica "próxima rodada tenta de novo e conclui"    igual "$RC" 0
verifica "agora grava v1.2.0"                        igual "$(cat "$VERSAO")" v1.2.0
verifica "o repositório estava na v1.2.0"            contem "$CHAMADAS" "HEAD=${SHA_V120}"

# ---- 7. tags que não podem ser implantadas ----------------------------------------------------
titulo "tag fora da main, anterior ao Portal ou inexistente"
chamadas_antes="$(n_chamadas)"
api 200 v9.0.0
rodar
verifica "fora da main: sai com 0"                   igual "$RC" 0
verifica "fora da main: avisa e ignora"              contem "$LOGF" "não está em origin/main"
api 200 v0.1.0
rodar
verifica "anterior ao Portal: sai com 0"             igual "$RC" 0
verifica "anterior ao Portal: avisa e ignora"        contem "$LOGF" "não contém portal/deploy/docker-compose.yml"
api 200 v7.7.7
rodar
verifica "tag inexistente: sai com 0"                igual "$RC" 0
verifica "tag inexistente: avisa"                    contem "$LOGF" "não existe no repositório"
verifica "nenhuma delas chamou o deploy"             igual "$(n_chamadas)" "$chamadas_antes"
verifica "a versão implantada não mudou"             igual "$(cat "$VERSAO")" v1.2.0

# ---- 8. travas (flock) ------------------------------------------------------------------------
titulo "duas execuções ao mesmo tempo"
if command -v flock > /dev/null; then
  api 200 v1.1.0       # diferente da implantada (v1.2.0): sem trava, o script tentaria implantar
  ( exec 9> "${BASE}/.seguir-release.lock"; flock 9; sleep 4 ) &
  PID_TRAVA=$!
  sleep 1
  chamadas_antes="$(n_chamadas)"
  rodar
  verifica "com outra execução ativa: sai com 0"     igual "$RC" 0
  verifica "avisa que há outra execução"             contem "${RAIZ}/saida.txt" "Outra execução em andamento"
  verifica "e não implanta nada"                     igual "$(n_chamadas)" "$chamadas_antes"
  wait "$PID_TRAVA"
else
  echo "pulado: este sistema não tem flock"
fi

echo
if [ "$falhas" -eq 0 ]; then
  echo "Tudo certo: ${total} verificações passaram."
else
  echo "FALHOU: ${falhas} de ${total} verificações." >&2
  echo "--- deploy.log ---" >&2; cat "$LOGF" >&2 || true
  exit 1
fi
