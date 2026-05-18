# server-docker-uciengines

Moteurs d'échecs UCI exposés en TCP via Docker, avec **uciserver** compilé en Rust (binaire statique musl).

Compatible Droidfish (Android), CuteChess, Arena, Chessbase, et tout client utilisant `uciproxy`.

---

## Structure

```
.
├── Cargo.toml              ← workspace Rust (contient uciserver)
├── uciserver/              ← code source Rust de uciserver
│   ├── Cargo.toml
│   └── src/main.rs
├── uci-stockfish/
│   └── Dockerfile          ← build multi-stage : Rust + télécharge Stockfish
├── uci-dragon/
│   └── Dockerfile          ← build multi-stage : Rust + binaire Dragon local
├── docker-compose.yml
├── .env.example
└── .gitignore
```

---

## Prérequis

- Docker + Docker Compose
- Pour Dragon : disposer du binaire `dragon` (non open-source) et le placer dans `uci-dragon/`

---

## Configuration

```bash
cp .env.example .env
# éditer .env si besoin (ports)
```

`.env` :
```
STOCKFISH_PORT=8100
DRAGON_PORT=8200
```

> **Important** : `.env` est dans `.gitignore`. Ne commiter jamais ce fichier.

---

## Build et lancement

```bash
# Build et démarrage en arrière-plan
docker compose up -d --build

# Logs
docker compose logs -f

# Arrêt
docker compose down
```

Les containers redémarrent automatiquement au boot (`restart: unless-stopped`).

---

## Test de la communication

```bash
# Stockfish
telnet localhost 8100

# Dragon
telnet localhost 8200
```

Une fois connecté, taper `uci` puis Entrée — le moteur doit répondre.

---

## Utilisation avec uciproxy (client Windows/Linux)

```bash
# Stockfish distant
cp uciproxy.exe remote_stockfish.exe
echo 192.168.x.x:8100 > remote_stockfish.txt

# Dragon distant
cp uciproxy.exe remote_dragon.exe
echo 192.168.x.x:8200 > remote_dragon.txt
```

---

## Architecture Docker (multi-stage)

```
Stage 1 (rust:alpine)  →  compile uciserver → binaire statique musl (~5 Mo)
Stage 2 (alpine)       →  télécharge / copie le moteur UCI
Stage 3 (alpine)       →  image finale = uciserver + moteur seulement
```

L'image finale ne contient pas Rust, pas de compilateur, pas de toolchain.
Taille typique : ~15 Mo pour Stockfish, ~10 Mo pour Dragon.

---

## Commandes Docker utiles

```bash
# Arrêter tous les containers
docker stop $(docker ps -q)

# Purger les images non utilisées
docker system prune -a

# Redémarrer tous les containers
docker restart $(docker ps -a -q)

# Accès non-root (Arch Linux)
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker
```
