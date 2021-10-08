defmodule Zung.State.Login.Creation.AccountPassword do
  @behaviour Zung.State.State

  @impl Zung.State.State
  def run(%Zung.Client{} = client, data) do
    Zung.Client.write_data(client, "||ECHO_OFF||");
    account_password_action = prompt_account_password(client)
    Zung.Client.write_data(client, "||ECHO_ON||||NL||");

    case account_password_action do
      {:ok, account_password} ->
        {Zung.State.Login.Creation.Finalize, Map.put(data, :account_password, account_password)} # TODO encrypt/salt/pepper that sucker!
      {:error, :bad_password} ->
        Zung.Client.write_line(client, "Password is invalid.")
        {__MODULE__, data}
      {:error, :do_not_match} ->
        Zung.Client.write_line(client, "Entries do not match.")
        {__MODULE__, data}
    end
  end

  defp prompt_account_password(client) do
    Zung.Client.write_data(client, "||YEL||Enter password ||BLU||(\"a-z\", \"A-Z\", \"0-9\", \"!@#$%^&*()_\" allowed, 8-32 length)||RESET||: ")
    with data <- Zung.Client.read_line(client),
          {:ok, account_password} <- validate_account_password(data),
          {:ok, account_password} <- verify_with_reentry(client, account_password),
          do: {:ok, account_password}
  end

  defp verify_with_reentry(client, account_password) do
    Zung.Client.write_data(client, "||NL||||YEL||Re-enter password||RESET||: ")
    with data <- Zung.Client.read_line(client),
          {:ok, other_account_password} <- validate_account_password(data),
          do: if other_account_password === account_password, do: {:ok, account_password}, else: {:error, :do_not_match}
  end

  defp validate_account_password(dirty_account_password) do # TODO this is identical-ish to the one in intro, should clean this uuuuuuup
    trimmed_dirt = dirty_account_password
      |> String.trim

    cond do
      not String.match?(trimmed_dirt, ~r/^[a-zA-Z0-9\!\@\#\$\%\^\&\*\(\)\_]{8,32}$/) -> {:error, :bad_password}
      true -> {:ok, trimmed_dirt}
    end
  end
end
