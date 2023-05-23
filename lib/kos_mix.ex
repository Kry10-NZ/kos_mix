# Copyright (c) 2022, Kry10 Limited. All rights reserved.
#
# SPDX-License-Identifier: LicenseRef-Kry10

defmodule KosMix do
  @moduledoc false
  # This is an internal module with helper functions for the mix tasks
  # defined in this project.

  def get_path(:kos_home) do
    System.get_env("KOS_HOME", Path.expand("~/.kos"))
  end

  def get_path(:kos_toolchain_base) do
    Path.join([get_path(:kos_home), "toolchains"])
  end

  def get_path(:kos_toolchain, tag) do
    Path.join(get_path(:kos_toolchain_base), "kos-#{tag}")
  end

  def get_default_toolchain() do
    default = get_path(:kos_toolchain, "default")
    System.get_env("KOS_TOOLCHAIN", default)
  end

  def create_dir(dir) do
    with false <- File.exists?(dir),
         :ok <- File.mkdir_p(dir) do
      {:ok, dir}
    else
      true -> {:exists, dir}
      {:error, reason} -> {:error, reason}
    end
  end

  def supported_platforms do
    [
      "am335x",
      "qemu-arm-virt",
      "imx8mm-evk",
      "x86_64",
      "nitrogen6sx",
      "rpi4"
    ]
  end

  def supported_platform(platform) do
    Enum.member?(supported_platforms(), platform)
  end

  def check_deps() do
    case Mix.Task.run("kos.deps.check", ["--quiet"]) do
      :ok ->
        :ok

      :error ->
        """
        Missing KOS toolchain dependencies.

        Run 'mix kos.deps.check' to check for missing prerequisite dependencies.
        """
        |> Mix.raise()
    end
  end
end
