defmodule Zung.State.Login.AccountLogin do
  @behaviour Zung.State.State

  @impl Zung.State.State
  def run(%Zung.Client{} = client, data) do
    handle_login(client, data[:account_name])
  end

  defp handle_login(client, account_name, attempt\\0, max_attempts\\3)
  defp handle_login(_client, _account_name, attempt, max_attempts) when attempt == max_attempts do
    raise Zung.Error.SecurityConcern, message: "Exceeded max attempts!", show_client: true
  end
  defp handle_login(%Zung.Client{} = client, account_name, attempt, max_attempts) do
    Zung.Client.write_data(client, "||YEL||Enter Password (#{attempt + 1}/#{max_attempts})||RESET||: ||ECHO_OFF||")
    account_password = Zung.Client.read_line(client)
    Zung.Client.write_data(client, "||ECHO_ON||||NL||")

    if Zung.DataStore.password_matches?(account_name, account_password) do
      Zung.Client.write_line(client, "||YEL||Welcome #{String.trim(account_name)}! ||RESET||")
      {Zung.State.Game, %{account_name: account_name}}
    else
      Zung.Client.write_line(client, "||RED||Incorrect Password.||RESET||")
      handle_login(client, account_name, attempt + 1, max_attempts)
    end
  end

end
