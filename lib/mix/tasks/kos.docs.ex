# Copyright (c) 2022, Kry10 Limited. All rights reserved.
#
# SPDX-License-Identifier: LicenseRef-Kry10

defmodule Mix.Tasks.Kos.Docs do
  use Mix.Task

  @shortdoc "Load the Kry10 documentation"
  @moduledoc """
  #{@shortdoc}

    $ mix kos.docs

  This will build a copy of the KOS system documentation and place it in the
  `docs` folder in the KOS_HOME directory.

  After building, the documentation will be opened in the default web browser of
  the current user. If this fails, a URL will be output so that the
  documentation can be opened manually.

  """

  @impl true
  @doc false
  def run(_) do
    KosMix.check_deps()

    default = KosMix.get_default_toolchain()

    unless File.exists?(default) do
      Mix.raise(
        "Could not find KOS installation. You must install KOS first (eg `mix kos.install --token <token> --default`)"
      )
    end

    doc_index =
      if File.exists?(Path.join([default, "docs", "index.html"])) do
        Path.join([default, "docs", "index.html"])
      else
        out_path = Path.join(KosMix.get_path(:kos_home), "docs")

        nix_build = System.find_executable("nix-build")

        unless nix_build do
          Mix.raise("Could not find nix-build. Is `nix` installed?")
        end

        path = Path.join(default, "default.nix")

        unless File.regular?(path) do
          Mix.raise(
            "Could not find kos install at: " <> default <> "\nThe installation may be corrupted"
          )
        end

        case File.read_link(out_path) do
          {:ok, _} ->
            File.rm(out_path)

          _ ->
            nil
        end

        {_, 0} = System.cmd(nix_build, ["-A", "docs", "-o", out_path, path], into: IO.stream())

        Path.join(out_path, "/share/html/index.html")
      end

    """

    Attempting to open the documentation webpage in a browser window.

    If this fails, then the webpage can be manually loaded at:
    file://#{doc_index}
    """
    |> Mix.shell().info()

    cond do
      System.find_executable("open") ->
        open("open", doc_index)

      System.find_executable("xdg-open") ->
        open("xdg-open", doc_index)

      true ->
        """
        Unable to open documentation in browser window

        """
        |> Mix.shell().error()
    end
  end

  defp open(command, doc_index) do
    Task.start(fn ->
      {_, 0} = System.cmd(command, ~w(#{doc_index}))
    end)

    :timer.sleep(1000)
  end
end
