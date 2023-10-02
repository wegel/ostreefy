## OSTreefy any distro

Massive shout-outs to [M1cha](https://github.com/M1cha/) for [M1cha/archlinux-ostree](https://github.com/M1cha/archlinux-ostree) and [GrabbenD](https://github.com/GrabbenD) for [GrabbenD/ostree-utility](https://github.com/GrabbenD/ostree-utility) for making this possible.

### Overview

This is a set of base images and accompanying scripts and utilities to convert distros to OSTree. OSTree-based distros are immutable by default.

Once you are running an OSTreefy-based system, you can upgrade it by building a new image and deploying it to the system. If something goes wrong, you can easily roll back to the previous image.

Base images are built automatically by GitHub Actions and are available on [GitHub Container Registry](https://github.com/wegel/ostreefy/pkgs/container/ostreefy%2Fbase%2Farchlinux/versions). Example "final" images are also automatically built [and available on GHCR](https://github.com/wegel/ostreefy/pkgs/container/ostreefy%2Fexamples%2Farchlinux-wegel/versions).

### Persistence

As per OSTree's design, the root filesystem is read-only and all changes are stored in `/var`. This means that the system is stateless and can be reset to a previous state at any time. `/etc` is treated as a special case and the changes are merged during upgrades.

### Running

`./ostreefy upgrade public.ecr.aws/q8x0g0l6/ostreefy/examples/archlinux:wegel-0.0.1`

### Similar projects

- ***[ostree-utility](https://github.com/GrabbenD/ostree-utility)***
- ***[archlinux-ostree](https://github.com/M1cha/archlinux-ostree)***
- [BootC](https://github.com/containers/bootc)
- [Universal Blue](https://universal-blue.org/)
