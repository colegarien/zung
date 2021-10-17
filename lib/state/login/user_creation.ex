defmodule Zung.State.Login.UserCreation do
  @behaviour Zung.State.State

  @new_player_welcome ~S"""
--------------------------------------------------------------------------------
Welcome to Zung! First you need to pick an username.
Decribe rest of creation process here!
--------------------------------------------------------------------------------
"""

  @impl Zung.State.State
  def run(%Zung.Client{} = client, data) do
    Zung.Client.clear_screen(client)
    Zung.Client.write_line(client, @new_player_welcome)
    {Zung.State.Login.Creation.Username, client, data}
  end

end
