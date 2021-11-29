defmodule Zung.State.Game.Game do
  require Logger
  @behaviour Zung.State.State

  def run(%Zung.Client{} = client, data) do
    # Convert simple state data into GameData struct
    game_state = %Zung.Client.GameState{ username: data[:username], room: Zung.Game.Room.get_room(data[:room_id]) }

    # MOTD and welcome!
    Zung.Client.push_output(client, "||NL||||YEL||Welcome #{game_state.username}!||RESET||")
    Zung.Client.push_output(client, Zung.Game.Room.describe(game_state.room))

    run(%Zung.Client{client | game_state: game_state}, %{})
  end
  def run(%Zung.Client{game_state: %Zung.Client.GameState{}} = client, _) do
    # TODO add a sleep here?
    do_game(client) |> run(%{})
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
          case Zung.Game.Room.move(new_client.game_state.room, direction) do
            {:ok, new_room} -> %Zung.Client{new_client | game_state: %Zung.Client.GameState{new_client.game_state | room: new_room}}
            {:error, error_message} -> Zung.Client.push_output(new_client, error_message)
          end
        {:look, room} -> Zung.Client.push_output(new_client, Zung.Game.Room.describe(room))
        {:look, room, target} -> Zung.Client.push_output(new_client, Zung.Game.Room.look_at(room, target))
        {:csay, channel, message} -> Zung.Client.publish(new_client, channel, message)
        :quit -> raise Zung.Error.Connection.Closed
        {:bad_parse, message} -> Zung.Client.push_output(new_client, "||RED||#{message}||RESET||")
        _ -> Zung.Client.push_output(new_client, "||GRN||Wut?||RESET||")
      end
    else
      new_client
    end
  end

end
