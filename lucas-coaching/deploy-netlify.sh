#!/usr/bin/env bash
# Publie le site Lucas Coaching sur Netlify via l'API.
# Prérequis : variable NETLIFY_AUTH_TOKEN (jeton d'accès personnel Netlify).
# Usage : ./deploy-netlify.sh [nom-du-site]   (par défaut : lucas-coaching)
set -euo pipefail

NAME="${1:-lucas-coaching}"
API="https://api.netlify.com/api/v1"
DIR="$(cd "$(dirname "$0")" && pwd)"
: "${NETLIFY_AUTH_TOKEN:?NETLIFY_AUTH_TOKEN manquant}"
AUTH=(-H "Authorization: Bearer ${NETLIFY_AUTH_TOKEN}")

ZIP="$(mktemp -d)/site.zip"
(cd "$DIR" && zip -qr "$ZIP" index.html assets)

# Réutilise le site s'il existe déjà sur le compte, sinon le crée.
SITE_ID="$(curl -fsS "${AUTH[@]}" "$API/sites?name=$NAME&filter=all" \
  | python3 -c "import json,sys; s=[x for x in json.load(sys.stdin) if x['name']==sys.argv[1]]; print(s[0]['id'] if s else '')" "$NAME")"
if [ -z "$SITE_ID" ]; then
  RESP="$(curl -sS "${AUTH[@]}" -H "Content-Type: application/json" -d "{\"name\":\"$NAME\"}" "$API/sites")"
  SITE_ID="$(printf '%s' "$RESP" | python3 -c "import json,sys; print(json.load(sys.stdin).get('id',''))")"
  if [ -z "$SITE_ID" ]; then
    echo "Création impossible (nom « $NAME » déjà pris ?) : $RESP" >&2
    exit 1
  fi
fi

curl -fsS "${AUTH[@]}" -H "Content-Type: application/zip" --data-binary @"$ZIP" \
  "$API/sites/$SITE_ID/deploys" >/dev/null
echo "En ligne : https://$NAME.netlify.app"
