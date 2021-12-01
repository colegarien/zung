defmodule Zung.State.Login.Creation.Password do
  @behaviour Zung.State.State

  @password_banner ~S"""
Welcome to Zung, username.
Something something a few questions to create your character,
you will be plopped directly into the game after.

"""

  @impl Zung.State.State
  def run(%Zung.Client{} = client, data) do
    Zung.Client.raw_clear_screen(client)
    Zung.Client.raw_write(client, String.replace(@password_banner, "username", data[:username]));
    handle_password(client, data)
  end

  defp handle_password(%Zung.Client{} = client, data) do
    Zung.Client.raw_write(client, "||ECHO_OFF||");
    password_action = prompt_password(client)
    Zung.Client.raw_write(client, "||ECHO_ON||||NL||");

    case password_action do
      {:ok, password} ->
        {Zung.State.Login.Creation.ColorCheck, client, Map.put(data, :password, Zung.Client.User.hash_password(data[:username], password))}
      {:error, message} ->
        Zung.Client.raw_write_line(client, message)
        handle_password(client, data)
    end
  end

  defp prompt_password(client) do
    Zung.Client.raw_write(client, "Enter password (\"a-z\", \"A-Z\", \"0-9\", \"!@#$%^&*()_\" allowed, 8-32 length): ")
    with data <- Zung.Client.raw_read(client),
          {:ok, password} <- validate_password(data),
          {:ok, password} <- verify_with_reentry(client, password),
          do: {:ok, password}
  end

  defp verify_with_reentry(client, password) do
    Zung.Client.raw_write(client, "||NL||Please re-enter password: ")
    with data <- Zung.Client.raw_read(client),
          {:ok, other_password} <- validate_password(data),
          do: if other_password === password, do: {:ok, password}, else: {:error, "Entries do not match."}
  end

  defp validate_password(dirty_password) do
    dirty_password
      |> String.trim
      |> Zung.Client.User.validate_password_format
  end
end
