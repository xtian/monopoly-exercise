# Monopoly

## Usage

Start the console using `bin/start`. Then:

```
iex> {:ok, first_player, game_id} = Monopoly.new_game([1, 2])
iex> Monopoly.start_turn(game_id, first_player)
iex> Monopoly.buy_property(game_id, first_player)
iex> {:ok, next_player} = Monopoly.end_turn(game_id, first_player)
```
