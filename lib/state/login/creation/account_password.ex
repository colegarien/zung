defmodule Zung.State.Login.Creation.AccountPassword do
  @behaviour Zung.State.State

  @account_password_banner ~S"""
Welcome to Zung, account_name.
Something something a few questions to create your character,
you will be plopped directly into the game after.

"""

  @impl Zung.State.State
  def run(%Zung.Client{} = client, data) do
    Zung.Client.clear_screen(client)
    Zung.Client.write_data(client, String.replace(@account_password_banner, "account_name", data[:account_name]));
    handle_account_password(client, data)
  end

  defp handle_account_password(%Zung.Client{} = client, data) do
    Zung.Client.write_data(client, "||ECHO_OFF||");
    account_password_action = prompt_account_password(client)
    Zung.Client.write_data(client, "||ECHO_ON||||NL||");

    case account_password_action do
      {:ok, account_password} ->
        {Zung.State.Login.Creation.ColorCheck, Map.put(data, :account_password, account_password)} # TODO encrypt/salt/pepper that sucker!
      {:error, message} ->
        Zung.Client.write_line(client, message)
        handle_account_password(client, data)
    end
  end

  defp prompt_account_password(client) do
    Zung.Client.write_data(client, "Enter password (\"a-z\", \"A-Z\", \"0-9\", \"!@#$%^&*()_\" allowed, 8-32 length): ")
    with data <- Zung.Client.read_line(client),
          {:ok, account_password} <- validate_account_password(data),
          {:ok, account_password} <- verify_with_reentry(client, account_password),
          do: {:ok, account_password}
  end

  defp verify_with_reentry(client, account_password) do
    Zung.Client.write_data(client, "||NL||Please re-enter password: ")
    with data <- Zung.Client.read_line(client),
          {:ok, other_account_password} <- validate_account_password(data),
          do: if other_account_password === account_password, do: {:ok, account_password}, else: {:error, "Entries do not match."}
  end

  defp validate_account_password(dirty_account_password) do # TODO this is identical-ish to the one in intro, should clean this uuuuuuup
    trimmed_dirt = dirty_account_password
      |> String.trim

    cond do
      not String.match?(trimmed_dirt, ~r/^[a-zA-Z0-9\!\@\#\$\%\^\&\*\(\)\_]{8,32}$/) -> {:error, "Password is invalid."}
      true -> {:ok, trimmed_dirt}
    end
  end
end
