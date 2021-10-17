defmodule Zung.State.Login.UserLogin do
  @behaviour Zung.State.State

  @impl Zung.State.State
  def run(%Zung.Client{} = client, data) do
    handle_login(client, data[:username])
  end

  defp handle_login(client, username, attempt\\0, max_attempts\\3)
  defp handle_login(_client, _username, attempt, max_attempts) when attempt == max_attempts do
    raise Zung.Error.SecurityConcern, message: "Exceeded max attempts!", show_client: true
  end
  defp handle_login(%Zung.Client{} = client, username, attempt, max_attempts) do
    Zung.Client.write_data(client, "||YEL||Password (#{attempt + 1}/#{max_attempts})||RESET||: ||ECHO_OFF||")
    user_password = Zung.Client.read_line(client)
    Zung.Client.write_data(client, "||ECHO_ON||||NL||")

    if Zung.DataStore.password_matches?(username, user_password) do
      Zung.Client.authenticate_as(client, username)
      {Zung.State.Game.Main, client, %{username: username}} # TODO can probably switch back to not allowing "client" to be overridden by state for no reason
    else
      Zung.Client.write_line(client, "||RED||Incorrect Password.||RESET||")
      handle_login(client, username, attempt + 1, max_attempts)
    end
  end

end
