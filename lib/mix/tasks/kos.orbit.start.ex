# Copyright (c) 2022, Kry10 Limited. All rights reserved.
#
# SPDX-License-Identifier: LicenseRef-Kry10

defmodule Mix.Tasks.Kos.Orbit.Start do
  use Mix.Task

  @shortdoc "Launch Orbit, the Kry10 Management Service"
  @moduledoc """
  #{@shortdoc}
  It might need sudo depending on how docker is installed.

  docker (20.10.17+) and docker compose (2.6.0+) are required.

      $ mix kos.orbit.start
  """

  @impl true
  @doc false
  def run(_args) do
    docker = System.find_executable("docker")

    unless docker do
      Mix.raise("Could not find docker. Is `docker` installed?")
    end

    use_sudo = needs_sudo?(docker)

    orbit_version_file = Path.join([KosMix.get_default_toolchain(), "orbit", "VERSION"])

    unless File.regular?(orbit_version_file) do
      Mix.raise("Could not find Orbit VERSION at: " <> orbit_version_file)
    end

    orbit_tag = File.read!(orbit_version_file) |> String.trim()

    docker_compose_file =
      Path.join([KosMix.get_default_toolchain(), "orbit", "docker-compose.yml"])

    unless File.regular?(docker_compose_file) do
      Mix.raise("Could not find Orbit docker-compose.yml at: " <> docker_compose_file)
    end

    with :ok <- pull_image(docker, use_sudo, orbit_tag) do
      compose_up(docker, docker_compose_file, orbit_tag, use_sudo)
    end
  end

  defp compose_up(docker, docker_compose_file, orbit_tag, use_sudo) do
    args = "compose -f #{docker_compose_file} --profile orbit_tag up --force-recreate"
    exec = if use_sudo, do: "sudo ", else: ""

    """

    To start orbit run:

    #{exec}ORBIT_TAG=#{orbit_tag} #{docker} #{args}

    To stop orbit <ctrl-c> the running console.
    """
    |> Mix.shell().info()
  end

  defp needs_sudo?(docker) do
    case System.cmd(docker, ["version"], stderr_to_stdout: true) do
      {_, 0} ->
        false

      {output, 1} ->
        if output =~ "permission denied" do
          true
        else
          Mix.raise("Failed to run docker. Reason: #{output}")
        end
    end
  end

  defp pull_image(docker, use_sudo, orbit_tag) do
    nix_shell = System.find_executable("nix-shell")

    unless nix_shell, do: Mix.raise("Could not find nix-shell. Is `nix` installed?")

    askpass_shell =
      Path.join([KosMix.get_default_toolchain(), "projects", "studio", "kos_mix", "shell.nix"])

    unless File.regular?(askpass_shell),
      do: Mix.raise("Could not find shell.nix at: " <> askpass_shell)

    kos_home = KosMix.get_path(:kos_home)
    File.mkdir_p("#{kos_home}/.docker")

    sudo_args =
      if use_sudo do
        "SUDO_ASKPASS=$(which askpass.sh) sudo -A"
      else
        ""
      end

    args = [
      askpass_shell,
      "--run",
      "#{sudo_args} #{docker} --config #{kos_home}/.docker pull ghcr.io/kry10-nz/release:#{orbit_tag}"
    ]

    case System.cmd(nix_shell, args, stderr_to_stdout: true, into: IO.stream()) do
      {_output, 0} ->
        :ok

      {_, exit_status} ->
        Mix.shell().error("Failed to authenticate. Exit status: #{exit_status}")
        {:error, exit_status}
    end
  end
end
