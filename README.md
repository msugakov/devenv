# devenv
Docker image setup for development environment

How to build the damn thing
```bash
DOCKER_BUILDKIT=1 sudo -E time docker build --progress plain -t node-dev .
```

How to run the damn thing
```
sudo ~/projects/devenv/run-container.sh $(id --user) $(id --group)
```

Cleanup
1. https://stackoverflow.com/questions/34658836/docker-is-in-volume-in-use-but-there-arent-any-docker-containers
2. https://www.digitalocean.com/community/tutorials/how-to-remove-docker-images-containers-and-volumes
