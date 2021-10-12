defmodule Zung.State.Login.Creation.AccountName do
  @behaviour Zung.State.State

  @impl Zung.State.State
  def run(%Zung.Client{} = client, data) do
    handle_account_name(client, data)
  end

  defp handle_account_name(%Zung.Client{} = client, data) do
    account_name_action = prompt_account_name(client)

    case account_name_action do
      {:ok, account_name} ->
        {Zung.State.Login.Creation.AccountPassword, client, Map.put(data, :account_name, account_name)}
      {:error, message} ->
        Zung.Client.write_line(client, message)
        handle_account_name(client, data)
    end
  end

  defp prompt_account_name(client) do
    Zung.Client.write_data(client, "Enter your new account name (\"a-z\" and \"_\" allowed, 3-12 length): ")
    with data <- Zung.Client.read_line(client),
          {:ok, account_name} <- validate_account_name(data),
          do: {:ok, account_name}
  end

  defp validate_account_name(dirty_account_name) do # TODO this is identical-ish to the one in intro, should clean this uuuuuuup
    trimmed_dirt = dirty_account_name
      |> String.downcase
      |> String.trim

    # TODO consider disallowing more 'reserverd' words like colors, formatting, keywords, etc...
    cond do
      trimmed_dirt == "new" -> {:error, "Username cannot be 'new'."}
      not String.match?(trimmed_dirt, ~r/^[a-z][a-z0-9\_]{2,11}$/) -> {:error, "Username is invalid."}
      Zung.DataStore.account_exists?(trimmed_dirt) -> {:error, "Username already taken."}
      true -> {:ok, trimmed_dirt}
    end
  end
end
