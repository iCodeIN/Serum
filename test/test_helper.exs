ExUnit.start()

{:ok, _} = Application.ensure_all_started(:ex_machina)

Serum.V2.Console.config(mute_err: true, mute_msg: true)

defmodule Serum.TestHelper do
  import Mox
  alias Serum.Build.FileProcessor.Template

  @test_dir Path.join(File.cwd!(), "test_fixtures")

  defmacro fixture(arg) do
    quote(do: Path.join([unquote(@test_dir), unquote(arg)]))
  end

  def get_tmp_dir(prefix) do
    uniq = Base.url_encode64(:crypto.strong_rand_bytes(6))

    Path.expand(prefix <> uniq, System.tmp_dir!())
  end

  def make_project(target) do
    ["" | ~w(pages posts includes templates assets media files)]
    |> Enum.map(&Path.join(target, &1))
    |> Enum.each(&File.mkdir_p!/1)

    File.touch!(Path.join([target, "assets", "test_asset"]))
    File.touch!(Path.join([target, "media", "test_media"]))
    File.touch!(Path.join([target, "files", "test_file.txt"]))
    File.cp!(fixture("proj/good/serum.exs"), Path.join(target, "serum.exs"))
    File.cp!(fixture("templates/nav.html.eex"), Path.join(target, "includes/nav.html.eex"))

    ~w(base list page post)
    |> Enum.map(&["templates/", &1, ".html.eex"])
    |> Enum.each(fn file ->
      File.cp!(fixture(file), Path.join([target, file]))
    end)

    page = "pages/good-*.md" |> fixture() |> Path.wildcard() |> List.first()
    post = "posts/good-*.md" |> fixture() |> Path.wildcard() |> List.first()

    File.cp!(page, Path.join([target, "pages", Path.basename(page)]))
    File.cp!(post, Path.join([target, "posts", Path.basename(post)]))
  end

  def get_plugin_mock(callbacks \\ %{}, optional_callbacks) do
    mock =
      Serum.V2.Plugin.Mock
      |> expect(:name, callbacks[:name] || fn -> "" end)
      |> expect(:version, callbacks[:version] || fn -> "0.1.0" end)
      |> expect(:description, callbacks[:description] || fn -> "" end)
      |> expect(:implements, callbacks[:implements] || fn -> Map.keys(optional_callbacks) end)
      |> expect(:init, callbacks[:init] || fn _ -> {:ok, nil} end)
      |> expect(:cleanup, callbacks[:cleanup] || fn _ -> {:ok, {}} end)

    Enum.reduce(optional_callbacks, mock, fn {{fun_name, _arity}, code}, mock ->
      expect(mock, fun_name, code)
    end)
  end

  def get_theme_mock(callbacks \\ %{}) do
    Serum.V2.Theme.Mock
    |> expect(:name, callbacks[:name] || fn -> "" end)
    |> expect(:description, callbacks[:description] || fn -> "" end)
    |> expect(:version, callbacks[:version] || fn -> "0.1.0" end)
    |> expect(:init, callbacks[:init] || fn _ -> {:ok, nil} end)
    |> expect(:cleanup, callbacks[:cleanup] || fn _ -> {:ok, {}} end)
    |> expect(:get_includes, callbacks[:get_includes] || fn _ -> {:ok, []} end)
    |> expect(:get_templates, callbacks[:get_templates] || fn _ -> {:ok, []} end)
    |> expect(:get_assets, callbacks[:get_assets] || fn _ -> {:ok, false} end)
  end

  def load_templates(opts \\ []) do
    {:ok, _} =
      Template.compile_templates(%{
        includes: read_template_files(~w(nav), opts),
        templates: read_template_files(~w(base list page post), opts)
      })
  end

  defp read_template_files(names, opts) do
    alias Serum.V2

    names
    |> Enum.map(&fixture(Path.join("templates", "#{&1}.html.eex")))
    |> Enum.map(fn src ->
      %V2.File{src: src}
      |> V2.File.read()
      |> elem(1)
      |> Map.update!(:in_data, &break_template(&1, opts[:break]))
    end)
  end

  defp break_template(data, break?)
  defp break_template(data, true), do: data <> ~s(<%= raise "test" %>)
  defp break_template(data, _), do: data
end

defmodule Serum.Case do
  use ExUnit.CaseTemplate

  using do
    quote do
      require Serum.TestHelper
      import Mox
      import Serum.Factory
      import Serum.TestHelper
    end
  end
end
