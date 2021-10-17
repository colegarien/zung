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
    Zung.Client.clear_screen(client)
    Zung.Client.write_data(client, String.replace(@finalize_message, "username", data[:username]));

    finalize_user(data)
    Zung.Client.authenticate_as(client, data[:username])

    # wait for user to hit Enter
    Zung.Client.read_line(client)
    {Zung.State.Game.Main, client, %{username: data[:username]}}
  end

  defp finalize_user(data) do
    # TODO eventually add other things like, class, gender, subclasses, etc?
    new_user = %{
      username: data[:username],
      password: data[:user_password],
      use_ansi?: data[:use_ansi?],
    }
    Zung.DataStore.add_user(new_user)
    Zung.DataStore.update_current_room_id(data[:username], "newbie/room_1")
  end
end
