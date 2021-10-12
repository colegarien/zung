defmodule Zung.State.Login.AccountCreation do
  @behaviour Zung.State.State

  @new_player_welcome ~S"""
--------------------------------------------------------------------------------
Welcome to Zung! First you need to pick an account name.
Decribe rest of creation process here!
--------------------------------------------------------------------------------
"""

  @impl Zung.State.State
  def run(%Zung.Client{} = client, data) do
    Zung.Client.clear_screen(client)
    Zung.Client.write_line(client, @new_player_welcome)
    {Zung.State.Login.Creation.AccountName, client, data}
  end

end
