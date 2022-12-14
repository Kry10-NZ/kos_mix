<!--
Copyright (c) 2022, Kry10 Limited. All rights reserved.

SPDX-License-Identifier: LicenseRef-Kry10
-->

# KOS Mix

Tools for getting or installing the KOS system sources, building the KOS
documentation, starting the KOS development environment, using the Elixir
[Mix](https://hexdocs.pm/mix/Mix.html) build tool.

## Build and install archive

To build and install Kos_Mix as an archive you can do:

* `mix archive.install git https://github.com/Kry10-NZ/kos_mix.git`

It can be uninstalled with:

* `mix archive.uninstall kos_mix`

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

### Install Docker Engine

Docker is used to run the KOS management platform (Orbit) along with its
required dependencies.

Instructions for installing Docker can be found on the
[Docker](https://docs.docker.com/engine/install/) site, or the following
commands can be used:


Linux

```sh
$ cd $HOME/Downloads && git clone https://github.com/docker/docker-install && cd ./docker-install
$ sh install.sh
````

MacOS

```sh
brew install docker docker-machine
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
