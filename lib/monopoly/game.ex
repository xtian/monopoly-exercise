defmodule Monopoly.Game do
  @moduledoc """
  Game logic for simplified version of Monopoly

  Limitations:
    - No way to get out of jail
    - Building houses/hotels not implemented
    - Chance/Community Chest not implemented
    - Income tax/Luxury tax not implemented
    - Mortgaging properties not implemented
  """

  @min_players Application.compile_env(:monopoly, :min_players, 2)
  @max_players Application.compile_env(:monopoly, :max_players, 8)
  @starting_money Application.compile_env(:monopoly, :starting_money, 1500)

  @spaces {:go, {:purple, 60, 2}, :community_chest, {:purple, 60, 4}, :income_tax,
           {:railroad, 100}, {:light_blue, 100, 6}, :chance, {:light_blue, 100, 6},
           {:light_blue, 120, 8}, :visiting_jail, {:pink, 140, 10}, {:utility, 150},
           {:pink, 140, 10}, {:pink, 150, 12}, {:railroad, 200}, {:orange, 180, 14},
           :community_chest, {:orange, 180, 14}, {:orange, 200, 16}, :free_parking,
           {:red, 220, 18}, :chance, {:red, 220, 18}, {:red, 240, 20}, {:railroad, 100},
           {:yellow, 260, 22}, {:utility, 150}, {:yellow, 260, 22}, {:yellow, 280, 24},
           :go_to_jail, {:green, 300, 26}, {:green, 300, 26}, :community_chest, {:green, 320, 28},
           {:railroad, 200}, :chance, {:dark_blue, 350, 35}, :luxury_tax, {:dark_blue, 400, 50}}

  @spaces_range 0..(tuple_size(@spaces) - 1)
  @railroads Enum.filter(@spaces_range, &match?({:railroad, _}, elem(@spaces, &1)))
  @utilities Enum.filter(@spaces_range, &match?({:utility, _}, elem(@spaces, &1)))

  @special_spaces Enum.filter(@spaces_range, &(@spaces |> elem(&1) |> is_atom()))
  @ownership Map.new(Enum.to_list(@spaces_range) -- @special_spaces, &{&1, nil})

  @jail -1

  require Logger

  defguardp active?(game, player_id) when elem(game.players, game.active_player) == player_id

  def new(player_ids) do
    with {_, true} <- {:duplicate_players, player_ids == Enum.uniq(player_ids)},
         {_, true} <- {:invalid_player_count, length(player_ids) in @min_players..@max_players} do
      players_list = Enum.shuffle(player_ids)
      players = List.to_tuple(players_list)

      {:ok, hd(players_list),
       %{
         active_player: 0,
         balances: Map.new(0..(tuple_size(players) - 1), &{&1, @starting_money}),
         game_over: false,
         ownership: @ownership,
         players: players,
         players_list: players_list,
         positions: Map.new(0..(tuple_size(players) - 1), &{&1, 0}),
         turn_started: false
       }}
    else
      {reason, _} -> {:error, reason}
    end
  end

  def start_turn(game, player_id) when not active?(game, player_id), do: {:error, :not_turn}
  def start_turn(%{game_over: true}, _), do: {:error, :game_over}
  def start_turn(%{turn_started: true}, _), do: {:error, :already_started}

  def start_turn(game, _) when :erlang.map_get(game.active_player, game.positions) == @jail do
    {:ok, game}
  end

  def start_turn(game, _) do
    %{
      active_player: active_player,
      balances: balances,
      ownership: ownership,
      positions: positions
    } = game

    dice_roll = :rand.uniform(6) + :rand.uniform(6)
    old_position = Map.fetch!(positions, active_player)
    new_position = Integer.mod(old_position + dice_roll, tuple_size(@spaces))

    game = %{
      game
      | positions: Map.put(positions, active_player, new_position),
        turn_started: true
    }

    game =
      if new_position < old_position do
        # Player passed "GO"
        %{game | balances: Map.update!(balances, active_player, &(&1 + 200))}
      else
        game
      end

    case {elem(@spaces, new_position), Map.get(ownership, new_position)} do
      {:go_to_jail, _} ->
        {:ok, %{game | positions: Map.put(positions, active_player, @jail)}}

      {space, _} when is_atom(space) ->
        Logger.warning("Special spaces not implemented")
        {:ok, game}

      {_, owner} when owner == nil or owner == active_player ->
        {:ok, game}

      {{:railroad, _}, owner} ->
        rent =
          case @railroads |> filter_map(&(Map.fetch!(ownership, &1) == owner)) |> length() do
            1 -> 25
            2 -> 50
            3 -> 100
            4 -> 200
          end

        {:ok, charge_rent(game, rent, owner)}

      {{:utility, _}, owner} ->
        rent =
          if @utilities |> filter_map(&(Map.fetch!(ownership, &1) == owner)) |> length() == 2 do
            dice_roll * 10
          else
            dice_roll * 4
          end

        {:ok, charge_rent(game, rent, owner)}

      {{_, _, rent}, owner} ->
        {:ok, charge_rent(game, rent, owner)}
    end
  end

  def buy_property(game, player_id) when not active?(game, player_id), do: {:error, :not_turn}
  def buy_property(%{game_over: true}, _), do: {:error, :game_over}
  def buy_property(%{turn_started: false}, _), do: {:error, :turn_not_started}

  def buy_property(game, _) do
    %{
      active_player: active_player,
      balances: balances,
      ownership: ownership,
      positions: positions
    } = game

    position = Map.fetch!(positions, active_player)

    with {:ok, nil} <- Map.fetch(ownership, position),
         price = @spaces |> elem(position) |> elem(1),
         balance = Map.fetch!(balances, active_player),
         true <- price <= balance do
      balances = Map.put(balances, active_player, balance - price)
      ownership = %{ownership | position => active_player}

      {:ok, %{game | balances: balances, ownership: ownership}}
    else
      false -> {:error, :not_enough_money}
      {:ok, ^active_player} -> {:error, :already_purchased}
      {:ok, _} -> {:error, :owned}
      :error -> {:error, :not_purchaseable}
    end
  end

  def end_turn(game, player_id) when not active?(game, player_id), do: {:error, :not_turn}
  def end_turn(%{game_over: true}, _), do: {:error, :game_over}
  def end_turn(%{turn_started: false}, _), do: {:error, :turn_not_started}

  def end_turn(game, _) do
    active_player = Integer.mod(game.active_player + 1, tuple_size(game.players))

    {:ok, elem(game.players, active_player),
     %{game | active_player: active_player, turn_started: false}}
  end

  def end_game(game, player_id) when not active?(game, player_id), do: {:error, :not_turn}
  def end_game(%{game_over: true}, _), do: {:error, :already_ended}

  def end_game(game, _) do
    {position, positions} = Map.pop!(game.positions, game.active_player)

    if position != @jail and positions |> Map.values() |> Enum.all?(&(&1 == @jail)) do
      {:ok, %{game | game_over: true}}
    else
      {:error, :win_condition_unmet}
    end
  end

  defp charge_rent(game, rent, owner) do
    %{active_player: active_player, balances: balances, positions: positions} = game
    %{^active_player => balance, ^owner => owner_balance} = balances

    new_balance = balance - rent
    new_owner_balance = owner_balance + rent
    balances = %{balances | active_player => new_balance, owner => new_owner_balance}

    # Send player to jail if rent puts them into bankruptcy
    positions =
      if new_balance < 0, do: Map.put(positions, active_player, @jail), else: positions

    positions =
      if new_owner_balance > 0 and Map.fetch!(positions, owner) == @jail do
        # Take owner out of jail if someone lands on their property and they are not bankrupt
        Map.put(positions, owner, 0)
      else
        positions
      end

    %{game | balances: balances, positions: positions}
  end

  defp filter_map(list, fun) do
    :lists.filtermap(fun, list)
  end
end
