defmodule Zung.State.Login.Intro do
  @behaviour Zung.State.State

  @the_banner ~S"""
________________________________________________________________________________
________________________________________________________________________________
__/\\\\\\\\\\\\\\\__/\\\________/\\\__/\\\\\_____/\\\_____/\\\\\\\\\\\\_________
__\////////////\\\__\/\\\_______\/\\\_\/\\\\\\___\/\\\___/\\\//////////_________
_____________/\\\/___\/\\\_______\/\\\_\/\\\/\\\__\/\\\__/\\\___________________
____________/\\\/_____\/\\\_______\/\\\_\/\\\//\\\_\/\\\_\/\\\____/\\\\\\\______
___________/\\\/_______\/\\\_______\/\\\_\/\\\\//\\\\/\\\_\/\\\___\/////\\\_____
__________/\\\/_________\/\\\_______\/\\\_\/\\\_\//\\\/\\\_\/\\\_______\/\\\____
_________/\\\/___________\//\\\______/\\\__\/\\\__\//\\\\\\_\/\\\_______\/\\\___
_________/\\\\\\\\\\\\\\\__\///\\\\\\\\\/___\/\\\___\//\\\\\_\//\\\\\\\\\\\\/___
_________\///////////////_____\/////////_____\///_____\/////___\////////////____
________________________________________________________________________________
__[                             ]______________[                             ]__
__[    -- Welcome to Zung --    ]______________[      More filler here,      ]__
__[     Players Online: 000     ]______________[        and this too.        ]__
__[                             ]______________[                             ]__
--------------------------------------------------------------------------------
  Enter 'new' to create a new account
--------------------------------------------------------------------------------
"""

  @impl Zung.State.State
  def run(%Zung.Client{} = client, data) do
    # TODO replace 000 with padded logged in player counts (do after separating a "session" store)
    Zung.Client.write_data(client, @the_banner)
    handle_intro(client, data)
  end

  defp handle_intro(%Zung.Client{} = client, data) do
    login_action = prompt_login(client)

    case login_action do
      {:ok, :new} ->
        {Zung.State.Login.AccountCreation, client, %{}}
      {:ok, account_name} ->
        {Zung.State.Login.AccountLogin, client, %{account_name: account_name}}
      {:error, message} ->
        Zung.Client.write_line(client, message)
        handle_intro(client, data)
    end
  end

  defp prompt_login(%Zung.Client{} = client) do
    Zung.Client.write_data(client, "Enter your account name: ")
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
      not String.match?(trimmed_dirt, ~r/^[a-z][a-z0-9\_]{2,11}$/) -> {:error, "Invalid username. Please try again."}
      not Zung.DataStore.account_exists?(trimmed_dirt) -> {:error, "User does not exist. Please try again."}
      true -> {:ok, trimmed_dirt}
    end
  end
end
