defmodule Serum.DevServer do
  @moduledoc """
  The Serum development server.
  """

  require Serum.V2.Result, as: Result
  alias Serum.DevServer.Logger
  alias Serum.DevServer.Service
  alias Serum.Project.Loader, as: ProjectLoader
  alias Serum.V2.Project

  @doc """
  Starts the Serum development server.

  This function returns `{:ok, pid}` on success where `pid` is a process ID of
  a supervision tree for the Serum development server.
  """
  @spec run(binary, pos_integer) :: Result.t(pid())
  def run(dir, port) do
    uniq = Base.url_encode64(:crypto.strong_rand_bytes(6))
    site = Path.expand("serum_" <> uniq, System.tmp_dir!())

    with {:ok, %Project{} = proj} <- ProjectLoader.load(dir),
         {:ok, pid} when is_pid(pid) <- do_run(dir, site, port, proj) do
      {:ok, pid}
    else
      {:error, {:shutdown, {:failed_to_start_child, _, :eaddrinuse}}} ->
        Result.fail(
          "could not start the Serum development server. " <>
            "Make sure the port #{port} is not used by other applications"
        )

      {:error, {:shutdown, reason}} when not is_list(reason) ->
        Result.fail("could not start the Serum development server: #{inspect(reason)}")

      {:error, _} = error ->
        error
    end
  end

  @spec do_run(binary(), binary(), integer(), Project.t()) :: Supervisor.on_start()
  defp do_run(dir, site, port, %Project{} = proj) do
    trap_exit = Process.flag(:trap_exit, true)

    ms_options = [
      port: port,
      base: proj.base_url.path,
      callbacks: [Logger],
      index: true,
      gen_server_options: [name: Serum.Microscope],
      route_overrides: [
        {"/serum_live_reloader", Serum.DevServer.LiveReloadHandler, nil},
        {"/[...]", Serum.DevServer.Handler, nil}
      ]
    ]

    children = [
      {Service.GenServer, {dir, site, port}},
      %{
        id: Microscope,
        start: {Microscope, :start_link, [site, ms_options]}
      }
    ]

    sup_opts = [strategy: :one_for_one, name: Serum.DevServer.Supervisor]
    start_result = Supervisor.start_link(children, sup_opts)

    Process.flag(:trap_exit, trap_exit)

    start_result
  end
end
