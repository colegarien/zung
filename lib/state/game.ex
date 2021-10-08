defmodule Zung.State.Game do
  @behaviour Zung.State.State

  @impl Zung.State.State
  def run(%Zung.Client{} = client, _data) do
    # TODO good place for intro MOTD or brief of past happenings while away
    game_loop(client)
  end

  def game_loop(client) do
    Zung.Client.write_data(client, "||NL||||RESET||> ")
    msg =
      with data <- Zung.Client.read_line(client),
          {:ok, command} <- Zung.Command.parse(data),
          do: Zung.Command.run(command)

    case msg do
      {:ok, output} -> Zung.Client.write_line(client, output)
      {:error, :unknown_command} -> Zung.Client.write_line(client, "||GRN||Wut?||RESET||")
    end

    game_loop(client)
  end
end
