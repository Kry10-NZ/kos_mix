# Copyright (c) 2022, Kry10 Limited. All rights reserved.
#
# SPDX-License-Identifier: LicenseRef-Kry10

defmodule Mix.Tasks.Kos do
  use Mix.Task

  @shortdoc "Prints Kos help information"

  @moduledoc """
  Prints Kos tasks and their information.
      $ mix kos
  """

  @impl true
  @doc false
  def run(args) do
    case args do
      [] -> general()
      _ -> Mix.raise("Invalid arguments, expected: mix kos")
    end
  end

  defp general() do
    # Application.ensure_all_started(:kos) # ???
    # Mix.shell().info "KOS Slogan ??"
    Mix.Tasks.Help.run(["--search", "kos."])
  end
end
