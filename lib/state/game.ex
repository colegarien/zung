defmodule Zung.State.Game do
  @behaviour Zung.State.State

  @impl Zung.State.State
  def run(%Zung.Client{} = client, data) do
    Zung.Client.write_data(client, "||NL||||RESET||> ")
    msg =
      with data <- Zung.Client.read_line(client),
          {:ok, command} <- Zung.Command.parse(data),
          do: Zung.Command.run(command)

    case msg do
      {:ok, output} -> Zung.Client.write_line(client, output)
      {:error, :unknown_command} -> Zung.Client.write_line(client, "||GRN||Wut?||RESET||")
    end
    {__MODULE__, data}
  end
end
