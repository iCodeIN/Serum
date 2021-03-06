defimpl Serum.Fragment.Source, for: Serum.V2.PostList do
  require Serum.V2.Result, as: Result
  alias Serum.Renderer
  alias Serum.Template.Storage, as: TS
  alias Serum.V2
  alias Serum.V2.Fragment
  alias Serum.V2.PostList

  @spec to_fragment(PostList.t()) :: Result.t(Fragment.t())
  def to_fragment(post_list) do
    Result.run do
      template <- TS.get("list", :template)
      html <- Renderer.render_fragment(template, page: post_list)

      Serum.Fragment.new(%V2.File{}, post_list.dest, post_list, html)
    end
  end
end
