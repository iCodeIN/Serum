defmodule Serum.Build.FileLoader.Includes do
  @moduledoc false

  _moduledocp = """
  A module for loading includes from a project or a theme.
  """

  import Serum.Build.FileLoader.Common
  import Serum.V2.Console, only: [put_msg: 2]
  alias Serum.Plugin.Client, as: PluginClient
  alias Serum.Theme.Client, as: ThemeClient
  alias Serum.V2
  alias Serum.V2.Error
  alias Serum.V2.Result

  @doc false
  @spec load(binary()) :: Result.t([V2.File.t()])
  def load(src) do
    put_msg(:info, "Loading includes...")

    case ThemeClient.get_includes() do
      {:ok, paths} ->
        paths
        |> Map.merge(get_project_includes(src))
        |> Enum.map(&elem(&1, 1))
        |> PluginClient.reading_templates()
        |> case do
          {:ok, files} -> read_files(files)
          {:error, %Error{}} = plugin_error -> plugin_error
        end

      {:error, %Error{}} = error ->
        error
    end
  end

  @spec get_project_includes(binary()) :: map()
  defp get_project_includes(src) do
    includes_dir = get_subdir(src, "includes")

    if File.exists?(includes_dir) do
      includes_dir
      |> Path.join("*.html.eex")
      |> Path.wildcard()
      |> Enum.map(&{Path.basename(&1, ".html.eex"), &1})
      |> Map.new()
    else
      %{}
    end
  end
end
