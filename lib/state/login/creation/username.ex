defmodule Zung.State.Login.Creation.Username do
  @behaviour Zung.State.State

  @impl Zung.State.State
  def run(%Zung.Client{} = client, data) do
    handle_username(client, data)
  end

  defp handle_username(%Zung.Client{} = client, data) do
    username_action = prompt_username(client)

    case username_action do
      {:ok, username} ->
        {Zung.State.Login.Creation.Password, client, Map.put(data, :username, username)}
      {:error, message} ->
        Zung.Client.write_line(client, message)
        handle_username(client, data)
    end
  end

  defp prompt_username(client) do
    Zung.Client.write_data(client, "Enter your new username (\"a-z\" and \"_\" allowed, 3-12 length): ")
    with data <- Zung.Client.read_line(client),
          {:ok, username} <- validate_username(data),
          do: {:ok, username}
  end

  defp validate_username(dirty_username) do # TODO this is identical-ish to the one in intro, should clean this uuuuuuup
    trimmed_dirt = dirty_username
      |> String.downcase
      |> String.trim

    # TODO consider disallowing more 'reserverd' words like colors, formatting, keywords, etc...
    cond do
      trimmed_dirt == "new" -> {:error, "Username cannot be 'new'."}
      not String.match?(trimmed_dirt, ~r/^[a-z][a-z0-9\_]{2,11}$/) -> {:error, "Username is invalid."}
      not Zung.Client.User.username_available?(trimmed_dirt) -> {:error, "Username already taken."}
      true -> {:ok, trimmed_dirt}
    end
  end
end
