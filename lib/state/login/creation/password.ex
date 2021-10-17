defmodule Zung.State.Login.Creation.Password do
  @behaviour Zung.State.State

  @password_banner ~S"""
Welcome to Zung, username.
Something something a few questions to create your character,
you will be plopped directly into the game after.

"""

  @impl Zung.State.State
  def run(%Zung.Client{} = client, data) do
    Zung.Client.clear_screen(client)
    Zung.Client.write_data(client, String.replace(@password_banner, "username", data[:username]));
    handle_password(client, data)
  end

  defp handle_password(%Zung.Client{} = client, data) do
    Zung.Client.write_data(client, "||ECHO_OFF||");
    password_action = prompt_password(client)
    Zung.Client.write_data(client, "||ECHO_ON||||NL||");

    case password_action do
      {:ok, password} ->
        {Zung.State.Login.Creation.ColorCheck, client, Map.put(data, :password, Zung.Client.User.hash_password(data[:username], password))}
      {:error, message} ->
        Zung.Client.write_line(client, message)
        handle_password(client, data)
    end
  end

  defp prompt_password(client) do
    Zung.Client.write_data(client, "Enter password (\"a-z\", \"A-Z\", \"0-9\", \"!@#$%^&*()_\" allowed, 8-32 length): ")
    with data <- Zung.Client.read_line(client),
          {:ok, password} <- validate_password(data),
          {:ok, password} <- verify_with_reentry(client, password),
          do: {:ok, password}
  end

  defp verify_with_reentry(client, password) do
    Zung.Client.write_data(client, "||NL||Please re-enter password: ")
    with data <- Zung.Client.read_line(client),
          {:ok, other_password} <- validate_password(data),
          do: if other_password === password, do: {:ok, password}, else: {:error, "Entries do not match."}
  end

  defp validate_password(dirty_password) do # TODO this is identical-ish to the one in intro, should clean this uuuuuuup
    trimmed_dirt = dirty_password
      |> String.trim

    cond do
      not String.match?(trimmed_dirt, ~r/^[a-zA-Z0-9\!\@\#\$\%\^\&\*\(\)\_]{8,32}$/) -> {:error, "Password is invalid."}
      true -> {:ok, trimmed_dirt}
    end
  end
end
