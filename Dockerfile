# ------------------------------------------------------------------------------
# Dockerfile — SIGI (Sistema Integrado de Gestão Interna)
#
# Multi-stage build. Produz uma imagem final magra que executa Node.js
# a servir a aplicação Nuxt 4 construída em modo produção.
# ------------------------------------------------------------------------------

# ---- Stage 1: dependências ----
FROM node:20-bookworm-slim AS deps

WORKDIR /app

# Instalar pnpm via corepack (é o gestor que o projeto usa)
RUN corepack enable && corepack prepare pnpm@10.19.0 --activate

# Instalar apenas os manifestos primeiro, para tirar partido da cache do Docker
COPY package.json pnpm-lock.yaml* ./

# Instalar dependências de produção + dev (precisamos das dev para o build)
RUN pnpm install --frozen-lockfile

# ---- Stage 2: build ----
FROM node:20-bookworm-slim AS builder

WORKDIR /app

RUN corepack enable && corepack prepare pnpm@10.19.0 --activate

# Trazer node_modules do stage anterior
COPY --from=deps /app/node_modules ./node_modules

# Copiar todo o código
COPY . .

# Construir a aplicação Nuxt em modo produção
# Produz .output/server/index.mjs e .output/public/*
RUN NODE_OPTIONS="--max-old-space-size=3072" pnpm build

# ---- Stage 3: runtime ----
FROM node:20-bookworm-slim AS runner

WORKDIR /app

# Variáveis de ambiente por defeito (podem ser sobrepostas no docker-compose)
ENV NODE_ENV=production
ENV NUXT_HOST=0.0.0.0
ENV NUXT_PORT=3000

# Copiar apenas o output de produção do stage builder
COPY --from=builder /app/.output ./.output

# Utilizador não-root por segurança
RUN groupadd -r nuxt && useradd -r -g nuxt nuxt \
    && chown -R nuxt:nuxt /app

USER nuxt

EXPOSE 3000

# Iniciar o servidor Nitro produzido pelo Nuxt
CMD ["node", ".output/server/index.mjs"]
