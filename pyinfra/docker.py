from pyinfra import host
from pyinfra.facts.server import Path
from pyinfra.operations import files, server

if "docker" in host.data.get("flags"):
    env = {"PATH": f"/Users/max.schaefer/.local/bin:/Users/max.schaefer/.local/share/mise/shims:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:${host.get_fact(Path)}"}

    files.sync(
        name="Upload docker directory",
        delete=True,
        dest="/tmp/docker",
        src="docker",
    )

    server.shell(
        _env=env,
        _success_exit_codes=[0,1],
        name="Create default docker network",
        commands=["docker network create docker"],
    )

    server.shell(
        _chdir="/tmp/docker/caddy",
        _env=env,
        name="Deploy caddy with docker compose",
        commands=["docker compose up -d"],
    )

    server.shell(
        _chdir="/tmp/docker/portainer",
        _env=env,
        name="Deploy portainer agent with docker compose",
        commands=["docker compose -f docker-compose.agent.yaml up -d"],
    )

    if "portainer" in host.data.get("flags"):
        server.shell(
            _chdir="/tmp/docker/portainer",
            _env=env,
            name="Deploy portainer service with docker compose",
            commands=["docker compose -f docker-compose.service.yaml up -d"],
        )

    server.shell(
        name="Clean up docker directory",
        commands=["rm -rf /tmp/docker"],
    )
