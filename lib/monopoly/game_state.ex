defmodule Monopoly.GameState do
  use GenServer

  alias Monopoly.Game

  @table_name :game_state

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def init(_arg) do
    {:ok, PersistentEts.new(@table_name, "game_state.tab", [:named_table, :set])}
  end

  def new_game(player_ids) do
    GenServer.call(__MODULE__, {:new_game, player_ids})
  end

  def get_game(tid \\ @table_name, game_id) do
    case :ets.lookup(tid, game_id) do
      [{_, game}] -> {:ok, game}
      [] -> {:error, :not_found}
    end
  end

  def start_turn(game_id, player_id) do
    GenServer.call(__MODULE__, {:start_turn, game_id, player_id})
  end

  def buy_property(game_id, player_id) do
    GenServer.call(__MODULE__, {:buy_property, game_id, player_id})
  end

  def end_turn(game_id, player_id) do
    GenServer.call(__MODULE__, {:end_turn, game_id, player_id})
  end

  def end_game(game_id, player_id) do
    GenServer.call(__MODULE__, {:end_game, game_id, player_id})
  end

  def handle_call({:new_game, player_ids}, _from, tid) do
    result =
      with {:ok, first_player, game} <- Game.new(player_ids) do
        game_id = Monopoly.new_id()
        :ets.insert(tid, {game_id, game})

        {:ok, first_player, game_id}
      end

    {:reply, result, tid}
  end

  def handle_call({:start_turn, game_id, player_id}, _from, tid) do
    result =
      with {:ok, game} <- get_game(tid, game_id),
           {:ok, game} = result <- Game.start_turn(game, player_id) do
        :ets.insert(tid, {game_id, game})
        result
      end

    {:reply, result, tid}
  end

  def handle_call({:buy_property, game_id, player_id}, _from, tid) do
    result =
      with {:ok, game} <- get_game(tid, game_id),
           {:ok, game} = result <- Game.buy_property(game, player_id) do
        :ets.insert(tid, {game_id, game})
        result
      end

    {:reply, result, tid}
  end

  def handle_call({:end_turn, game_id, player_id}, _from, tid) do
    result =
      with {:ok, game} <- get_game(tid, game_id),
           {:ok, _, game} = result <- Game.end_turn(game, player_id) do
        :ets.insert(tid, {game_id, game})
        result
      end

    {:reply, result, tid}
  end

  def handle_call({:end_game, game_id, player_id}, _from, tid) do
    result =
      with {:ok, game} <- get_game(tid, game_id),
           {:ok, game} = result <- Game.end_game(game, player_id) do
        :ets.insert(tid, {game_id, game})
        result
      end

    {:reply, result, tid}
  end
end
