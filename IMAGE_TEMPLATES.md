# Template Link Gambar untuk README.md n8n

Berikut adalah template link gambar yang sudah disiapkan dalam README.md. Anda tinggal mengganti URL placeholder dengan link gambar sesungguhnya:

## 1. Logo dan Header
```markdown
<h1 align="center"><img src="https://docs.n8n.io/assets/images/n8n-logo.png" width="400"></h1>
```
**Ganti dengan**: Logo n8n yang lebih besar/custom

## 2. Instalasi - Docker Status
```markdown
![n8n Docker Status](https://via.placeholder.com/600x300/0066CC/FFFFFF?text=n8n+Docker+Containers+Running)
```
**Screenshot yang dibutuhkan**: 
- Terminal menampilkan `docker-compose ps` 
- Status containers running
- Ports yang terbuka (5678)

## 3. Instalasi - SSL Setup Complete
```markdown
![n8n SSL Setup Complete](https://via.placeholder.com/600x300/10B981/FFFFFF?text=n8n+SSL+Configuration+Complete)
```
**Screenshot yang dibutuhkan**:
- Browser menampilkan HTTPS padlock
- n8n login screen dengan SSL aktif
- Certbot success message

## 4. Konfigurasi - Owner Account Setup
```markdown
![n8n Owner Account Setup](https://via.placeholder.com/600x400/8B5CF6/FFFFFF?text=n8n+Owner+Account+Creation)
```
**Screenshot yang dibutuhkan**:
- n8n first-time setup screen
- Form create owner account
- Email, nama, password fields

## 5. Otomatisasi - DigitalOcean 1-Click
```markdown
![DigitalOcean n8n](https://via.placeholder.com/600x300/0066CC/FFFFFF?text=DigitalOcean+n8n+1-Click+Install)
```
**Screenshot yang dibutuhkan**:
- DigitalOcean marketplace
- n8n 1-click app listing
- Create droplet interface

## 6. Otomatisasi - Railway Deploy
```markdown
![Railway Deploy](https://via.placeholder.com/600x300/8B5CF6/FFFFFF?text=Railway+n8n+Deploy)
```
**Screenshot yang dibutuhkan**:
- Railway.app dashboard
- n8n template deployment
- Deploy button interface

## 7. Otomatisasi - Render Blueprint
```markdown
![Render Blueprint](https://via.placeholder.com/600x300/10B981/FFFFFF?text=Render+n8n+Blueprint)
```
**Screenshot yang dibutuhkan**:
- Render.com blueprint page
- n8n template selection
- One-click deploy interface

## 8. Cara Pemakaian - Dashboard Overview
```markdown
![n8n Dashboard Overview](https://via.placeholder.com/800x500/1F2937/FFFFFF?text=n8n+Dashboard+Interface)
```
**Screenshot yang dibutuhkan**:
- n8n main dashboard
- Workflows, Executions, Credentials menu
- Main interface overview

## 9. Cara Pemakaian - New Workflow
```markdown
![n8n New Workflow](https://via.placeholder.com/800x400/3B82F6/FFFFFF?text=n8n+Workflow+Editor)
```
**Screenshot yang dibutuhkan**:
- n8n workflow editor (kosong)
- Node palette di sebelah kiri
- Canvas area untuk workflow

## 10. Cara Pemakaian - Node Connection
```markdown
![n8n Node Connection](https://via.placeholder.com/700x400/10B981/FFFFFF?text=n8n+Node+Connections)
```
**Screenshot yang dibutuhkan**:
- Beberapa nodes yang sudah terkoneksi
- Flow arrows antar nodes
- Node configuration panel

## 11. Cara Pemakaian - Workflow Activated
```markdown
![n8n Workflow Activation](https://via.placeholder.com/600x300/F59E0B/FFFFFF?text=n8n+Workflow+Activated)
```
**Screenshot yang dibutuhkan**:
- Toggle switch "Active" ON
- Status workflow aktif
- Execution ready message

## 12. Cara Pemakaian - Database Backup Workflow
```markdown
![n8n Database Backup Workflow](https://via.placeholder.com/800x400/8B5CF6/FFFFFF?text=n8n+Database+Backup+Workflow)
```
**Screenshot yang dibutuhkan**:
- Complete workflow untuk database backup
- Schedule trigger → Execute command → Upload → Notify
- Node connections yang jelas

## 13. Cara Pemakaian - Social Media Automation
```markdown
![n8n Social Media Automation](https://via.placeholder.com/800x400/EF4444/FFFFFF?text=n8n+Social+Media+Automation)
```
**Screenshot yang dibutuhkan**:
- Workflow multi-platform posting
- Webhook → Twitter → Facebook → LinkedIn → Telegram
- Social media nodes

## 14. Cara Pemakaian - Credentials Management
```markdown
![n8n Credentials Management](https://via.placeholder.com/700x500/6366F1/FFFFFF?text=n8n+Credentials+Setup)
```
**Screenshot yang dibutuhkan**:
- Settings → Credentials page
- List of different credential types
- Add new credential interface

## 15. Cara Pemakaian - Execution History
```markdown
![n8n Execution History](https://via.placeholder.com/800x400/059669/FFFFFF?text=n8n+Execution+Monitoring)
```
**Screenshot yang dibutuhkan**:
- Executions tab
- List of successful/failed executions
- Execution details view

## Instruksi Penggantian Link Gambar:

### Cara 1: Upload ke GitHub Repository
1. Buat folder `images/` di root repository
2. Upload screenshot dengan nama deskriptif: `n8n-dashboard.png`
3. Ganti placeholder URL dengan: `images/n8n-dashboard.png`

### Cara 2: Upload ke Image Hosting
1. Upload ke Imgur, GitHub Assets, atau hosting lain
2. Copy direct link gambar
3. Ganti placeholder URL dengan link tersebut

### Cara 3: Menggunakan GitHub Issues (Recommended)
1. Buat issue dummy di repository
2. Drag & drop gambar ke comment box
3. Copy link yang di-generate GitHub
4. Close issue dan gunakan link tersebut

### Format Penggantian:
```markdown
# Dari:
![Alt Text](https://via.placeholder.com/600x300/COLOR/TEXT)

# Menjadi:
![Alt Text](https://your-image-url.com/image.png)
# atau
![Alt Text](images/your-screenshot.png)
```

### Tips Screenshot:
1. **Browser**: Gunakan incognito mode untuk UI bersih
2. **Resolution**: Minimal 1280x720 untuk clarity
3. **Format**: PNG untuk UI, JPG untuk content
4. **Size**: Kompres untuk loading cepat (< 500KB)
5. **Consistency**: Gunakan browser/theme yang sama
6. **Annotations**: Tambah arrows/highlights jika perlu

### Recommended Tools:
- **Screenshot**: Lightshot, Snagit, built-in tools
- **Editing**: GIMP, Canva, Figma
- **Compression**: TinyPNG, ImageOptim
- **Hosting**: GitHub, Imgur, Cloudinary