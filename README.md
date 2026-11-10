# Setup

## Fresh debian install
### Setting QEMU/KVM or Oracle VirtualBox

<!-- <details>

<summary>Specific to QEMU</summary>

</details> -->
Get [**Debian iso**](https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-13.7.0-amd64-netinst.iso) and create VM from it. Once logged in

```sh
sudo apt update && sudo apt install make git curl
```

<details> <summary>Specific to QEMU</summary>
add to network hardware inside interface type="user" block to allow ssh from host machine

```xml
<portForward proto="tcp" address="127.0.0.1">
	<range start="2222" to="22"/>
</portForward>
<backend type="passt"/>
```

</details>

Install [**docker engine for debian**](https://docs.docker.com/engine/install/debian/) 

```sh
sudo apt remove $(dpkg --get-selections docker.io docker-compose docker-doc docker-buildx podman-docker containerd runc | cut -f1)
```

```sh
# Add Docker's official GPG key:
sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt update
```

```sh
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

- **Don't forget** [post install](https://docs.docker.com/engine/install/linux-postinstall/) and reboot/logout to apply group changes

```sh
sudo usermod -aG docker $USER && sudo reboot
```



# Links

- [Dockerfile](https://docs.docker.com/reference/dockerfile "Docker docs")
- [docker-arg-env-var](https://vsupalov.com/docker-arg-env-variable-guide/)
- [wordpress](https://wiki.alpinelinux.org/wiki/WordPress "Wiki Alpine Wordpress")
- [mariaDB](https://wiki.alpinelinux.org/wiki/MariaDB "Wiki Alpine MariaDB") and [mariaDb-install](https://mariadb.com/docs/server/clients-and-utilities/deployment-tools/mariadb-install-db )
- [Nginx](https://wiki.alpinelinux.org/wiki/Nginx "Wiki Alpine Nginx")
- [KVM/QEMU](https://www.youtube.com/watch?v=N_0SIOceugs "Youtube FR")
- [set -eou pipefail](https://gist.github.com/mohanpedala/1e2ff5661761d3abd0385e8223e16425?permalink_comment_id=3799230)
