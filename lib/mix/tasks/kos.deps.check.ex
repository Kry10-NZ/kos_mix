# Copyright (c) 2022, Kry10 Limited. All rights reserved.
#
# SPDX-License-Identifier: LicenseRef-Kry10

defmodule Mix.Tasks.Kos.Deps.Check do
  use Mix.Task

  @shortdoc "Verify system prerequisites are sufficient"
  @moduledoc """
  #{@shortdoc}

    $ mix kos.deps.check

  `--quiet` or `-q`: run checks in verbose mode
  `--check=<app>` or `-c=<app>`: run individual checks [all, nix, docker, docker_compose, curl, elixir]
  """

  @impl true
  @doc false
  def run(args) do
    {opts, _, _} =
      OptionParser.parse(args,
        strict: [quiet: :boolean, check: :string],
        aliases: [q: :quiet, c: :check]
      )

    check = opts[:check] || "all"
    quiet = opts[:quiet] || false

    cond do
      quiet == false -> Mix.shell().info("Modes, quiet: #{quiet}, check: #{check}")
      quiet == true -> nil
    end

    checks(check, quiet)
  end

  defp checks(check, quiet) do
    case check do
      "all" ->
        check_nix(quiet)
        check_docker(quiet)
        check_docker_compose(quiet)
        check_curl(quiet)
        check_elixir(quiet)

      "nix" ->
        check_nix(quiet)

      "docker" ->
        check_docker(quiet)

      "docker_compose" ->
        check_docker_compose(quiet)

      "curl" ->
        check_curl(quiet)

      "elixir" ->
        check_elixir(quiet)
    end
  end

  defp info(message, false), do: Mix.shell().info(message)
  defp info(_message, true), do: :ok

  # NIX
  defp check_nix(quiet) do
    minimal = "> 2.0.0"
    app_name = "nix"

    case System.shell(
           "#{app_name} --version 1>/dev/null && #{app_name} --version | cut -d ' ' -f3",
           stderr_to_stdout: true
         ) do
      {version, 0} ->
        version = String.trim_trailing(version)

        case Version.match?(String.trim_trailing(version), minimal) do
          true ->
            info("Version installed [#{app_name}]: #{version}, compatible.", quiet)

          false ->
            Mix.shell().error(
              "Version problem [#{app_name}]: installed #{version} | required #{minimal}"
            )

            :error
        end

      {error, _} ->
        Mix.shell().error("Error [#{app_name}]: #{String.trim_trailing(error)}")
        :error
    end
  end

  # DOCKER
  defp check_docker(quiet) do
    minimal = "> 20.8.0"
    app_name = "docker"

    case System.shell(
           "#{app_name} --version 1>/dev/null && #{app_name} --version | cut -d ' ' -f3 | tr -d ','",
           stderr_to_stdout: true
         ) do
      {version, 0} ->
        version = String.trim_trailing(version)

        case Version.match?(String.trim_trailing(version), minimal) do
          true ->
            info("Version installed [#{app_name}]: #{version}, compatible.", quiet)

          false ->
            Mix.shell().error(
              "Version problem [#{app_name}]: installed #{version} | required #{minimal}"
            )

            :error
        end

      {error, _} ->
        Mix.shell().error("Error [#{app_name}]: #{String.trim_trailing(error)}")
        :error
    end
  end

  # DOCKER COMPOSE
  defp check_docker_compose(quiet) do
    minimal = "> 2.0.0"
    app_name = "docker compose"

    case System.shell(
           "#{app_name} version 1>/dev/null && #{app_name} version | cut -d ' ' -f4 | tr -d 'v'",
           stderr_to_stdout: true
         ) do
      {version, 0} ->
        version = String.trim_trailing(version)

        case Version.match?(String.trim_trailing(version), minimal) do
          true ->
            info("Version installed [#{app_name}]: #{version}, compatible.", quiet)

          false ->
            Mix.shell().error(
              "Version problem [#{app_name}]: installed #{version} | required #{minimal}"
            )

            :error
        end

      {error, _} ->
        Mix.shell().error("Error [#{app_name}]: #{String.trim_trailing(error)}")
        :error
    end
  end

  # ELIXIR
  defp check_elixir(quiet) do
    minimal = "> 1.13.0"
    app_name = "elixir"

    case System.shell(
           "#{app_name} --version 1>/dev/null 2>/dev/null && #{app_name} --version 2>/dev/null | grep compiled | cut -d ' ' -f2"
         ) do
      {version, 0} ->
        version = String.trim_trailing(version)

        case Version.match?(String.trim_trailing(version), minimal) do
          true ->
            info("Version installed [#{app_name}]: #{version}, compatible.", quiet)

          false ->
            Mix.shell().error(
              "Version problem [#{app_name}]: installed #{version} | required #{minimal}"
            )

            :error
        end

      {error, _} ->
        Mix.shell().error("Error [#{app_name}]: #{String.trim_trailing(error)}")
        :error
    end
  end

  # CURL
  defp check_curl(quiet) do
    minimal = "> 6.0.0"
    app_name = "curl"

    case System.shell(
           "#{app_name} --version 1>/dev/null && #{app_name} --version | grep #{app_name} | cut -d ' ' -f2",
           stderr_to_stdout: true
         ) do
      {version, 0} ->
        version = String.trim_trailing(version)

        case Version.match?(String.trim_trailing(version), minimal) do
          true ->
            info("Version installed [#{app_name}]: #{version}, compatible.", quiet)

          false ->
            Mix.shell().error(
              "Version problem [#{app_name}]: installed #{version} | required #{minimal}"
            )

            :error
        end

      {error, _} ->
        Mix.shell().error("Error [#{app_name}]: #{String.trim_trailing(error)}")
        :error
    end
  end
end
