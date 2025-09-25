#!/bin/bash

#==============================================================================
# Skrip Instalasi n8n via VPS
#==============================================================================

set -e  # Keluar jika terjadi error

# Variabel
N8N_DIR="$HOME/n8n"
DB_PASSWORD=""
DOMAIN=""
EMAIL=""
TIMEZONE="Asia/Jakarta"

print_header() {
    echo "=============================================="
    echo "        Skrip Instalasi n8n di VPS"
    echo "=============================================="
}

print_step() {
    echo "[LANGKAH] $1"
}

print_success() {
    echo "[BERHASIL] $1"
}

print_error() {
    echo "[ERROR] $1"
    exit 1
}

check_requirements() {
    print_step "Memeriksa persyaratan sistem..."
    
    # Cek apakah menggunakan Ubuntu
    if ! grep -q "Ubuntu" /etc/os-release 2>/dev/null; then
        print_error "Skrip ini membutuhkan Linux Ubuntu. Gunakan Ubuntu 22.04+ untuk kompatibilitas terbaik."
    fi
    
    # Cek apakah dijalankan sebagai root
    if [[ $EUID -eq 0 ]]; then
        print_error "Jangan jalankan skrip ini sebagai root. Jalankan sebagai user biasa yang memiliki akses sudo."
    fi
    
    # Cek akses sudo
    if ! sudo -n true 2>/dev/null; then
        print_error "Skrip ini membutuhkan akses sudo. Pastikan user Anda dapat menggunakan sudo."
    fi
    
    print_success "Persyaratan sistem terpenuhi"
}

