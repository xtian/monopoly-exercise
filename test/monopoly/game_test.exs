defmodule Monopoly.GameTest do
  use ExUnit.Case

  alias Monopoly.Game

  test "can play game" do
    assert {:ok, first_player, game} = Game.new([Monopoly.new_id(), Monopoly.new_id()])

    assert {:ok, game} = Game.start_turn(game, first_player)
    assert {:ok, next_player, game} = Game.end_turn(game, first_player)

    assert {:ok, game} = Game.start_turn(game, next_player)
    assert {:ok, ^first_player, _} = Game.end_turn(game, next_player)
  end
end
