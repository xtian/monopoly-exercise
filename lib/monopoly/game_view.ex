defmodule Monopoly.GameView do
  @space_names {"Go", "Mediterranean Avenue", "Community Chest", "Baltic Avenue", "Income Tax",
                "Reading Railroad", "Oriental Avenue", "Chance", "Vermont Avenue",
                "Connecticut Avenue", "Visiting Jail", "St. Charles Place", "States Avenue",
                "Electric Company", "Virginia Avenue", "Pennsylvania Railroad", "St. James Place",
                "Community Chest", "Tennessee Avenue", "New York Avenue", "Free Parking",
                "Kentucky Avenue", "Chance", "Indiana Avenue", "Illinois Avenue",
                "B & O Railroad", "Atlantic Avenue", "Ventnor Avenue", "Water Works",
                "Marvin Gardens", "Go To Jail", "Pacific Avenue", "North Carolina Avenue",
                "Community Chest", "Pennsylvania Avenue", "Short Line", "Chance", "Park Place",
                "Luxury Tax", "Boardwalk"}

  def render({:error, :already_ended}, _), do: "Error: The game has already ended\n"
  def render({:error, :already_purchased}, _), do: "Error: You already own this property\n"
  def render({:error, :already_started}, _), do: "Error: You've already started your turn\n"
  def render({:error, :duplicate_players}, _), do: "Error: Duplicate players are not allowed\n"
  def render({:error, :game_over}, _), do: "Error: The game has ended\n"
  def render({:error, :invalid_player_count}, _), do: "Error: Invalid player count\n"
  def render({:error, :turn_not_started}, _), do: "Error: You must start your turn first\n"
  def render({:error, :owned}, _), do: "Error: Someone else already owns this property\n"
  def render({:error, :not_enough_money}, _), do: "Error: You don't have enough money\n"
  def render({:error, :not_found}, _), do: "Error: Game not found\n"
  def render({:error, :not_turn}, _), do: "Error: It's not your turn\n"

  def render({:ok, game}, game_id) do
    %{
      active_player: active_player,
      balances: balances,
      game_over: game_over,
      ownership: ownership,
      players: players,
      players_list: players_list,
      positions: positions,
      turn_started: turn_started
    } = game

    status =
      cond do
        game_over -> "Game Ended"
        turn_started -> "#{elem(players, active_player)} taking their turn"
        true -> "Waiting for #{elem(players, active_player)}"
      end

    rendered_players =
      for {player, index} <- Enum.with_index(players_list), into: "" do
        owned_properties =
          ownership
          |> Enum.to_list()
          |> filter_map(fn {property, owner} ->
            if owner == index, do: {true, elem(@space_names, property)}, else: false
          end)
          |> Enum.join(", ")

        """
        [#{player}]
        Location: #{elem(@space_names, Map.fetch!(positions, index))}
        Balance: #{Map.fetch!(balances, index)}
        Owned Properties: #{owned_properties}
        """
      end

    """
    [[#{game_id}]]
    Status: #{status}

    #{rendered_players}
    """
  end

  defp filter_map(list, fun) do
    :lists.filtermap(fun, list)
  end
end
