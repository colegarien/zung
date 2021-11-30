defmodule Zung.State.Game.Init do
  require Logger
  @behaviour Zung.State.State

  def run(%Zung.Client{} = client, data) do
    # Convert simple state data into GameData struct
    game_state = %Zung.Client.GameState{ username: data[:username], room: Zung.Game.Room.get_room(data[:room_id]) }

    # MOTD and welcome!
    init_client = %Zung.Client{client | game_state: game_state}
      |> Zung.Client.push_output("||NL||||YEL||Welcome #{game_state.username}!||RESET||")
      |> Zung.Client.push_output(Zung.Game.Room.describe(game_state.room))
      |> Zung.Client.flush_output

    # Jump into the actual Game
    {Zung.State.Game.Game, init_client, %{}}
  end
end
