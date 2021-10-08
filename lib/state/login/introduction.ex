defmodule Zung.State.Login.Introduction do
  @behaviour Zung.State.State

  @impl Zung.State.State
  @spec run(%Zung.Client{}, any) ::
          {Zung.State.Login.AccountCreation, %{}}
          | {Zung.State.Login.AccountLogin, %{account_name: binary}}
          | {Zung.State.Login.Introduction, any}
  def run(%Zung.Client{} = client, data) do
    login_action = prompt_login(client)

    case login_action do
      {:ok, :new} ->
        {Zung.State.Login.AccountCreation, %{}}
      {:ok, account_name} ->
        {Zung.State.Login.AccountLogin, %{account_name: account_name}}
      {:error, :bad_username} ->
        Zung.Client.write_line(client, "Invalid username.")
        {__MODULE__, data}
      {:error, :missing_user} ->
        Zung.Client.write_line(client, "User does not exist.")
        {__MODULE__, data}
    end
  end

  defp prompt_login(%Zung.Client{} = client) do
    Zung.Client.write_data(client, "||YEL||Enter your account name or \"new\" to create a new account||RESET||: ")
    with data <- Zung.Client.read_line(client),
          {:ok, account_name} <- validate_account_name(data),
          do: if account_name == "new", do: {:ok, :new}, else: {:ok, account_name}
  end

  defp validate_account_name(dirty_account_name) do
    trimmed_dirt = dirty_account_name
      |> String.downcase
      |> String.trim

    cond do
      trimmed_dirt === "new" -> {:ok, "new"} # new user request!
      not String.match?(trimmed_dirt, ~r/^[a-z][a-z0-9\_]{2,11}$/) -> {:error, :bad_username}
      not Zung.DataStore.account_exists?(trimmed_dirt) -> {:error, :missing_user}
      true -> {:ok, trimmed_dirt}
    end
  end

end
