defmodule Zung.State.Game.Init do
  require Logger
  @behaviour Zung.State.State

  def run(%Zung.Client{} = client, %{username: username}) do
    # auth, init game state, and welcome
    new_client = Zung.Client.authenticate_as(client, username)
      |> Map.put(:game_state, build_game_state(username))
      |> join_default_chat_rooms
      |> place_in_world

    {Zung.State.Game.Game, new_client, %{}}
  end

  defp build_game_state(username) do
    start_room = Zung.DataStore.get_current_room_id(username) |> Zung.Game.Room.get_room
    %Zung.Client.GameState {
      username: username,
      room: start_room
    }
  end

  defp join_default_chat_rooms(client) do
    client
      |> Zung.Client.join_chat("ooc")
  end

  defp place_in_world(client) do
    client
      |> Zung.Client.push_output("||NL||||YEL||Welcome #{client.game_state.username}!||RESET||")
      |> Zung.Client.enter_room(client.game_state.room)
      |> Zung.Client.flush_output
  end
end
