defmodule Zung.State.Login.UserLogin do
  @behaviour Zung.State.State

  @impl Zung.State.State
  def run(%Zung.Client{} = client, data) do
    handle_login(client, data[:username])
  end

  defp handle_login(client, username, attempt \\ 0, max_attempts \\ 3)

  defp handle_login(_client, _username, attempt, max_attempts) when attempt == max_attempts do
    raise Zung.Error.SecurityConcern, message: "Exceeded max attempts!", show_client: true
  end

  defp handle_login(%Zung.Client{} = client, username, attempt, max_attempts) do
    Zung.Client.raw_write(
      client,
      "||YEL||Password (#{attempt + 1}/#{max_attempts})||RESET||: ||ECHO_OFF||"
    )

    password = Zung.Client.User.hash_password(username, Zung.Client.raw_read(client))
    Zung.Client.raw_write(client, "||ECHO_ON||||NL||")

    if Zung.Client.User.password_matches?(username, password) do
      {Zung.State.Game.Init, client, %{username: username}}
    else
      Zung.Client.raw_write_line(client, "||RED||Incorrect Password.||RESET||")
      handle_login(client, username, attempt + 1, max_attempts)
    end
  end
end
