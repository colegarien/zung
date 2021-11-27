defmodule Zung.Game.Parser do

  def parse(%Zung.Client{} = client, input) do
    {command, _arguments} = tokenize(client, input) |> split
    case command do
      "north" -> {:move, {:direction, :north}}
      "south" -> {:move, {:direction, :south}}
      "east" -> {:move, {:direction, :east}}
      "west" -> {:move, {:direction, :west}}
      "look" -> {:look, {:room, client.game_state.room}}
      "quit" -> :quit
      _ -> :unknown_command
    end
  end

  defp tokenize(%Zung.Client{} = _client, input) do
    input
      |> String.trim
  end

  defp split(""), do: {nil, []}
  defp split(data) do
    case String.split(data) do
      [command] -> {command, []}
      [command | arguments] -> {command, arguments}
    end
  end
end
