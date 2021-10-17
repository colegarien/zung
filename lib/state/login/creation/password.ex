defmodule Zung.State.Login.Creation.Password do
  @behaviour Zung.State.State

  @user_password_banner ~S"""
Welcome to Zung, username.
Something something a few questions to create your character,
you will be plopped directly into the game after.

"""

  @impl Zung.State.State
  def run(%Zung.Client{} = client, data) do
    Zung.Client.clear_screen(client)
    Zung.Client.write_data(client, String.replace(@user_password_banner, "username", data[:username]));
    handle_user_password(client, data)
  end

  defp handle_user_password(%Zung.Client{} = client, data) do
    Zung.Client.write_data(client, "||ECHO_OFF||");
    user_password_action = prompt_user_password(client)
    Zung.Client.write_data(client, "||ECHO_ON||||NL||");

    case user_password_action do
      {:ok, user_password} ->
        {Zung.State.Login.Creation.ColorCheck, client, Map.put(data, :user_password, user_password)} # TODO encrypt/salt/pepper that sucker!
      {:error, message} ->
        Zung.Client.write_line(client, message)
        handle_user_password(client, data)
    end
  end

  defp prompt_user_password(client) do
    Zung.Client.write_data(client, "Enter password (\"a-z\", \"A-Z\", \"0-9\", \"!@#$%^&*()_\" allowed, 8-32 length): ")
    with data <- Zung.Client.read_line(client),
          {:ok, user_password} <- validate_user_password(data),
          {:ok, user_password} <- verify_with_reentry(client, user_password),
          do: {:ok, user_password}
  end

  defp verify_with_reentry(client, user_password) do
    Zung.Client.write_data(client, "||NL||Please re-enter password: ")
    with data <- Zung.Client.read_line(client),
          {:ok, other_user_password} <- validate_user_password(data),
          do: if other_user_password === user_password, do: {:ok, user_password}, else: {:error, "Entries do not match."}
  end

  defp validate_user_password(dirty_user_password) do # TODO this is identical-ish to the one in intro, should clean this uuuuuuup
    trimmed_dirt = dirty_user_password
      |> String.trim

    cond do
      not String.match?(trimmed_dirt, ~r/^[a-zA-Z0-9\!\@\#\$\%\^\&\*\(\)\_]{8,32}$/) -> {:error, "Password is invalid."}
      true -> {:ok, trimmed_dirt}
    end
  end
end
