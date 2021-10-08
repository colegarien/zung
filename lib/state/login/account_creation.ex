defmodule Zung.State.Login.AccountCreation do
  @behaviour Zung.State.State

  @impl Zung.State.State
  def run(%Zung.Client{} = client, state_data) do
    Zung.Client.write_line(client, "||NL||||YEL||Welcome to Zung!||NL||||RESET||")
    {Zung.State.Login.Creation.AccountName, state_data}
  end

end
