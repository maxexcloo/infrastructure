from pyinfra import host
from pyinfra.facts.server import Command, LsbRelease, Path
from pyinfra.operations import apt, server

if "apt" in host.data.get("flags"):
    apt.packages(
        _sudo=True,
        name=f"Install apt packages",
        packages=["curl"],
        update=True,
    )

    if "cloudflared" in host.data.get("flags"):
        dpkg_arch = host.get_fact(Command, command="dpkg --print-architecture")

        apt.deb(
            _sudo=True,
            name="Install cloudflared",
            src=f"https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-{dpkg_arch}.deb",
        )

        server.shell(
            _success_exit_codes=[0,1],
            _sudo=True,
            name="Uninstall cloudflared service",
            commands=[f"cloudflared service uninstall"],
        )

        server.shell(
            _sudo=True,
            name="Configure cloudflared service",
            commands=[f"cloudflared service install {host.data.get("cloudflare_tunnel_token")}"],
        )

    if "docker" in host.data.get("flags"):
        dpkg_arch = host.get_fact(Command, command="dpkg --print-architecture")
        lsb_release = host.get_fact(LsbRelease)
        lsb_id = lsb_release["id"].lower()

        apt.packages(
            _sudo=True,
            name="Install docker prerequisites",
            packages=["ca-certificates"],
            update=True,
        )

        apt.key(
            _sudo=True,
            name="Download the docker apt key",
            src=f"https://download.docker.com/linux/{lsb_id}/gpg",
        )

        apt.repo(
            _sudo=True,
            name="Add the docker apt repo",
            filename="docker",
            src=f"deb [arch={dpkg_arch}] https://download.docker.com/linux/{lsb_id} {lsb_release['codename']} stable",
        )

        apt.packages(
            _sudo=True,
            name="Install docker via apt",
            packages=[
                "containerd.io",
                "docker-buildx-plugin",
                "docker-ce",
                "docker-ce-cli",
                "docker-compose-plugin",
            ],
            update=True,
        )

        server.group(
            _sudo=True,
            name="Create docker group",
            group="docker",
        )

        server.user(
            _sudo=True,
            name="Add primary user to docker group",
            groups=["docker"],
            user=host.data.get("ssh_user"),
        )
