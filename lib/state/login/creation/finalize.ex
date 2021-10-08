defmodule Zung.State.Login.Creation.Finalize do
  @behaviour Zung.State.State

  @impl Zung.State.State
  def run(%Zung.Client{} = client, data) do
    new_user = %{
      account_name: data[:account_name],
      password: data[:account_password],
    }
    Zung.DataStore.add_user(new_user)
    Zung.Client.write_data(client, "||NL||||GRN||Success!||RESET||||NL||||NL||");
    {Zung.State.Login.Introduction, %{}}
  end
end
