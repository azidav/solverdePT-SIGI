# Deploy do SIGI com Docker

Guia para instalar e manter o SIGI num servidor Linux (Ubuntu/Debian) com Docker.
Tudo corre em contentores: não é preciso instalar Node, pnpm ou PostgreSQL no servidor.

---

## 1. Pré-requisitos (uma só vez)

Instala o Docker (inclui o Docker Compose v2):

```bash
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker "$USER"
```

Sai da sessão SSH e volta a entrar (para o grupo `docker` fazer efeito). Confirma:

```bash
docker --version
docker compose version
```

---

## 2. Primeira instalação

```bash
# 1. Clonar o projeto
git clone https://github.com/azidav/solverdePT-SIGI.git ~/sigi
cd ~/sigi

# 2. Criar o ficheiro de configuração a partir do exemplo
cp .env.example .env
nano .env        # preencher POSTGRES_PASSWORD e JWT_SECRET (ver notas no ficheiro)

# 3. Construir e arrancar (db + migrações + app)
docker compose -f docker-compose.prod.yml --env-file .env up -d --build
```

O primeiro arranque demora alguns minutos (a construir a imagem). Quando terminar,
acede em **http://IP-DO-SERVIDOR:3000**.

**Login inicial:** `admin` / `admin123` — muda a password imediatamente em
*Definições* ou no menu do utilizador.

---

## 3. Atualizações (sempre que houver código novo)

A forma mais simples — um só comando:

```bash
cd ~/sigi
./deploy.sh
```

O `deploy.sh` faz: `git pull` → reconstrói a imagem → **aplica as migrações da base
de dados** → reinicia → limpa imagens antigas.

> **Porque é que já não tens de aplicar migrações à mão:** o serviço `migrate` do
> compose corre o `db/update.sql` em cada arranque. Como esse ficheiro é idempotente
> (`IF NOT EXISTS`, `ON CONFLICT DO NOTHING`), pode correr as vezes que forem sem
> partir nada — colunas e tabelas novas entram automaticamente na BD existente.

Se preferires sem o script:

```bash
cd ~/sigi
git pull
docker compose -f docker-compose.prod.yml --env-file .env up -d --build
```

---

## 4. Operações do dia-a-dia

Todas assumem que estás em `~/sigi`. Prefixo comum:
`docker compose -f docker-compose.prod.yml --env-file .env`

```bash
# Ver estado dos contentores
docker compose -f docker-compose.prod.yml ps

# Ver logs da app (Ctrl+C para sair)
docker compose -f docker-compose.prod.yml logs -f app

# Ver o resultado das migrações
docker compose -f docker-compose.prod.yml logs migrate

# Reiniciar só a app
docker compose -f docker-compose.prod.yml --env-file .env restart app

# Parar tudo (sem apagar dados)
docker compose -f docker-compose.prod.yml down

# Arrancar de novo
docker compose -f docker-compose.prod.yml --env-file .env up -d
```

---

## 5. Backups da base de dados

Os dados vivem no volume `sigi_pgdata` e **não** são apagados por `down` nem por
rebuilds. Ainda assim, faz backups regulares.

```bash
# Exportar um backup (dump SQL)
docker exec sigi_postgres pg_dump -U sigi sigi_prod > backup_$(date +%F).sql

# Restaurar um backup (ATENÇÃO: substitui os dados atuais)
cat backup_2026-08-11.sql | docker exec -i sigi_postgres psql -U sigi -d sigi_prod
```

(Ajusta `sigi` / `sigi_prod` se mudaste `POSTGRES_USER` / `POSTGRES_DB` no `.env`.)

Automatizar um backup diário com cron:

```bash
crontab -e
# adicionar a linha (backup às 03:00, guarda em ~/sigi-backups):
0 3 * * * docker exec sigi_postgres pg_dump -U sigi sigi_prod > ~/sigi-backups/backup_$(date +\%F).sql
```

---

## 6. HTTPS com Nginx (recomendado em produção)

Para servir em `https://sigi.solverde.pt` em vez de `IP:3000`.

**a)** Em `docker-compose.prod.yml`, muda a porta da app para ficar só acessível
localmente (o Nginx é que expõe ao exterior):

```yaml
    ports:
      - "127.0.0.1:3000:3000"
```

e volta a subir: `docker compose -f docker-compose.prod.yml --env-file .env up -d`.

**b)** Instala Nginx + Certbot:

```bash
sudo apt update && sudo apt install -y nginx
sudo snap install --classic certbot
```

**c)** Cria `/etc/nginx/sites-available/sigi`:

```nginx
server {
    server_name sigi.solverde.pt;

    client_max_body_size 20M;   # para upload de saldos por Excel

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

**d)** Ativa e emite o certificado:

```bash
sudo ln -s /etc/nginx/sites-available/sigi /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
sudo certbot --nginx -d sigi.solverde.pt
```

O Certbot configura o HTTPS e a renovação automática.

Depois de teres HTTPS, atualiza no `.env`:
`NUXT_PUBLIC_BASE_URL=https://sigi.solverde.pt`

---

## 7. Arranque automático

O `restart: unless-stopped` no compose faz os contentores voltarem a subir sozinhos
se o servidor reiniciar (desde que o serviço Docker arranque no boot, o que é o
comportamento por defeito). Confirma com:

```bash
sudo systemctl is-enabled docker    # deve dizer "enabled"
```

---

## 8. Resolução de problemas

| Sintoma | O que verificar |
|---|---|
| A app não abre em `:3000` | `docker compose ... logs app` — ver erros de arranque |
| Erro de coluna/tabela em falta | `docker compose ... logs migrate` — confirmar que as migrações correram sem erro |
| Migrações falharam | Correr à mão: `docker exec -i sigi_postgres psql -U sigi -d sigi_prod -v ON_ERROR_STOP=1 -f - < db/update.sql` |
| Build falha em `pnpm build` | Confirmar que o servidor tem RAM suficiente (o build usa até ~3 GB) |
| Esqueci a password do admin | Ver secção abaixo |

**Repor a password do admin** (define-a como `admin123`):

```bash
docker exec -i sigi_postgres psql -U sigi -d sigi_prod -c "UPDATE users SET password = '\$2b\$10\$xn/YpyF2OAwALd8gicGoCOcMcV5Q5ZSnyV9tD9nbXMRjU9O48uKVS', must_change_password = true WHERE username = 'admin';"
```

---

## Resumo rápido

| Ação | Comando |
|---|---|
| Instalar | `cp .env.example .env` → editar → `docker compose -f docker-compose.prod.yml --env-file .env up -d --build` |
| Atualizar | `./deploy.sh` |
| Logs | `docker compose -f docker-compose.prod.yml logs -f app` |
| Backup | `docker exec sigi_postgres pg_dump -U sigi sigi_prod > backup.sql` |
