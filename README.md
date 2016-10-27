# docker-tramp - TRAMP integration for docker containers

*Authors:* Erno Kuusela, based on docker-tramp from Mario Rodas <marsam@users.noreply.github.com><br>
*Version:* 0.1<br>

`lxc-tramp.el` offers a TRAMP method for LXC containers.

## Usage

Offers the TRAMP method `lxc` to access running containers

    C-x C-f /lxc:user@container:/path/to/file

    where
      user           is the user that you want to use (optional)
      container      is the id or name of the container

