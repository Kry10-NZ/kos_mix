# Copyright (c) 2022, Kry10 Limited. All rights reserved.
#
# SPDX-License-Identifier: LicenseRef-Kry10

defmodule Mix.Tasks.Kos.Install do
  use Mix.Task

  @shortdoc "Installs a copy of the KOS code"

  @moduledoc """
  #{@shortdoc}

    $ mix kos.install

  This will download and install a copy of the KOS code in the KOS_HOME directory.

  `KOS_HOME` is a global destination directory for the KOS code. By default it
    is `~/.kos`.

  Command line arguments:

  * `--token`: authentication token required for obtaining the sources
  * `--default` or `-d`: Set the new version as the default toolchain.
  * `--tag` or `-t`: The selected version of the sources

  If there is no default toolchain set (indicated by the path: `$KOS_HOME/toolchains/default`)
  or the `--default/-d` flag was provided then the new version will be set as the default version.

  """

  @default_tar_url_base "https://github.com/Kry10-NZ/release/archive/refs/tags/"
  @default_tar_version "1.0.0-beta-rc3"

  defp ver_sha("1.0.0-beta"), do: "e4b20a81b09c694f0953f72a7e0ca5d1aeb6db541848b4f5cd903573387cba71"
  defp ver_sha("1.0.0-beta-rc2"), do: "0d59ffad9fc7866d1e3d325a6dc9176c4c8c0800975968af4ea793cd02c3bc0d"
  defp ver_sha("1.0.0-beta-rc3"), do: "8d2f0dc3b661ad6d428c83cd35a4d0545d95faa6726264cf7e5d90f984bd215f"

  @impl true
  @doc false
  def run(args) do
    Mix.shell().info("Installing KOS code")
    nix_shell = System.find_executable("nix-shell")

    unless nix_shell do
      Mix.raise("Could not find nix-shell. Is `nix` installed?")
    end

    opts_map = process_args_and_env(args)
    validate_opts(opts_map)

    # get the destination dir and install KOS into it
    tag = opts_map[:tag]
    tag_sha = ver_sha(tag)
    dest_dir_base = KosMix.get_path(:kos_toolchain_base)
    dest_dir = Path.join(dest_dir_base, "kos-#{tag}")
    download_file = Path.join(dest_dir_base, "release-#{tag}.tar.gz")

    url = @default_tar_url_base
    token = opts_map[:token]

    install_res =
      with :ok <- File.mkdir_p(dest_dir_base),
           {:exists, _path, false} <- {:exists, dest_dir, File.exists?(dest_dir)},
           {_output, 0} <-
             System.cmd(
               "curl",
               ~w(--user kosuser:#{token} --location --remote-name #{url}/#{tag}.tar.gz --remote-header-name),
               cd: dest_dir_base
             ),
           {:get_file, _path, true} <- {:get_file, download_file, File.exists?(download_file)},
           {sha_sum, 0} <-
             System.cmd(nix_shell, ~w(--pure -p --run) ++ ["sha256sum release-#{tag}.tar.gz"],
               cd: dest_dir_base
             ),
           {:sha256, [^tag_sha | _]} <- {:sha256, String.split(sha_sum)},
           {_output, 0} <- System.cmd("tar", ~w(-xf release-#{tag}.tar.gz), cd: dest_dir_base),
           {:rename, :ok} <-
             {:rename, File.rename(Path.join(dest_dir_base, "release-#{tag}"), dest_dir)},
           {:rm_tar, {:ok, [^download_file]}} <- {:rm_tar, File.rm_rf(download_file)} do
        {:ok, dest_dir}
      else
        {:exists, path, _} ->
          {:exists, path}

        {:get_file, path, _} ->
          # If the authentication doesn't work, curl will create an empty file {tag}.tar.gz
          Path.join(dest_dir_base, "#{tag}.tar.gz") |> File.rm()

          Mix.raise(
            "Could not download file: #{inspect(path)}.\nBad token? Token should start with `ghp_`"
          )

        {:sha256, [received_sha | _]} ->
          File.rm(download_file)
          Mix.raise("Downloaded file does not match SHA256: #{inspect({tag_sha, received_sha})}")

        {:rm_tar, error} ->
          {:error, {:rm_tar, error}}

        {output, error} ->
          {:error, {error, output}}

        {:rename, error} ->
          {:error, {:rename, error}}
      end

    case install_res do
      {:ok, path} ->
        Mix.shell().info("Installed KOS system to #{path}")

      {:exists, path} ->
        Mix.shell().info("KOS path already exists: #{path}")

      {:error, {:enoexists, path}} ->
        Mix.raise("KOS source directory does not exist: #{path}")

      {:error, reason} ->
        Mix.raise("Could not install KOS system: #{inspect(reason)}")
    end

    if opts_map[:default] do
      default_path = KosMix.get_path(:kos_toolchain, "default")

      case File.read_link(default_path) do
        {:ok, _} ->
          File.rm(default_path)

        _ ->
          nil
      end

      File.ln_s!(dest_dir, default_path)
      Mix.shell().info("Updated default version to #{tag}")
    end

    docker_login!(token)
  end

  defp docker_login!(token) do
    docker = System.find_executable("docker")

    unless docker do
      Mix.raise("Could not find docker. Is `docker` installed?")
    end

    use_sudo = docker_needs_sudo?(docker)

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
      "#{sudo_args} #{docker} --config #{kos_home}/.docker login -u kosuser -p #{token} ghcr.io"
    ]

    case System.cmd(nix_shell, args, stderr_to_stdout: true) do
      {_output, 0} ->
        :ok

      {_, exit_status} ->
        Mix.raise("Failed to authenticate. Exit status: #{exit_status}")
    end
  end

  defp docker_needs_sudo?(docker) do
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

  @switches [
    tag: :string,
    token: :string,
    default: :boolean
  ]
  @aliases [t: :tag, d: :default]

  defp process_args_and_env(args) do
    # get args
    {opts, left, inv} = OptionParser.parse(args, strict: @switches, aliases: @aliases)

    token = Keyword.get(opts, :token)
    tag = Keyword.get(opts, :tag, @default_tar_version)

    default =
      Keyword.get(opts, :default, !File.exists?(KosMix.get_path(:kos_toolchain, "default")))

    %{
      token: token,
      tag: tag,
      default: default,
      remaining_args: left,
      invalid_args: inv
    }
  end

  defp validate_opts(opts_map) do
    case opts_map do
      %{token: nil} ->
        Mix.raise("Missing required argument token")

      %{invalid_args: inv} when inv != [] ->
        Mix.raise("Unexpected arguments: #{inspect(inv)}")

      %{remaining_args: left} when left != [] ->
        Mix.raise("Unexpected arguments: #{inspect(left)}")

      _ ->
        nil
    end
  end
end
