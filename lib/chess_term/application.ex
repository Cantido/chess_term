defmodule ChessTerm.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    runtime_opts = [
      app: ChessTerm,
      shutdown: {:application, :chess_term}
    ]

    children = [
      {Ratatouille.Runtime.Supervisor, runtime: runtime_opts},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ChessTerm.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def stop(_state) do
    # Do a hard shutdown after the application has been stopped.
    #
    # Another, perhaps better, option is `System.stop/0`, but this results in a
    # rather annoying lag when quitting the terminal application.
    System.halt()
  end
end
