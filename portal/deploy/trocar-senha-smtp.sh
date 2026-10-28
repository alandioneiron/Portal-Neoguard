#!/usr/bin/env bash
# Troca a senha do SMTP do Portal Neoguard sem mostrá-la na tela.
# Uso (como root no 172.16.100.35):  bash /opt/portal-neoguard/trocar-senha-smtp.sh
# 1) pergunta a senha nova (duas vezes, sem eco); 2) testa o login no servidor de e-mail;
# 3) só se o login der certo, grava em SMTP_SENHA no .env (com backup) e recria SÓ o contêiner
#    da API. O site na porta 8090 continua no ar.
set -euo pipefail
BASE=/opt/portal-neoguard
ENV_FILE="$BASE/.env"
DC=(docker compose -p portal-neoguard -f "$BASE/repo/portal/deploy/docker-compose.yml" --env-file "$ENV_FILE")

usuario="$(grep -E '^SMTP_USUARIO=' "$ENV_FILE" | cut -d= -f2-)"
read -rsp "Nova senha de ${usuario}: " SENHA; echo
read -rsp "Repita a senha: " SENHA2; echo
if [ -z "$SENHA" ] || [ "$SENHA" != "$SENHA2" ]; then
  echo "As senhas não conferem (ou ficaram vazias). Nada foi alterado."; exit 1
fi
export SENHA

echo "Testando o login no servidor de e-mail..."
python3 - "$ENV_FILE" <<'PY'
import os, smtplib, ssl, sys
env = {}
for linha in open(sys.argv[1], encoding="utf8"):
    linha = linha.rstrip("\n")
    if linha and not linha.startswith("#") and "=" in linha:
        k, v = linha.split("=", 1)
        env[k] = v
try:
    with smtplib.SMTP_SSL(env["SMTP_HOST"], int(env["SMTP_PORT"]), context=ssl.create_default_context(), timeout=20) as c:
        c.login(env["SMTP_USUARIO"], os.environ["SENHA"])
except Exception as e:
    print("O servidor de e-mail RECUSOU essa senha:", str(e)[:120])
    print("Nada foi alterado.")
    sys.exit(1)
print("Login OK.")
PY

cp -p "$ENV_FILE" "$ENV_FILE.bak-$(date +%Y%m%d-%H%M%S)"
python3 - "$ENV_FILE" <<'PY'
import os, sys
s = os.environ["SENHA"]
if "'" not in s:
    valor = "'" + s + "'"
else:
    valor = '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'
linhas = open(sys.argv[1], encoding="utf8").read().splitlines()
achou = False
for i, l in enumerate(linhas):
    if l.startswith("SMTP_SENHA="):
        linhas[i] = "SMTP_SENHA=" + valor
        achou = True
if not achou:
    linhas.append("SMTP_SENHA=" + valor)
open(sys.argv[1], "w", encoding="utf8").write("\n".join(linhas) + "\n")
PY
chmod 600 "$ENV_FILE"

echo "Recriando só a API com a senha nova (o site continua no ar)..."
"${DC[@]}" up -d --no-deps api >/dev/null
for _ in $(seq 1 30); do
  if curl -fsS http://127.0.0.1:8090/api/saude >/dev/null 2>&1; then
    echo "Pronto: senha trocada. Teste o botão \"Enviar por e-mail\" no Portal."
    exit 0
  fi
  sleep 2
done
echo "A API não respondeu em 60 s. Veja os logs: ${DC[*]} logs --tail=50 api"
exit 1
