# 🏁 UCI Chess Engines over TCP — Docker + Rust

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Language: Rust](https://img.shields.io/badge/Language-Rust-orange.svg)](https://www.rust-lang.org/)
[![Container: Docker](https://img.shields.io/badge/Container-Docker-blue.svg)](https://www.docker.com/)

Exposez vos moteurs d'échecs UCI (Stockfish, Dragon, etc.) via **TCP** en utilisant **uciserver**, un serveur ultra-léger compilé en Rust avec binaires statiques MUSL.

> **Compatible avec** : DroidFish (Android), CuteChess, Arena, ChessBase, et tout client utilisant [`uciproxy`](./UCIPROXY_GUIDE.md).

---

## 📋 Table des matières

- [Vue d'ensemble](#-vue-densemble)
- [Prérequis](#-prérequis)
- [Installation rapide](#-installation-rapide)
- [Configuration](#-configuration)
- [Utilisation](#-utilisation)
- [Client UCI — uciproxy](#-client-uci--uciproxy)
- [Architecture](#-architecture)
- [Déploiement](#-déploiement)
- [Dépannage](#-dépannage)
- [Contribution](#-contribution)

---

## 🎯 Vue d'ensemble

Ce projet fournit une **pile Docker complète** pour exposer des moteurs UCI en réseau :

- **uciserver** : serveur TCP asynchrone écrit en Rust (5 Mo statique)
- **Multi-conteneurs** : Stockfish + Dragon (extensible)
- **Multi-stage Docker** : images minimalistes (~15 Mo Stockfish, ~10 Mo Dragon)
- **Zéro dépendances** : binaires statiques musl, Alpine Linux
- **uciproxy** : client UCI léger pour connecter des moteurs distants

### Flux de données (architecture complète)

```
┌────────────────────────────────────────────────────────────────┐
│                  Logiciel d'échecs (client)                    │
│        Arena, CuteChess, Droidfish, Chessbase...              │
└────────────────┬─────────────────────────────────────────────┘
                 │
            stdin / stdout
                 │
      ┌──────────▼──────────┐
      │     uciproxy        │  ← Voir UCIPROXY_GUIDE.md
      │   (moteur "local")  │
      └──────────┬──────────┘
                 │
              [TCP]
                 │
      ┌──────────▼──────────────────────┐
      │  Réseau / Tailscale / VPN...     │
      └──────────┬──────────────────────┘
                 │
   ┌─────────────▼─────────────┐
   │  Docker / Linux / Unraid  │
   │  ┌───────────────────────┐ │
   │  │  [uciserver]          │ │
   │  │  ┌─────────────────┐  │ │
   │  │  │ Stockfish/Dragon│  │ │
   │  │  └─────────────────┘  │ │
   │  └───────────────────────┘ │
   └─────────────────────────────┘
```

---

## 📦 Prérequis

- **Docker** ≥ 20.10
- **Docker Compose** ≥ 2.0
- **Pour Dragon** : disposer du binaire propriétaire `dragon` (non open-source)
  - Placer le binaire dans `uci-dragon/dragon`

### Optionnel (développement)

- **Rust** ≥ 1.70 (pour modifier uciserver)
- **Make** (pour les commandes pratiques)

---

## ⚡ Installation rapide

### 1️⃣ Cloner le dépôt

```bash
git clone https://github.com/Antidote1911/server-docker-uciengines.git
cd server-docker-uciengines
```

### 2️⃣ Configurer l'environnement

```bash
cp .env.example .env
# Éditez les ports si nécessaire
cat .env
```

### 3️⃣ Démarrer les services

```bash
docker compose up -d --build
```

### 4️⃣ Vérifier les logs

```bash
docker compose logs -f
```

---

## ⚙️ Configuration

### Variables d'environnement (`.env`)

```bash
# Ports TCP des moteurs
STOCKFISH_PORT=8100
DRAGON_PORT=8200
```

> ⚠️ **Important** : `.env` est ignoré par Git (sécurité). Ne le commitez jamais.

### Exemple : modifier les ports

```bash
# Éditer .env
echo "STOCKFISH_PORT=9000" > .env
echo "DRAGON_PORT=9001" >> .env

# Redémarrer
docker compose restart
```

---

## 🚀 Utilisation

### Test de connexion (telnet)

```bash
# Stockfish
telnet localhost 8100

# Dragon
telnet localhost 8200
```

Une fois connecté :

```
$ telnet localhost 8100
Connected to localhost.
Escape character is '^]'.
uci
id name Stockfish 17
id author the Stockfish developers (see AUTHORS file)
option name ...
uciok
```

### Test avec nc (netcat)

```bash
echo "uci" | nc localhost 8100
```

### Avec uciproxy (Windows/Linux)

Pour exécuter des moteurs **distants** sur votre machine cliente, utilisez **uciproxy**.

👉 **[Voir le guide complet → UCIPROXY_GUIDE.md](./UCIPROXY_GUIDE.md)**

#### Setup rapide (Windows)

```batch
:: Télécharger/compiler uciproxy
cargo build --release

:: Copier l'exécutable
copy target/release/uciproxy.exe remote_stockfish.exe

:: Créer le fichier config
echo 192.168.x.x:8100 > remote_stockfish.txt

:: Ajouter dans votre logiciel d'échecs (Arena, CuteChess, etc.)
:: Utiliser remote_stockfish.exe comme moteur local
```

#### Setup rapide (Linux)

```bash
# Compiler
cargo build --release

# Copier
cp target/release/uciproxy remote_stockfish

# Config
echo "192.168.x.x:8100" > remote_stockfish.txt

# Rendre exécutable
chmod +x remote_stockfish
```

---

## 🏗️ Architecture

### Structure du projet

```
.
├── Cargo.toml                  # Workspace Rust
├── uciserver/                  # Serveur UCI (code source)
│   ├── Cargo.toml
│   └── src/main.rs             # Logique TCP/stdin-stdout bridge
├── uci-stockfish/
│   └── Dockerfile              # Build multi-stage + Stockfish
├── uci-dragon/
│   ├── Dockerfile              # Build multi-stage + Dragon
│   └── dragon                  # Binaire Dragon (git-ignored)
├── docker-compose.yml          # Orchestration des services
├── .env.example                # Template environnement
├── .gitignore
├── README.md
├── UCIPROXY_GUIDE.md           # Guide complet du client uciproxy
└── LICENSE
```

### Build multi-stage Dockerfile

```dockerfile
# Stage 1 : Compilation Rust
FROM rust:alpine AS builder
COPY uciserver /app
RUN cargo build --release --target x86_64-unknown-linux-musl

# Stage 2 : Image finale
FROM alpine:latest
COPY --from=builder /app/target/x86_64-unknown-linux-musl/release/uciserver /usr/local/bin/
COPY stockfish /usr/local/bin/
CMD ["uciserver", "--port", "8100", "--engine", "/usr/local/bin/stockfish"]
```

**Avantages** :

- ✅ Image finale minimaliste (~15 Mo)
- ✅ Aucun compilateur Rust dans l'image de production
- ✅ Binaires statiques MUSL = compatible multi-plateforme
- ✅ Startup instantané

---

## 🌍 Déploiement

### Démarrer les services

```bash
# Build + démarrage en arrière-plan
docker compose up -d --build

# Vérifier le statut
docker compose ps

# Logs en temps réel
docker compose logs -f stockfish
docker compose logs -f dragon
```

### Arrêter les services

```bash
docker compose down
```

### Logs complets

```bash
# Tous les services
docker compose logs

# Un service spécifique
docker compose logs -f stockfish

# Dernières 50 lignes
docker compose logs --tail=50
```

### Redémarrer automatiquement

Les conteneurs ont `restart: unless-stopped` → ils redémarrent automatiquement à chaque reboot de l'hôte.

---

## 🐳 Commandes Docker utiles

```bash
# Arrêter tous les conteneurs
docker compose stop

# Redémarrer tous les services
docker compose restart

# Reconstruire les images (sans cache)
docker compose build --no-cache

# Voir l'utilisation des ressources
docker stats

# Purger les images non utilisées
docker system prune -a

# Nettoyer les volumes
docker volume prune
```

### Accès sans sudo (Linux)

```bash
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker

# Test
docker ps
```

---

## 🔧 Dépannage

### ❌ Erreur : "Port already in use"

```bash
# Trouver le processus occupant le port
lsof -i :8100

# Arrêter manuellement
kill -9 <PID>

# Ou modifier les ports dans .env
echo "STOCKFISH_PORT=9000" > .env
```

### ❌ Erreur : "Failed to start engine"

```bash
# Vérifier que le moteur est présent
docker compose exec stockfish which stockfish

# Vérifier les permissions
ls -la uci-dragon/dragon

# Vérifier le Dockerfile
cat uci-stockfish/Dockerfile
```

### ❌ Connexion refusée

```bash
# Vérifier les conteneurs
docker compose ps

# Vérifier les logs
docker compose logs stockfish

# Redémarrer les services
docker compose restart
```

### ✅ Test de connectivité

```bash
# Depuis la machine hôte
telnet localhost 8100

# Depuis un autre PC du réseau
telnet <IP_SERVER> 8100

# Avec nc
echo "uci" | nc -w 1 localhost 8100
```

---

## 📚 Utilisation avancée

### Exécuter uciserver localement

```bash
# Compiler
cd uciserver
cargo build --release

# Lancer
./target/release/uciserver --port 7900 --engine /usr/bin/stockfish

# Options
./target/release/uciserver --help
# Usage: uciserver [OPTIONS]
# Options:
#   -p, --port <PORT>        Port TCP à écouter [required]
#   -e, --engine <ENGINE>    Chemin vers le moteur UCI [required]
#       --host <HOST>        Interface réseau [default: 0.0.0.0]
#   -h, --help              Afficher l'aide
#   -V, --version           Afficher la version
```

### Ajouter un nouveau moteur

1. Créer un répertoire `uci-moteur/`
2. Ajouter un `Dockerfile` (copier depuis `uci-stockfish/Dockerfile`)
3. Éditer `docker-compose.yml` :

```yaml
services:
  lichess:
    container_name: lichess_uci
    restart: unless-stopped
    build:
      context: .
      dockerfile: uci-lichess/Dockerfile
      args:
        PORT: ${LICHESS_PORT}
    env_file:
      - .env
    ports:
      - "${LICHESS_PORT}:${LICHESS_PORT}"
```

4. Ajouter au `.env` :

```
LICHESS_PORT=8300
```

5. Redémarrer :

```bash
docker compose up -d --build
```

---

## 🔐 Sécurité

- ✅ Binaires statiques musl (pas de dépendances système)
- ✅ Images Alpine (surface d'attaque minimale)
- ⚠️ **ATTENTION** : uciserver écoute sur `0.0.0.0` — limitez l'accès réseau si le serveur est sur Internet
- 💡 **Recommandation** : utilisez un firewall ou un VPN pour l'accès distant

### Restreindre l'accès à localhost

Éditez `docker-compose.yml` :

```yaml
services:
  stockfish:
    ports:
      - "127.0.0.1:8100:8100"  # Localhost uniquement
```

---

## 📄 Licence

MIT License — voir [LICENSE](LICENSE)

---

## 👤 Auteur

**Fabrice Corraire**

- 📧 [antidote1911@gmail.com](mailto:antidote1911@gmail.com)
- 🐙 [@Antidote1911](https://github.com/Antidote1911)

---

## 🤝 Contribution

Les contributions sont bienvenues !

1. Fork le projet
2. Créer une branche (`git checkout -b feature/amelioration`)
3. Commit vos changements (`git commit -m 'Add feature'`)
4. Pousser vers GitHub (`git push origin feature/amelioration`)
5. Ouvrir une Pull Request

---

## 🐛 Signaler un bug

Utilisez [GitHub Issues](https://github.com/Antidote1911/server-docker-uciengines/issues) pour signaler un bug.

**Incluez** :
- Les logs Docker
- La version de Docker
- Les commandes utilisées
- Le système d'exploitation

---

## 📌 Roadmap

- [ ] GitHub Actions CI/CD (build + tests)
- [ ] Health checks Docker
- [ ] Monitoring Prometheus
- [ ] Support multi-architectures (ARM64, ARMv7)
- [ ] Web UI pour gérer les moteurs
- [ ] Persistance des logs

---

## 📖 Ressources

- [UCI Protocol](http://wbec-ridderkerk.nl/html/UCIProtocol.html)
- [uciremote — Client uciproxy](https://github.com/Antidote1911/uciremote)
- [Rust async/await avec Tokio](https://tokio.rs/)
- [Docker best practices](https://docs.docker.com/develop/dev-best-practices/)
- [Alpine Linux](https://alpinelinux.org/)
- [Tailscale VPN](https://tailscale.com/)

---

**Made with ❤️ in Rust & Docker**
