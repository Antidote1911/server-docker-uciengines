# 🖥️ UCI Proxy — Guide Complet Client

[![Language: Rust](https://img.shields.io/badge/Language-Rust-orange.svg)](https://www.rust-lang.org/)

Ce guide explique comment utiliser **uciproxy** pour exécuter des moteurs d'échecs **distants** sur votre machine cliente.

---

## 📋 Table des matières

- [Vue d'ensemble](#-vue-densemble)
- [Architecture](#-architecture)
- [Installation](#-installation)
- [Utilisation](#-utilisation)
- [Mode proxy nommé](#-mode-proxy-nommé)
- [Reconnexion automatique](#-reconnexion-automatique)
- [Cas d'usage](#-cas-dusage)
- [Dépannage](#-dépannage)

---

## 🎯 Vue d'ensemble

**uciproxy** est un client léger qui :

- ✅ Se **connecte à un uciserver distant** (TCP)
- ✅ Se comporte comme un **moteur UCI local** face à votre logiciel d'échecs
- ✅ **Transparent** : le logiciel d'échecs ne fait pas la différence
- ✅ Supporte la **reconnexion automatique** en cas de coupure réseau

### Cas d'usage typiques

```
Arena / CuteChess / Chessbase / Droidfish
         │
    [uciproxy]  ← votre machine cliente
         │
      [TCP]     ← réseau
         │
    [uciserver] ← serveur distant (Unraid, Linux, Docker)
         │
    [Moteur UCI] ← Stockfish, Dragon, LC0...
```

---

## 🏗️ Architecture

### Flux de communication

```
┌─────────────────────────────────────────┐
│     Logiciel d'échecs (Windows/Mac)     │
│     Arena, CuteChess, Chessbase, etc.   │
└──────────────────┬──────────────────────┘
                   │
             stdin / stdout
                   │
       ┌───────────▼────────────┐
       │      uciproxy          │
       │ (Rust asynchrone)      │
       │ • Reçoit commandes UCI │
       │ • Envoie au serveur    │
       │ • Gère reconnexion     │
       └───────────┬────────────┘
                   │
              TCP socket
                   │
        ┌──────────▼─────────────┐
        │  [Réseau / Internet]   │
        │ 192.168.1.65:8100      │
        └──────────┬──────────────┘
                   │
       ┌───────────▼────────────────┐
       │      uciserver             │
       │ (Serveur distant)          │
       │ • Écoute TCP               │
       │ • Lance moteur UCI         │
       │ • Bridge bidirectionnel    │
       └───────────┬────────────────┘
                   │
             stdin / stdout
                   │
       ┌───────────▼────────────────┐
       │    Moteur UCI distant      │
       │  Stockfish, Dragon, LC0... │
       └────────────────────────────┘
```

---

## 💾 Installation

### Prérequis

- **Windows** : Rust toolchain (ou binaire pré-compilé)
- **Linux/macOS** : Rust toolchain
- **Optionnel** : accès SSH au serveur distant

### Obtenir uciproxy

#### Option 1 : Compiler depuis source

```bash
git clone https://github.com/Antidote1911/uciremote.git
cd uciremote
cargo build --release
```

Binaires produits :
- Linux/macOS : `target/release/uciproxy`
- Windows : `target/release/uciproxy.exe`

#### Option 2 : Cross-compiler pour Windows depuis Linux

Si vous êtes sur Linux et avez besoin d'une version Windows :

```bash
# Ajouter la target Windows
rustup target add x86_64-pc-windows-gnu

# Compiler
cargo build --release -p uciproxy --target x86_64-pc-windows-gnu

# Résultat
target/x86_64-pc-windows-gnu/release/uciproxy.exe
```

#### Option 3 : Télécharger binaires pré-compilés

(À ajouter selon votre GitHub Releases)

---

## 🚀 Utilisation

### Syntaxe basique

```bash
uciproxy --server <IP>:<PORT>
uciproxy -s <IP>:<PORT>
```

### Options

| Option | Court | Défaut | Description |
|--------|-------|--------|-------------|
| `--server` | `-s` | optionnel* | Adresse du serveur `ip:port` |
| `--retry` | `-r` | `5` | Délai de reconnexion (secondes) |
| `--help` | `-h` | — | Afficher l'aide |
| `--version` | `-V` | — | Afficher la version |

*Si omis, uciproxy cherche un fichier `.txt` (voir mode proxy nommé).

### Exemples simples

```bash
# Se connecter à Stockfish sur le serveur local
uciproxy --server 192.168.1.65:8100

# Forme courte
uciproxy -s 192.168.1.65:8100

# Avec reconnexion toutes les 10 secondes
uciproxy -s 192.168.1.65:8100 --retry 10

# Sans reconnexion automatique
uciproxy -s 192.168.1.65:8100 --retry 0

# Afficher l'aide
uciproxy --help

# Afficher la version
uciproxy --version
```

### Intégration dans une application

Beaucoup de logiciels d'échecs (Arena, CuteChess, Chessbase) permettent de configurer des moteurs UCI. Utilisez uciproxy comme moteur :

#### Windows (Arena, CuteChess, Chessbase)

```
Menu Moteurs → Ajouter moteur → uciproxy.exe
Dossier : C:\chess\engines\
Arguments : -s 192.168.1.65:8100
```

#### Linux

```bash
# Ajouter comme moteur dans votre logiciel d'échecs
/usr/local/bin/uciproxy --server 192.168.1.65:8100
```

---

## 📍 Mode proxy nommé

Le **mode proxy nommé** permet de lancer uciproxy **sans arguments**, ce qui est utile pour les applications qui ne supportent pas les paramètres du moteur.

### Fonctionnement

1. Copier `uciproxy` avec un nom suggestif
2. Créer un fichier `.txt` portant le même nom
3. Écrire l'adresse `IP:PORT` dans le fichier
4. Lancer le binaire — il lira automatiquement le `.txt`

### Exemples

#### Linux

```bash
# Créer deux proxies nommés
cp uciproxy remote_stockfish
cp uciproxy remote_dragon

# Créer les fichiers de configuration
echo "192.168.1.65:8100" > remote_stockfish.txt
echo "192.168.1.65:8200" > remote_dragon.txt

# Rendre exécutables
chmod +x remote_stockfish remote_dragon

# Lancer
./remote_stockfish
./remote_dragon
```

#### Windows

```cmd
REM Copier les exécutables
copy uciproxy.exe remote_stockfish.exe
copy uciproxy.exe remote_dragon.exe

REM Créer les fichiers de configuration
echo 192.168.1.65:8100 > remote_stockfish.txt
echo 192.168.1.65:8200 > remote_dragon.txt

REM Lancer
remote_stockfish.exe
remote_dragon.exe
```

### Où placer les fichiers

Les fichiers doivent être **dans le même répertoire** :

```
C:\chess\engines\
├── remote_stockfish.exe
├── remote_stockfish.txt
├── remote_dragon.exe
└── remote_dragon.txt
```

### Utilisation dans une application

Ajouter les binaires comme moteurs locaux :

- **Arena** : Menu Moteurs → Ajouter `remote_stockfish.exe`
- **CuteChess** : Menu Tools → Engines → Add Engine `remote_stockfish.exe`
- **Lichess** : Settings → Engine Management → Add `remote_stockfish.exe`

L'application les traite comme des moteurs ordinaires et ne fait pas la différence.

---

## 🔄 Reconnexion automatique

### Comportement par défaut

```bash
uciproxy -s 192.168.1.65:8100 --retry 5
```

- ✅ Connexion établie → fonctionne normalement
- ❌ Serveur se déconnecte → uciproxy attend **5 secondes**
- 🔁 Retente automatiquement la connexion
- ✅ Reconnectée → reprend transparemment

### Scénarios d'utilisation

```bash
# Reconnexion toutes les 5 secondes (défaut)
uciproxy -s 192.168.1.65:8100

# Reconnexion toutes les 30 secondes (réseau lent/instable)
uciproxy -s 192.168.1.65:8100 --retry 30

# Reconnexion toutes les secondes (LAN rapide)
uciproxy -s 192.168.1.65:8100 --retry 1

# Pas de reconnexion automatique (arrêt sur déconnexion)
uciproxy -s 192.168.1.65:8100 --retry 0
```

### Cas pratiques

#### 1. Serveur Unraid qui redémarre

```bash
# Config robuste
uciproxy -s 192.168.1.65:8100 --retry 10
```

Quand Unraid redémarre :
1. uciproxy détecte la déconnexion
2. Attend 10 secondes
3. Unraid relance les conteneurs
4. uciproxy se reconnecte automatiquement
5. Le logiciel d'échecs continue normalement

#### 2. Réseau instable (WiFi)

```bash
# Tolérant aux déconnexions courtes
uciproxy -s 192.168.1.65:8100 --retry 15
```

---

## 📋 Cas d'usage

### Cas 1 : Unraid + CuteChess sur Windows

**Architecture** :
- Serveur : Unraid + Docker (Stockfish sur 8100, Dragon sur 8200)
- Client : Windows avec CuteChess

**Setup client** :

```cmd
REM C:\chess\engines\
copy uciproxy.exe remote_stockfish.exe
copy uciproxy.exe remote_dragon.exe

echo 192.168.1.65:8100 > remote_stockfish.txt
echo 192.168.1.65:8200 > remote_dragon.txt
```

**Dans CuteChess** :
1. Tools → Engines
2. Add Engine → `C:\chess\engines\remote_stockfish.exe`
3. Add Engine → `C:\chess\engines\remote_dragon.exe`
4. C'est prêt !

### Cas 2 : Linux serveur + Droidfish sur Android (local)

**Architecture** :
- Serveur : Linux + uciserver
- Client : Droidfish sur le même réseau

**Setup serveur** :

```bash
uciserver -p 8100 -e /usr/bin/stockfish &
uciserver -p 8200 -e /usr/bin/dragon &
```

**Dans Droidfish** :
```
Settings → Network engine
  Server : 192.168.1.65:8100
```

### Cas 3 : Accès distant avec Tailscale + Droidfish

**Architecture** :
- Serveur : Unraid + Tailscale VPN
- Client : Droidfish sur Android + Tailscale

**Setup serveur** (avec Docker) :

```bash
docker compose up -d
# Stockfish sur 8100 via Tailscale
```

**Setup client Android** :
1. Installer Tailscale depuis Play Store
2. Se connecter au réseau Tailscale
3. Droidfish → Settings → Network engine
4. Server : `100.70.128.103:8100` (IP Tailscale du serveur)

**Résultat** : Accès sécurisé depuis n'importe où ! 🌍

### Cas 4 : Multi-clients sur le même serveur

**Serveur** :
```bash
docker compose up -d
# Stockfish : 8100
# Dragon : 8200
```

**Client 1 (Windows - CuteChess)** :
```cmd
copy uciproxy.exe sf.exe
echo 192.168.1.65:8100 > sf.txt
```

**Client 2 (Linux - CuteChess)** :
```bash
cp uciproxy stockfish_remote
echo "192.168.1.65:8100" > stockfish_remote.txt
chmod +x stockfish_remote
```

**Client 3 (Android - Droidfish)** :
```
Settings → Network engine → 192.168.1.65:8100
```

Les trois clients utilisent **simultanément** les mêmes moteurs ! 🎯

---

## 🔧 Dépannage

### ❌ "Connection refused"

```bash
# Vérifier que uciserver écoute
ss -tlnp | grep 8100          # Linux
netstat -tlnp | grep 8100      # Windows

# Vérifier l'adresse IP
ping 192.168.1.65

# Vérifier les logs du serveur
docker compose logs uciserver  # Si Docker
```

### ❌ "Connection timed out"

```bash
# Firewall bloque peut-être la connexion
# Vérifier les règles firewall

# Sur le serveur :
sudo ufw allow 8100  # Linux/UFW
sudo firewall-cmd --add-port=8100/tcp --permanent  # CentOS/Fedora

# Tester la connectivité
nc -zv 192.168.1.65 8100  # Linux
Test-NetConnection 192.168.1.65 -Port 8100  # PowerShell
```

### ❌ "uciproxy: command not found"

```bash
# uciproxy n'est pas dans le PATH
# Option 1 : ajouter au PATH
export PATH=$PATH:/chemin/vers/uciproxy
echo $PATH

# Option 2 : utiliser le chemin complet
/usr/local/bin/uciproxy -s 192.168.1.65:8100

# Option 3 : créer un symlink
sudo ln -s /chemin/vers/uciproxy /usr/local/bin/
```

### ❌ Mode proxy nommé ne fonctionne pas

```bash
# Vérifier que le fichier .txt existe
ls -la remote_stockfish.txt

# Vérifier le contenu (pas de caractères cachés)
cat remote_stockfish.txt
# Doit afficher : 192.168.1.65:8100

# Vérifier les permissions
chmod +x remote_stockfish
chmod 644 remote_stockfish.txt
```

### ✅ Vérifier que ça marche

```bash
# Test simple avec telnet
echo "uci" | nc localhost 8100

# Test uciproxy localement (simulation)
./uciproxy -s localhost:8100
```

---

## 📖 Ressources

- [uciremote (GitHub)](https://github.com/Antidote1911/uciremote)
- [server-docker-uciengines](https://github.com/Antidote1911/server-docker-uciengines)
- [UCI Protocol](http://wbec-ridderkerk.nl/html/UCIProtocol.html)
- [Tailscale](https://tailscale.com/)
- [Droidfish](https://github.com/peterosterlund2/droidfish)

---

**Made with ❤️ in Rust**
