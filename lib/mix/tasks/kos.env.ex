# Copyright (c) 2022, Kry10 Limited. All rights reserved.
#
# SPDX-License-Identifier: LicenseRef-Kry10

defmodule Mix.Tasks.Kos.Env do
  use Mix.Task

  @shortdoc "Launch a KOS development environment shell"
  @moduledoc """
  #{@shortdoc}

    $ mix kos.env

  Launches a KOS development environment for a specified platform.

  Supported platforms: am335x (beaglebone black), imx8mm-evk, nitrogen6sx, x86_64 (simulator), qemu-arm-virt (simulator)

  Command line arguments:

  * `--platform`: KOS platform.
  """

  @terminal_list ~w(x-terminal-emulator mate-terminal gnome-terminal terminator xfce4-terminal urxvt rxvt termit Eterm aterm uxterm xterm roxterm termite lxterminal terminology st qterminal lilyterm tilix terminix konsole kitty guake tilda alacritty hyper wezterm)

  @impl true
  @doc false
  def run(args) do
    opts = process_args(args)
    validate_opts(opts)
    nix_shell = System.find_executable("nix-shell")

    unless nix_shell do
      Mix.raise("Could not find nix-shell. Is `nix` installed?")
    end

    path = Path.join(KosMix.get_default_toolchain(), "shell.nix")

    unless File.regular?(path) do
      Mix.raise("Could not find kos install at: " <> KosMix.get_default_toolchain())
    end

    kos_core_path = Path.join([KosMix.get_default_toolchain(), "projects", "kos_core"])

    unless System.find_executable("nix") do
      Mix.raise("Could not find `nix` program.")
    end

    json_path =
      :os.cmd(
        ~C(nix --extra-experimental-features nix-command show-config --json | nix-shell --quiet -p jq --run "jq -c '.\"nix-path\".value'")
      )

    {nix_path, _} = Code.eval_string(json_path)
    nix_path = Enum.join(["kos_core=" <> kos_core_path] ++ nix_path, ":")

    script = create_temp_file()
    System.cmd("chmod", ~w(+x #{script}))

    base_script = """
      #! /bin/bash
      echo "Launching kos.env for #{opts[:platform]}"
      rm #{script}
      export NIX_PATH="#{nix_path}"
      #{nix_shell} -A #{opts[:platform]} #{path}
      /bin/bash
    """
    File.write!(script, base_script)

    {cmd, args} =
      case :os.type() do
        {:unix, :darwin} ->
          {"open", ~w(-a Terminal -W #{script})}

        _ ->
          term = System.get_env("TERMINAL")

          terminal_prog =
            @terminal_list
            |> List.foldl(term, fn term, found ->
              if found do
                found
              else
                System.find_executable(term)
              end
            end)

          {terminal_prog, ~w(-e #{script})}
      end

    Task.start(fn -> System.cmd(cmd, args, into: IO.stream()) end)
    :timer.sleep(1000)
  end

  @switches [platform: :string]
  @aliases [p: :platform]

  defp process_args(args) do
    {opts, left, inv} = OptionParser.parse(args, strict: @switches, aliases: @aliases)
    platform = Keyword.get(opts, :platform)

    %{
      platform: platform,
      remaining_args: left,
      invalid_args: inv
    }
  end

  @platforms KosMix.supported_platforms()

  defp validate_opts(opts) do
    case opts do
      %{platform: platform} when platform not in @platforms ->
        Mix.raise(
          "Unsupported kos platform: #{inspect(platform)}. Supported platforms: #{inspect(KosMix.supported_platforms())}"
        )

      %{invalid_args: inv} when inv != [] ->
        Mix.raise("Unexpected arguments: #{inspect(opts[:invalid_args])}")

      %{remaining_args: left} when left != [] ->
        Mix.raise("Unexpected arguments: #{inspect(opts[:remaining_args])}")

      _ ->
        nil
    end
  end

  defp create_temp_file() do
    {file, 0} = System.cmd("mktemp", [])
    String.trim(file)
  end

end
