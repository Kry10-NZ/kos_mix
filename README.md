<!--
Copyright (c) 2022, Kry10 Limited. All rights reserved.

SPDX-License-Identifier: LicenseRef-Kry10
-->

# KOS Mix

Tools for getting or installing the KOS system sources, building the KOS
documentation, starting the KOS development environment, using the Elixir
[Mix](https://hexdocs.pm/mix/Mix.html) build tool.

## Quickstart

*You will need to have installed the prerequisites that are described below
before the following commands will work.*

The following commands will download and set up a KOS system for use.
First you need to set the TOKEN for accessing the sources, and select
a platform to build the system libraries and tools for.
(These environment variables are only used for the following command
expansions).

TOKEN is an authentication token provided to you in order to access the sources.
KOS_PLATFORM is a target platform to use. `am335x` is for the Beaglebone Black,
and `qemu-arm-virt` is for a simulator platform that doesn't require hardware.

```
export TOKEN=ghp_YOUR_TOKEN_HERE
export KOS_PLATFORM=qemu-arm-virt
```

The following commands will:
- install a `mix` plugin called `kos_mix`,
- Check that all prerequisites are installed and work
- Install the most recent version of the Kry10 OS,
- Launch the documentation for the current version in a browser window,
- Launch a development shell for the target platform and build/install
  platform-specific self-contained dependencies via nix.

```
mix archive.install --force git https://github.com/Kry10-NZ/kos_mix.git
mix kos.deps.check
mix kos.install --token $TOKEN
mix kos.docs
mix kos.env -p $KOS_PLATFORM
```

Uninstalling can be achieved with:

```
mix archive.uninstall kos_mix
rm -rf ~/.kos/
```

## Prerequisites

The tools required to develop a KOS system are currently only supported on
Linux and MacOS. Windows is not supported. The tools are primarily created
and maintained for Ubuntu flavours of Linux, but have been tested on MacOS
and should work on other Linux distributions.

Once the archive has been installed, prerequisites can be checked with:
`mix kos.deps.check`. This requires Elixir and Git to be correctly installed
first.

The following third-party tools need to be installed:

### Install Nix Package Manager

The Nix Package Manager is a cross-platform manager used to create
reproducible, declarative and reliable systems. We use it to ensure that all
of KOS' dependencies are installed with the correct versions and to handle
version management.

Details on installing it can be found on the
[download nix](https://nixos.org/download.html#download-nix)
page, or the following steps can be performed:

Linux

```sh
$ sh <(curl -L https://nixos.org/nix/install) --daemon
```


MacOS

```sh
$ sh <(curl -L https://nixos.org/nix/install)
```

### Install Docker and Docker Compose

Docker is used to run the KOS management platform (Orbit) along with its
required dependencies.

Instructions for installing Docker can be found on the
[Docker](https://docs.docker.com/get-docker/) site, or the following
commands can be used. Note that Docker may need to be manually started
to complete initial installation before any command line programs will work.


Linux (Docker Engine)

```sh
$ cd $HOME/Downloads && git clone https://github.com/docker/docker-install && cd ./docker-install
$ sh install.sh
````

MacOS (Docker Desktop)

```sh
brew install --cask docker
```

### Elixir

After you've installed Nix, you can use it to install Elixir:

```shell
$ nix-env -i elixir
```

## `kos`

This provides a mix task that outputs the available KOS mix tasks.

## `kos.install`

This provides a mix task to fetch and install a copy of the KOS sources.

You can do:

* `mix kos.install` This will install a copy of the KOS sources into a given
  destination directory. The code will be placed into the directory pointed to
  environment variable `KOS_HOME` which defaults to the `.kos` folder of the
  current user's home directory.
  
This task has three arguments:

* `--token`, which is used to authenticate when downloading the KOS sources.
  Required.
* `--default`, which determines if this downloaded version of the sources will
  be set as the newest default toolchain. If there is no default toolchain set,
  then this argument is implicitly set.
* `--tag`, which determines which version of the KOS sources should be
  downloaded.

## `kos.docs`

This provides a mix task to take an existing KOS source installation and build
the KOS system documentation.

You can do:

* `mix kos.docs` This will build a copy of the KOS documentation using a
  pre-installed KOS installation. After the build is complete, the documentation
  will be opened using the default web browser of the current user. If this
  fails, the task will output a URL for the documentation to be manually opened.
  The documentation will be placed in the `docs` folder in the pre-installed KOS
  installation.

## `kos.env`

This provides a mix task that spawns a new terminal that is running the KOS
development shell.

You can do:

* `mix kos.env` This will look for the toolchains in a pre-installed KOS
  installation and spawn a new terminal running the KOS development shell.
  
This task requires a single command line argument:

* `--platform`, which determines the supported platform for the KOS development
  shell.
  
Run `mix help kos.env` for a list of supported platforms.

## `kos.orbit.start`

This provides a mix task that launches Orbit, the Kry10 Management Service.

You can do:

* `mix kos.orbit.start` This will pull the Docker images from 'ghcr.io' and use
  Docker and Docker Compose to start a copy of Orbit.
  
This task requires a single commnad line argument:

* `--token`, which is used to authenticate when pulling the Docker images from
  'ghcr.io'.
