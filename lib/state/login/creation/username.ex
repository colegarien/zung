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
        Zung.Client.raw_write_line(client, message)
        handle_username(client, data)
    end
  end

  defp prompt_username(client) do
    Zung.Client.raw_write(
      client,
      "Enter your new username (\"a-z\" and \"_\" allowed, 3-12 length): "
    )

    with data <- Zung.Client.raw_read(client),
         {:ok, username} <- validate_username(data),
         do: {:ok, username}
  end

  defp validate_username(dirty_username) do
    dirty_username
    |> String.downcase()
    |> String.trim()
    |> Zung.Client.User.validate_username_format()
  end
end
