# NSD Container

Build infrastructure for an NSD container using the [in-tree container Dockerfile](https://github.com/NLnetLabs/nsd/tree/master/contrib/container).


## Usage

    docker pull ghcr.io/jschlyter/nsd-container

## Configuration

- [`nsd.conf`](https://github.com/NLnetLabs/nsd/blob/master/contrib/container/nsd.conf) is mounted at `/config/nsd.conf`
- All volatile data is stored under `/storage`

A [docker compose file](docker-compose.yaml) is available.


## Remote Control

Plain docker:

    docker exec nsd nsd-control

or using docker compose:

    docker compose exec nsd nsd-control
