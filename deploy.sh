#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# deploy.sh — atualiza e reinicia o SIGI num só comando.
#
# Uso no servidor:
#   ./deploy.sh
#
# Faz: git pull -> rebuild da imagem -> aplica migrações -> reinicia -> limpa.
# ------------------------------------------------------------------------------
set -euo pipefail

cd "$(dirname "$0")"

COMPOSE="docker compose -f docker-compose.prod.yml --env-file .env"

if [ ! -f .env ]; then
  echo "ERRO: falta o ficheiro .env. Cria-o primeiro:"
  echo "  cp .env.example .env && nano .env"
  exit 1
fi

echo "==> 1/4  A atualizar o código (git pull)..."
git pull --ff-only

echo "==> 2/4  A reconstruir a imagem e reiniciar (db + migrate + app)..."
$COMPOSE up -d --build

echo "==> 3/4  A limpar imagens Docker antigas..."
docker image prune -f >/dev/null 2>&1 || true

echo "==> 4/4  Estado atual:"
$COMPOSE ps

echo ""
echo "Concluído. Ver logs da app:   $COMPOSE logs -f app"
