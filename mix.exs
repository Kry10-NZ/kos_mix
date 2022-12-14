# Copyright (c) 2022, Kry10 Limited. All rights reserved.
#
# SPDX-License-Identifier: LicenseRef-Kry10

defmodule KosMix.MixProject do
  use Mix.Project

  @app :kos_mix
  @version "0.1.1"

  def project do
    [
      app: @app,
      version: @version,
      elixir: "~> 1.12",
      aliases: aliases()
    ]
  end

  def application do
    [
      extra_applications: [:eex]
    ]
  end

  def aliases do
    [
      kos_install: &kos_install/1,
      kos_build: &kos_build/1,
      kos_uninstall: "archive.uninstall #{Atom.to_string(@app)}-#{@version}"
    ]
  end

  def kos_install(_) do
    Mix.env(:prod)
    Mix.Task.run("archive.build", ["--include-dot-files"])
    Mix.Task.run("archive.install")
  end

  def kos_build(_) do
    Mix.env(:prod)
    Mix.Task.run("archive.build", ["--include-dot-files"])
  end
end
