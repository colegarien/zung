defmodule Zung.State.Game.Game do
  require Logger
  @behaviour Zung.State.State

  def run(%Zung.Client{} = client, _) do
    do_game(client) |> run(%{})
  end


  def do_game(%Zung.Client{} = client) do
    client
      |> process_events
      |> process_input
      |> Zung.Client.flush_output
  end

  defp process_events(%Zung.Client{} = client) do
    client
  end

  defp process_input(%Zung.Client{} = client) do
    {new_client, input} = Zung.Client.pop_input(client)
    if input !== nil do
      case Zung.Game.Parser.parse(new_client, input) do
        {:move, target} ->
          case Zung.Game.Room.move(new_client.game_state.room, target) do
            {:ok, new_room} ->
              new_client
                |> Zung.Client.leave_room(client.game_state.room)
                |> Zung.Client.enter_room(new_room)
            {:error, error_message} -> Zung.Client.push_output(new_client, error_message)
          end
        {:look, room} -> Zung.Client.push_output(new_client, Zung.Game.Room.describe(room))
        {:look, room, target} -> Zung.Client.push_output(new_client, Zung.Game.Room.look_at(room, target))
        {:say, room, message} -> Zung.Client.say_to_room(new_client, room.id, message)
        {:csay, chat_room, message} -> Zung.Client.publish_to_chat(new_client, chat_room, message)
        :quit -> raise Zung.Error.Connection.Closed
        {:bad_parse, message} -> Zung.Client.push_output(new_client, "||RED||#{message}||RESET||")
        _ -> Zung.Client.push_output(new_client, "||GRN||Wut?||RESET||")
      end
    else
      new_client
    end
  end

end
