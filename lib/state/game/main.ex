defmodule Zung.State.Game.Main do
  require Logger
  @behaviour Zung.State.State

  @impl Zung.State.State
  def run(%Zung.Client{} = client, data) do
    # TODO good place for intro MOTD or brief of past happenings while away
    Zung.Client.write_line(client, "||NL||||YEL||Welcome #{String.trim(data[:username])}!||RESET||")
    current_room = Zung.DataStore.get_room(Zung.DataStore.get_current_room_id(data[:username]))
    Zung.Client.write_data(client, Zung.Game.Room.describe(current_room))

    game_loop(client, data[:username], current_room)
  end

  def game_loop(%Zung.Client{} = client, username, current_room) do
    Zung.Client.write_data(client, "||NL||||RESET||> ")
    {status, action} =
      with data <- Zung.Client.read_line(client),
          {:ok, command} <- Zung.Game.Command.parse(username, data),
          do: Zung.Game.Command.run(command)

    # TODO this be weird, refactor command pattern above!
    if(status == :move) do
      move_action = Zung.Game.Room.move(current_room, action)
      case move_action do
        {:ok, new_room_id} ->
          new_room = Zung.DataStore.get_room(new_room_id)
          Zung.DataStore.update_current_room_id(username, new_room.id)
          Zung.Client.write_data(client, Zung.Game.Room.describe(new_room))

          game_loop(client, username, new_room)
        {:error, reason} ->
          Zung.Client.write_line(client, reason)
          game_loop(client, username, current_room)
      end
    else
      case {status, action} do
        {:ok, output} -> Zung.Client.write_line(client, output)
        {:look, :room} -> Zung.Client.write_data(client, Zung.Game.Room.describe(current_room))
        {:look, target} -> Zung.Client.write_line(client, Zung.Game.Room.look(current_room, target))
        {:publish, {channel, message}} -> Zung.Client.publish(client, channel, message)
        {:error, :unknown_command} -> Zung.Client.write_line(client, "||GRN||Wut?||RESET||")
      end
      game_loop(client, username, current_room)
    end
  end
end
