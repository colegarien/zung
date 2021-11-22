defmodule Zung.State.Game.Game do
  require Logger
  @behaviour Zung.State.State

  def run(%Zung.Client{game_state: %Zung.Client.GameState{}} = client, _) do
    # TODO add a sleep here?
    do_game(client) |> run(%{})
  end
  def run(%Zung.Client{} = client, data) do
    # Convert simple state data into GameData struct
    game_state = %Zung.Client.GameState{ username: data[:username] }
    run(%Zung.Client{client | game_state: game_state}, %{})
  end


  def do_game(%Zung.Client{} = client) do
    client
      |> process_input
      |> Zung.Client.flush_output
  end

  defp process_input(%Zung.Client{} = client) do
    {new_client, input} = Zung.Client.pop_input(client)
    if input !== nil do
      Zung.Client.push_output(new_client, "||GRN||Wut?||RESET||")
    else
      new_client
    end
  end

end
