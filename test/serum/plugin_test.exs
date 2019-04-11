defmodule Serum.PluginTest do
  use ExUnit.Case, async: false
  import Serum.Plugin
  alias Serum.File
  alias Serum.Fragment
  alias Serum.Page
  alias Serum.Post
  alias Serum.PostList
  alias Serum.Template

  priv_dir = :serum |> :code.priv_dir() |> IO.iodata_to_binary()

  1..3
  |> Enum.map(&Path.join(priv_dir, "test_plugins/dummy_plugin_#{&1}.ex"))
  |> Enum.each(&Code.require_file/1)

  test "load_plugins/1" do
    {:ok, loaded_plugins} =
      load_plugins([Serum.DummyPlugin1, Serum.DummyPlugin2, Serum.DummyPlugin3])

    assert length(loaded_plugins) == 3

    agent_state = Agent.get(Serum.Plugin, & &1)

    count =
      Enum.reduce(agent_state, 0, fn {_, plugins}, acc ->
        acc + length(plugins)
      end)

    assert count == 27

    Agent.update(Serum.Plugin, fn _ -> %{} end)
  end

  test "callback test" do
    {:ok, _} = load_plugins([Serum.DummyPlugin1, Serum.DummyPlugin2, Serum.DummyPlugin3])

    assert :ok = build_started("/path/to/src", "/path/to/dest")
    assert {:ok, _} = reading_pages(["a", "b", "c"])
    assert {:ok, _} = reading_posts(["a", "b", "c"])
    assert {:ok, _} = reading_templates(["a", "b", "c"])
    assert {:ok, _} = processing_page(%File{src: "page.md"})
    assert {:ok, _} = processing_post(%File{src: "post.md"})
    assert {:ok, _} = processing_template(%File{src: "template.html.eex"})
    assert {:ok, _} = processed_page(%Page{title: "Test Page"})
    assert {:ok, _} = processed_post(%Post{title: "Test Post"})
    assert {:ok, _} = processed_template(%Template{file: "template.html.eex"})
    assert {:ok, _} = processed_list(%PostList{title: "Test Post List"})
    assert {:ok, _} = rendered_fragment(%Fragment{output: "test.html"})
    assert {:ok, _} = rendered_page(%File{dest: "test.html"})
    assert :ok = wrote_file(%File{dest: "test.html"})
    assert :ok = build_succeeded("/src", "/dest")
    assert :ok = build_failed("/src", "/dest", {:error, "sample error"})
    assert :ok = finalizing("/src", "/dest")

    Agent.update(Serum.Plugin, fn _ -> %{} end)
  end
end