defimpl Serum.Fragment.Source, for: Serum.V2.Post do
  require Serum.V2.Result, as: Result
  alias Serum.Renderer
  alias Serum.Template.Storage, as: TS
  alias Serum.V2.Fragment
  alias Serum.V2.Post

  @spec to_fragment(Post.t()) :: Result.t(Fragment.t())
  def to_fragment(post) do
    template_name = post.template || "post"
    bindings = [page: post, contents: post.data]

    Result.run do
      template <- TS.get(template_name, :template)
      html <- Renderer.render_fragment(template, bindings)

      Serum.Fragment.new(post.source, post.dest, post, html)
    end
  end
end
