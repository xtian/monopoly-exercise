defmodule Monopoly do
  alias Monopoly.{GameState, GameView}

  def new_game(player_ids) do
    GameState.new_game(player_ids)
  end

  def start_turn(game_id, player_id) do
    game_id |> GameState.start_turn(player_id) |> render(game_id)
  end

  def buy_property(game_id, player_id) do
    game_id |> GameState.buy_property(player_id) |> render(game_id)
  end

  def end_turn(game_id, player_id) do
    game_id |> GameState.end_turn(player_id) |> render(game_id)
  end

  def end_game(game_id, player_id) do
    game_id |> GameState.end_game(player_id) |> render(game_id)
  end

  def new_id do
    System.unique_integer([:positive])
  end

  def render_game(game_id) do
    game_id |> GameState.get_game() |> render(game_id)
  end

  defp render(game, game_id) do
    game |> GameView.render(game_id) |> IO.write()
  end
end
