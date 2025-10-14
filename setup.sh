#!/bin/bash

set -e

echo "=== Script Instalasi n8n ==="

# --- Input ---
read -p "Masukkan Domain (contoh: domain-kamu.com): " DOMAIN_NAME
read -p "Masukkan Email untuk SSL: " SSL_EMAIL
read -sp "Masukkan Password Database Postgres: " POSTGRES_PASSWORD
echo ""

# --- Update & Dependencies ---
echo "[1/7] Update & Install dependencies..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget git unzip

# --- Install Docker ---
echo "[2/7] Install Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker "$USER"

# --- Install Docker Compose ---
echo "[3/7] Install Docker Compose..."
sudo apt install -y docker-compose-plugin

# --- Setup Directory ---
echo "[4/7] Setup direktori n8n..."
mkdir -p ~/n8n && cd ~/n8n

# Buat .env
cat > .env <<EOL
# Domain Configuration
DOMAIN_NAME=$DOMAIN_NAME
SSL_EMAIL=$SSL_EMAIL

# Data Directory
DATA_FOLDER=./data

# Database
POSTGRES_PASSWORD=$POSTGRES_PASSWORD
EOL

# Buat file docker-compose.yml
cat > docker-compose.yml <<'EOL'
services:
  traefik:
    image: traefik
    container_name: n8n_traefik
    restart: unless-stopped
    command:
      - --api=true
      - --api.insecure=true
      - --api.dashboard=true
      - --providers.docker=true
      - --providers.docker.exposedbydefault=false
      - --entrypoints.web.address=:80
      - --entrypoints.websecure.address=:443
      - --certificatesresolvers.mytlschallenge.acme.tlschallenge=true
      - --certificatesresolvers.mytlschallenge.acme.email=${SSL_EMAIL}
      - --certificatesresolvers.mytlschallenge.acme.storage=/letsencrypt/acme.json
      - --entrypoints.web.http.redirections.entryPoint.to=websecure
      - --entrypoints.web.http.redirections.entryPoint.scheme=https
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ${DATA_FOLDER}/letsencrypt:/letsencrypt
      - /var/run/docker.sock:/var/run/docker.sock:ro
    networks:
      - n8n_network

  postgres:
    image: postgres:14
    container_name: n8n_postgres
    restart: unless-stopped
    environment:
      - POSTGRES_DB=n8n
      - POSTGRES_USER=n8n
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
    volumes:
      - ${DATA_FOLDER}/postgres:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U n8n"]
      interval: 30s
      timeout: 10s
      retries: 5
    networks:
      - n8n_network

  n8n:
    image: docker.n8n.io/n8nio/n8n:latest
    container_name: n8n_app
    restart: unless-stopped
    environment:
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_DATABASE=n8n
      - DB_POSTGRESDB_USER=n8n
      - DB_POSTGRESDB_PASSWORD=${POSTGRES_PASSWORD}
      - N8N_HOST=${DOMAIN_NAME}
      - N8N_PORT=5678
      - N8N_PROTOCOL=https
      - NODE_ENV=production
      - N8N_BASIC_AUTH_ACTIVE=false
      - N8N_SECURE_COOKIE=true
      - WEBHOOK_URL=https://${DOMAIN_NAME}
      - GENERIC_TIMEZONE=Asia/Jakarta
      - NODE_OPTIONS=--max-old-space-size=2048
      - EXECUTIONS_TIMEOUT=3600
      - EXECUTIONS_TIMEOUT_MAX=7200
      - EXECUTIONS_DATA_SAVE_ON_ERROR=all
      - EXECUTIONS_DATA_SAVE_ON_SUCCESS=all
      - EXECUTIONS_DATA_MAX_AGE=168
    volumes:
      - ${DATA_FOLDER}/.n8n:/home/node/.n8n
    labels:
      - traefik.enable=true
      - traefik.http.routers.n8n.rule=Host("${DOMAIN_NAME}")
      - traefik.http.routers.n8n.tls=true
      - traefik.http.routers.n8n.entrypoints=websecure
      - traefik.http.routers.n8n.tls.certresolver=mytlschallenge
    depends_on:
      postgres:
        condition: service_healthy
    networks:
      - n8n_network

networks:
  n8n_network:
    driver: bridge
EOL

# --- Setup Data Directory ---
echo "[5/7] Setup data directory..."
mkdir -p data/letsencrypt data/.n8n data/postgres
sudo chown -R 1000:1000 data/.n8n
sudo chown -R 999:999 data/postgres
sudo chmod 600 data/letsencrypt

# --- Setup Firewall ---
echo "[6/7] Setup firewall..."
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable

# --- Start Services ---
echo "[7/7] Menjalankan n8n & Traefik..."
docker compose up -d

echo "=== Setup selesai! ==="
echo "Akses n8n di: https://$DOMAIN_NAME"
