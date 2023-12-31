defmodule Monopoly.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Monopoly.GameState
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Monopoly.Supervisor)
  end
end
