defmodule Zung.State.Game.Main do
  @behaviour Zung.State.State

  @impl Zung.State.State
  def run(%Zung.Client{} = client, data) do
    # TODO good place for intro MOTD or brief of past happenings while away
    current_room = Zung.DataStore.get_location(data[:account_name])
    current_room.describe()


    game_loop(client, current_room)
  end

  def game_loop(%Zung.Client{} = client, current_room) do
    Zung.Client.write_data(client, "||NL||||RESET||> ")
    {status, action} =
      with data <- Zung.Client.read_line(client),
          {:ok, command} <- Zung.Game.Command.parse(data),
          do: Zung.Game.Command.run(command)

    # TODO this be weird, refactor command pattern above!
    # TODO need to actually update DataStore with where the player is!
    if(status == :move) do
      move_action = current_room.move(action)
      case move_action do
        {:ok, new_room} -> game_loop(client, new_room)
        {:error, reason} ->
          Zung.Client.write_line(client, reason)
          game_loop(client, current_room)
      end
    else
      case {status, action} do
        {:ok, output} -> Zung.Client.write_line(client, output)
        {:look, :room} -> Zung.Client.write_data(client, current_room.describe())
        {:error, :unknown_command} -> Zung.Client.write_line(client, "||GRN||Wut?||RESET||")
      end
      game_loop(client, current_room)
    end
  end
end
