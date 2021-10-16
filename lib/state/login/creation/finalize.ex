defmodule Zung.State.Login.Creation.Finalize do
  @behaviour Zung.State.State

  @finalize_message ~S"""

||BOLD||||RED||-----------------------------------------------------------------------------||RESET||
     ||GRN||Congratulations account_name||RESET||, you have now completed
character creation. You will be dropped in the newbie area. Describe newbie
area benefits and such here.

                Enjoy your adventures, and welcome to Zung!
||BOLD||||RED||-----------------------------------------------------------------------------||RESET||

[ Press enter to continue ]||RESET||
"""

  @impl Zung.State.State
  def run(%Zung.Client{} = client, data) do
    Zung.Client.clear_screen(client)
    Zung.Client.write_data(client, String.replace(@finalize_message, "account_name", data[:account_name]));
    Zung.Session.authenticate_session(client.session_id, data[:account_name])

    finalize_user(data)

    # wait for user to hit Enter
    Zung.Client.read_line(client)
    {Zung.State.Game.Main, client, %{account_name: data[:account_name]}}
  end

  defp finalize_user(data) do
    # TODO eventually add other things like, class, gender, subclasses, etc?
    new_user = %{
      account_name: data[:account_name],
      password: data[:account_password],
      use_ansi?: data[:use_ansi?],
    }
    Zung.DataStore.add_user(new_user)
    Zung.DataStore.update_current_room_id(data[:account_name], "newbie/room_1")
  end
end
