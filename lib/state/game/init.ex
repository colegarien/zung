defmodule Zung.State.Game.Init do
  require Logger
  @behaviour Zung.State.State

  def run(%Zung.Client{} = client, %{username: username}) do
    # auth, init game state, and welcome
    new_client = Zung.Client.authenticate_as(client, username)
      |> Map.put(:game_state, build_game_state(username))
      |> subscribe_to_channels
      |> output_welcome

    {Zung.State.Game.Game, new_client, %{}}
  end

  defp build_game_state(username) do
    start_room = Zung.DataStore.get_current_room_id(username) |> Zung.Game.Room.get_room
    %Zung.Client.GameState {
      username: username,
      room: start_room
    }
  end

  defp subscribe_to_channels(client) do
    client
      |> Zung.Client.subscribe("ooc")
  end

  defp output_welcome(client) do
    client
      |> Zung.Client.push_output("||NL||||YEL||Welcome #{client.game_state.username}!||RESET||")
      |> Zung.Client.push_output(Zung.Game.Room.describe(client.game_state.room))
      |> Zung.Client.flush_output
  end
end
