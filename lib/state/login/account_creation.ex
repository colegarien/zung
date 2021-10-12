defmodule Zung.State.Login.AccountCreation do
  @behaviour Zung.State.State

  @new_player_welcome ~S"""
--------------------------------------------------------------------------------
Welcome to Zung! First you need to pick an account name.
Decribe rest of creation process here!
--------------------------------------------------------------------------------
"""

  @impl Zung.State.State
  def run(%Zung.Client{} = client, state_data) do
    Zung.Client.clear_screen(client)
    Zung.Client.write_line(client, @new_player_welcome)
    {Zung.State.Login.Creation.AccountName, state_data}
  end

end
