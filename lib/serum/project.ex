defmodule Serum.Project do
  @moduledoc false

  _moduledocp = """
  Defines functions internally used by Serum to create and manipulate
  `Serum.V2.Project` structs.
  """

  import Serum.V2.Console, only: [put_err: 2]
  alias Serum.V2.Project
  alias Serum.V2.Project.BlogConfiguration

  @spec default_date_format() :: binary()
  def default_date_format, do: "{YYYY}-{0M}-{0D}"

  @spec default_list_title_tag() :: binary()
  def default_list_title_tag, do: "Posts Tagged ~s"

  @spec new(map) :: Project.t()
  def new(map) do
    struct(Project, put_blog_config(map))
  end

  @spec put_blog_config(map()) :: map()
  defp put_blog_config(map)

  defp put_blog_config(%{blogs: %{} = blog_config} = map) do
    %{map | blogs: struct(BlogConfiguration, check_list_title_tag(blog_config))}
  end

  defp put_blog_config(%{blogs: false} = map), do: map
  defp put_blog_config(map), do: map

  @spec check_list_title_tag(map) :: map
  defp check_list_title_tag(map) do
    case map[:list_title_tag] do
      nil ->
        map

      fmt when is_binary(fmt) ->
        :io_lib.format(fmt, ["test"])
        map
    end
  rescue
    ArgumentError ->
      msg = """
      Invalid post list title format string `list_title_tag`.
      The default format string will be used instead.
      """

      put_err(:warn, String.trim(msg))
      Map.delete(map, :list_title_tag)
  end
end
