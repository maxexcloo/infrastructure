from pyinfra.operations import server

server.shell(
    _sudo=True,
    name="Reboot server",
    commands=["reboot"],
)
