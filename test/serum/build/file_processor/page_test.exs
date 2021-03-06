defmodule Serum.Build.FileProcessor.PageTest do
  use Serum.Case
  require Serum.TestHelper
  import Serum.Build.FileProcessor.Page
  alias Serum.Project.Loader, as: ProjectLoader
  alias Serum.Template
  alias Serum.Template.Storage, as: TS
  alias Serum.V2
  alias Serum.V2.BuildContext
  alias Serum.V2.Error
  alias Serum.V2.Page

  setup_all do
    source_dir = fixture("proj/good/")
    dest_dir = "/path/to/dest/"
    {:ok, proj} = ProjectLoader.load(source_dir)
    context = %BuildContext{project: proj, source_dir: source_dir, dest_dir: dest_dir}
    template = Template.new("Hello, world!", "test", :template, "test.html.eex")

    TS.load(%{"test" => template}, :include)
    on_exit(fn -> TS.reset() end)

    {:ok, [context: context]}
  end

  describe "preprocess_pages/2 and process_posts/2" do
    test "preprocesses markdown files", %{context: context} do
      file = read("pages/good-md.md")
      {:ok, preprocessed_pages} = preprocess_pages([file], context)
      {:ok, [page]} = process_pages(preprocessed_pages, context)

      assert %Page{
               title: "Test Markdown Page",
               label: "test-md",
               group: "test",
               order: 1,
               type: "md"
             } = page

      assert String.ends_with?(page.dest, ".html")
      assert page.data =~ "Hello, world!"
    end

    test "preprocesses HTML-EEx files", %{context: context} do
      file = read("pages/good-html.html.eex")
      {:ok, preprocessed_pages} = preprocess_pages([file], context)
      {:ok, [page]} = process_pages(preprocessed_pages, context)

      assert %Page{
               title: "Test HTML-EEx Page",
               label: "test-eex",
               group: "test",
               order: 3,
               type: "html"
             } = page

      assert String.ends_with?(page.dest, ".html")
      assert page.data =~ "Hello, world!"
    end

    test "fallbacks to the default label", %{context: context} do
      file = %V2.File{src: fixture("pages/good-minimal-header.md")}
      {:ok, file} = V2.File.read(file)
      {:ok, [page]} = preprocess_pages([file], context)

      assert String.ends_with?(page.dest, ".html")
      assert page.label === "Test Page"
    end

    test "fails on pages with bad headers", %{context: context} do
      files =
        fixture("pages")
        |> Path.join("bad-*.md")
        |> Path.wildcard()
        |> Enum.map(&%V2.File{src: &1})
        |> Enum.map(&V2.File.read/1)
        |> Enum.map(fn {:ok, file} -> file end)

      {:error, %Error{caused_by: errors}} = preprocess_pages(files, context)

      assert length(errors) === length(files)
    end

    test "fails on bad EEx pages", %{context: context} do
      files =
        fixture("pages")
        |> Path.join("bad-*.html.eex")
        |> Path.wildcard()
        |> Enum.map(&%V2.File{src: &1})
        |> Enum.map(&V2.File.read/1)
        |> Enum.map(fn {:ok, file} -> file end)

      {:ok, pages} = preprocess_pages(files, context)
      {:error, %Error{caused_by: errors}} = process_pages(pages, context)

      assert length(errors) === length(files)
    end
  end

  defp read(path) do
    file = %V2.File{src: fixture(path)}
    {:ok, file} = V2.File.read(file)

    file
  end
end
