defmodule Zung.State.Login.Creation.Finalize do
  @behaviour Zung.State.State

  @finalize_message ~S"""

||BOLD||||RED||-----------------------------------------------------------------------------||RESET||
     ||GRN||Congratulations username||RESET||, you have now completed
character creation. You will be dropped in the newbie area. Describe newbie
area benefits and such here.

                Enjoy your adventures, and welcome to Zung!
||BOLD||||RED||-----------------------------------------------------------------------------||RESET||

[ Press enter to continue ]||RESET||
"""

  @impl Zung.State.State
  def run(%Zung.Client{} = client, data) do
    Zung.Client.raw_clear_screen(client)
    Zung.Client.raw_write(client, String.replace(@finalize_message, "username", data[:username]));

    # finalize and wait for user input
    finalize_user(data)
    Zung.Client.raw_read(client)

    {Zung.State.Game.Init, client, %{username: data[:username]}}
  end

  defp finalize_user(%{username: username, password: password, use_ansi?: use_ansi?}) do
    Zung.Client.User.create_user(username, password, %{ use_ansi?: use_ansi?, })
    Zung.DataStore.update_current_room_id(username, "newbie/room_1")
  end
end
