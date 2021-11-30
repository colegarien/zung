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

    finalize_user(data)
    Zung.Client.authenticate_as(client, data[:username])

    # wait for user to hit Enter
    Zung.Client.raw_read(client)
    {Zung.State.Game.Init, client, %{username: data[:username], room_id: "newbie/room_1"}}
  end

  defp finalize_user(data) do
    Zung.Client.User.create_user(data[:username],data[:password], %{
      use_ansi?: data[:use_ansi?],
    })
    # TODO eventually add other things like, class, gender, subclasses, etc?
    Zung.DataStore.update_current_room_id(data[:username], "newbie/room_1")
  end
end