get_user_input() {
    print_step "Mengambil detail konfigurasi..."
    
    # Ambil domain
    while [[ -z "$DOMAIN" ]]; do
        read -p "Masukkan nama domain Anda (misal: n8n.example.com): " DOMAIN
        if [[ ! "$DOMAIN" =~ ^[a-zA-Z0-9][a-zA-Z0-9.-]*[a-zA-Z0-9]$ ]]; then
            echo "Format domain tidak valid. Silakan coba lagi."
            DOMAIN=""
        fi
    done
    
    # Ambil email
    while [[ -z "$EMAIL" ]]; do
        read -p "Masukkan email untuk sertifikat SSL: " EMAIL
        if [[ ! "$EMAIL" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
            echo "Format email tidak valid. Silakan coba lagi."
            EMAIL=""
        fi
    done
    
    # Generate password database yang aman
    DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    
    print_success "Konfigurasi berhasil dikumpulkan"
}

update_system() {
    print_step "Memperbarui paket sistem..."
    
    sudo apt update -y
    sudo apt upgrade -y
    sudo apt install -y curl wget git unzip openssl
    
    print_success "Sistem berhasil diperbarui"
}

install_docker() {
    print_step "Menginstal Docker dan Docker Compose..."
    
    # Instal Docker
    if ! command -v docker &> /dev/null; then
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker $USER
        rm get-docker.sh
    fi
    
    # Instal Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        sudo apt install -y docker-compose
    fi
    
    print_success "Docker dan Docker Compose berhasil diinstal"
}

setup_n8n() {
    print_step "Menyiapkan konfigurasi n8n..."
    
    # Buat direktori n8n
    mkdir -p "$N8N_DIR"
    cd "$N8N_DIR"
    
    # Buat docker-compose.yml
    cat > docker-compose.yml << EOF
version: '3.8'

services:
  postgres:
    image: postgres:14
    container_name: n8n_postgres
    restart: unless-stopped
    environment:
      - POSTGRES_DB=n8n
      - POSTGRES_USER=n8n
      - POSTGRES_PASSWORD=${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U n8n"]
      interval: 30s
      timeout: 10s
      retries: 5
    networks:
      - n8n_network

  n8n:
    image: n8nio/n8n:latest
    container_name: n8n_app
    restart: unless-stopped
    ports:
      - "127.0.0.1:5678:5678"
    environment:
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres
      - DB_POSTGRESDB_DATABASE=n8n
      - DB_POSTGRESDB_USER=n8n
      - DB_POSTGRESDB_PASSWORD=${DB_PASSWORD}
      - N8N_HOST=https://${DOMAIN}
      - N8N_PORT=5678
      - N8N_PROTOCOL=https
      - NODE_ENV=production
      - N8N_SECURE_COOKIE=true
      - WEBHOOK_URL=https://${DOMAIN}
      - GENERIC_TIMEZONE=${TIMEZONE}
      - NODE_OPTIONS=--max-old-space-size=2048
      - EXECUTIONS_TIMEOUT=3600
      - EXECUTIONS_DATA_SAVE_ON_ERROR=all
      - EXECUTIONS_DATA_SAVE_ON_SUCCESS=all
    volumes:
      - n8n_data:/home/node/.n8n
    depends_on:
      postgres:
        condition: service_healthy
    networks:
      - n8n_network

volumes:
  postgres_data:
  n8n_data:

networks:
  n8n_network:
    driver: bridge
EOF
    
    print_success "Konfigurasi n8n berhasil dibuat"
}

install_nginx() {
    print_step "Menginstal dan mengkonfigurasi Nginx..."
    
    sudo apt install -y nginx
    
    # Buat konfigurasi Nginx
    sudo cat > /etc/nginx/sites-available/n8n << EOF
server {
    listen 80;
    server_name ${DOMAIN};
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name ${DOMAIN};
    
    # Konfigurasi SSL akan ditambahkan oleh Certbot
    
    # Header keamanan
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    # Rate limiting
    limit_req_zone \$binary_remote_addr zone=n8n_limit:10m rate=10r/m;
    limit_req zone=n8n_limit burst=20 nodelay;
    
    location / {
        proxy_pass http://127.0.0.1:5678;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
        client_max_body_size 50M;
    }
    
    location /webhook {
        proxy_pass http://127.0.0.1:5678;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_read_timeout 60s;
        limit_req off;
    }
    
    location /healthz {
        proxy_pass http://127.0.0.1:5678;
        access_log off;
    }
}
EOF
    
    # Aktifkan site
    sudo ln -sf /etc/nginx/sites-available/n8n /etc/nginx/sites-enabled/
    sudo rm -f /etc/nginx/sites-enabled/default
    
    # Tes konfigurasi nginx
    sudo nginx -t
    sudo systemctl reload nginx
    
    print_success "Nginx berhasil dikonfigurasi"
}

setup_ssl() {
    print_step "Mengatur sertifikat SSL dengan Let's Encrypt..."
    
    # Instal Certbot
    sudo apt install -y certbot python3-certbot-nginx
    
    # Dapatkan sertifikat SSL
    sudo certbot --nginx -d "$DOMAIN" --email "$EMAIL" --agree-tos --non-interactive --redirect
    
    # Atur auto-renewal
    (crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -
    
    print_success "Sertifikat SSL berhasil dikonfigurasi"
}

setup_firewall() {
    print_step "Mengkonfigurasi firewall..."
    
    # Atur UFW
    sudo ufw --force reset
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow ssh
    sudo ufw allow 'Nginx Full'
    sudo ufw --force enable
    
    print_success "Firewall berhasil dikonfigurasi"
}

start_services() {
    print_step "Menjalankan layanan n8n..."
    
    cd "$N8N_DIR"
    
    # Jalankan layanan Docker
    newgrp docker << EOF
docker-compose up -d
EOF
    
    # Tunggu layanan berjalan
    sleep 30
    
    # Cek apakah container berjalan
    if docker-compose ps | grep -q "Up"; then
        print_success "Layanan n8n berhasil dijalankan"
    else
        print_error "Gagal menjalankan layanan n8n. Cek log dengan: docker-compose logs"
    fi
}

create_backup_script() {
    print_step "Membuat skrip backup..."
    
    cat > "$N8N_DIR/backup.sh" << 'EOF'
#!/bin/bash
BACKUP_DIR="/home/backup/n8n"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup database
docker exec n8n_postgres pg_dump -U n8n -d n8n > $BACKUP_DIR/n8n_db_$DATE.sql

# Backup data n8n
docker run --rm -v n8n_n8n_data:/data -v $BACKUP_DIR:/backup alpine tar czf /backup/n8n_data_$DATE.tar.gz -C /data .

# Hapus backup lama (simpan 7 hari)
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "Backup selesai: $DATE"
EOF
    
    chmod +x "$N8N_DIR/backup.sh"
    
    # Tambahkan ke crontab untuk backup harian
    (crontab -l 2>/dev/null; echo "0 2 * * * $N8N_DIR/backup.sh >> /var/log/n8n-backup.log 2>&1") | crontab -
    
    print_success "Skrip backup berhasil dibuat"
}

print_completion() {
    echo
    echo "=============================================="
    echo "        Instalasi n8n Selesai!"
    echo "=============================================="
    echo
    echo "Instansi n8n Anda sekarang berjalan di:"
    echo "https://$DOMAIN"
    echo
    echo "Password Database: $DB_PASSWORD"
    echo "Direktori Instalasi: $N8N_DIR"
    echo
    echo "Perintah yang berguna:"
    echo "- Cek status: docker-compose ps"
    echo "- Lihat log: docker-compose logs -f n8n"
    echo "- Restart: docker-compose restart"
    echo "- Backup: ./backup.sh"
    echo
    echo "Simpan password database Anda dengan aman!"
    echo
}

# Eksekusi utama
main() {
    print_header
    check_requirements
    get_user_input
    update_system
    install_docker
    setup_n8n
    install_nginx
    setup_ssl
    setup_firewall
    start_services
    create_backup_script
    print_completion
}

# Jalankan fungsi utama
main "$@"
