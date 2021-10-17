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
  Enter 'new' to create a new user
--------------------------------------------------------------------------------
"""

  @impl Zung.State.State
  def run(%Zung.Client{} = client, data) do
    logged_in_count = String.pad_leading("#{Zung.Client.Session.get_session_count}", 3, "0")
    Zung.Client.write_data(client, String.replace(@the_banner, "000", logged_in_count))
    handle_intro(client, data)
  end

  defp handle_intro(%Zung.Client{} = client, data) do
    login_action = prompt_login(client)

    case login_action do
      {:ok, :new} ->
        {Zung.State.Login.UserCreation, client, %{}}
      {:ok, username} ->
        {Zung.State.Login.UserLogin, client, %{username: username}}
      {:error, message} ->
        Zung.Client.write_line(client, message)
        handle_intro(client, data)
    end
  end

  defp prompt_login(%Zung.Client{} = client) do
    Zung.Client.write_data(client, "Enter your username: ")
    with data <- Zung.Client.read_line(client),
          {:ok, username} <- validate_username(data),
          do: if username == "new", do: {:ok, :new}, else: {:ok, username}
  end

  defp validate_username(dirty_username) do
    trimmed_dirt = dirty_username
      |> String.downcase
      |> String.trim

    cond do
      trimmed_dirt === "new" -> {:ok, "new"} # new user request!
      not String.match?(trimmed_dirt, ~r/^[a-z][a-z0-9\_]{2,11}$/) -> {:error, "Invalid username. Please try again."}
      not Zung.DataStore.user_exists?(trimmed_dirt) -> {:error, "User does not exist. Please try again."}
      true -> {:ok, trimmed_dirt}
    end
  end
end
