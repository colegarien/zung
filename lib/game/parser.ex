defmodule Zung.Game.Parser do

  def parse(%Zung.Client{} = client, input) do
    {command, _arguments} = split_input(input)
    case command do
      "north" -> {:move, {:direction, :north}}
      "south" -> {:move, {:direction, :south}}
      "east" -> {:move, {:direction, :east}}
      "west" -> {:move, {:direction, :west}}
      "look" -> {:look, {:room, client.game_state.room_id}}
      _ -> :unknown_command
    end
  end

  defp split_input(""), do: {nil, []}
  defp split_input(input) do
    case String.split(input) do
      [command] -> {command, []}
      [command | arguments] -> {command, arguments}
    end
  end
end
