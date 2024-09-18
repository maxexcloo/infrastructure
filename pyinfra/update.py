from pyinfra import host
from pyinfra.facts.server import Path
from pyinfra.operations import apt, server

if "apt" in host.data.get("flags"):
    apt.update(
        _sudo=True,
        name="Apt update",
    )

    apt.upgrade(
        _sudo=True,
        name="Apt upgrade",
    )

    server.shell(
        _sudo=True,
        name="Apt autoremove",
        commands=["apt autoremove"],
    )

    server.shell(
        _sudo=True,
        name="Apt clean",
        commands=["apt clean"],
    )

if "docker" in host.data.get("flags"):
    env = {"PATH": f"~/.local/bin:${host.get_fact(Path)}"}

    server.shell(name="Docker prune", commands=["docker system prune -a -f"], _env=env)

if "homebrew" in host.data.get("flags"):
    env = {"PATH": f"/Users/max.schaefer/.local/bin:/Users/max.schaefer/.local/share/mise/shims:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:${host.get_fact(Path)}"}

    server.shell(
        _env=env,
        name="Brew update",
        commands=["brew update"],
    )

    server.shell(
        _env=env,
        name="Brew upgrade",
        commands=["brew upgrade"],
    )

    # server.shell(
    #     _env=env,
    #     name="Brew upgrade casks",
    #     commands=["brew upgrade --cask --greedy"],
    # )

    server.shell(
        _env=env,
        name="Brew cleanup",
        commands=["brew cleanup -s"],
    )

    server.shell(
        _env=env,
        name="Brew relink",
        commands=["brew list --formula -1 | while read line; do brew unlink $line; brew link $line; done"],
    )

    server.shell(
        _env=env,
        name="Brew doctor",
        commands=["brew doctor"],
    )

    # server.shell(
    #     _env=env,
    #     name="Mac App Store upgrade",
    #     commands=["mas upgrade"],
    # )

    server.shell(
        _env=env,
        name="Mise upgrade",
        commands=["mise upgrade"],
    )

    server.shell(
        name="Write defaults",
        commands=[
            "defaults write com.apple.desktopservices DontWriteNetworkStores -bool true",
            "defaults write com.apple.dock autohide-time-modifier-float 0",
            "defaults write com.apple.dock contents-immutable -bool true",
            "defaults write com.apple.dock ResetLaunchPad -bool true",
            "defaults write com.apple.dock tilesize -int 48",
            "killall Dock",
        ],
    )

if "openwrt" == host.data.get("type"):
    server.shell(
        name="Tailscale update",
        commands=["tailscale update"],
    )
