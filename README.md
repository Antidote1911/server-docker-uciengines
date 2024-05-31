# Remote Chess Engines

Docker image i use on my server to play chess remotely with Droidfish on my phone (who include an option to add a remote uci engine),  or for Chessbase app on Windows with a little uci-remote client.

By default, Stockfish server run on port 8100 and Dragon on port 8200. Make sure this ports are unused on your system or If you need, you can change them in the environment file `.env`

## Build

To build and launch this Docker image, clone this repo :
```
git clone git@github.com:Antidote1911/uciengines.git
```

Go to the project folder and build it :
```
cd uciengines && docker-compose up -d
```
## Tests
You can test the communication with Stockfish and Dragon :

```bash
telnet localhost 8100
telnet localhost 8200
```

### Uninstall:

To uninstal this, stop the images, and remove all stoped :
```
docker stop stockfish dragon
docker system prune --all --volumes --force
```
### Usefull Docker commands:

On my system (Archlinux), to not run Docker as root, i need to add my user to the docker group with ` sudo groupadd docker ` ` sudo usermod -aG docker $USER ` ` newgrp docker `
```
# Stop all containers
docker stop `docker ps -qa`

# Purge all stoped
docker system prune -a

# Restarting ALL (stopped and running) containers
docker restart $(docker ps -a -q)
```