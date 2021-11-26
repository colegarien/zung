defmodule Zung.State.Game.Game do
  require Logger
  @behaviour Zung.State.State

  def run(%Zung.Client{game_state: %Zung.Client.GameState{}} = client, _) do
    # TODO add a sleep here?
    do_game(client) |> run(%{})
  end
  def run(%Zung.Client{} = client, data) do
    # Convert simple state data into GameData struct
    game_state = %Zung.Client.GameState{ username: data[:username], room_id: data[:room_id] }
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
      case Zung.Game.Parser.parse(new_client, input) do
        {:move, {:direction, direction}} ->
          case Zung.Game.Room.move(Zung.Game.Room.get_room(new_client.game_state.room_id), direction) do
            {:ok, new_room_id} -> %Zung.Client{new_client | game_state: %Zung.Client.GameState{new_client.game_state | room_id: new_room_id}}
            {:error, error_message} -> Zung.Client.push_output(new_client, error_message)
          end
        {:look, {:room, room_id}} -> Zung.Client.push_output(new_client, Zung.Game.Room.describe(Zung.Game.Room.get_room(room_id)))
        :quit -> raise Zung.Error.Connection.Closed
        _ -> Zung.Client.push_output(new_client, "||GRN||Wut?||RESET||")
      end
    else
      new_client
    end
  end

end
