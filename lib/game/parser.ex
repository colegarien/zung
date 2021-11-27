defmodule Zung.Game.Parser do

  def parse(%Zung.Client{} = client, input) do
    {command, arguments} = input |> split
    case command do
      "north" -> {:move, {:direction, :north}}
      "south" -> {:move, {:direction, :south}}
      "east" -> {:move, {:direction, :east}}
      "west" -> {:move, {:direction, :west}}
      "look" -> parse_look(client, arguments)
      "quit" -> :quit
      _ -> :unknown_command
    end
  end

  defp parse_look(%Zung.Client{} = client, arguments) do
    current_room = client.game_state.room
    case arguments do
      # look/0
      [] -> {:look, current_room}
      # look/1
      _ -> {:look, current_room, parse_look_target(current_room, arguments)}
    end
  end

  defp parse_look_target(%Zung.Game.Room{} = room, arguments) do
    argument = join_arguments(arguments)
    if(argument in ["north", "south", "east", "west"]) do
      {:direction, String.to_atom(argument)}
    else
      flavor = Enum.find(room.flavor_texts, %{id: "", text: ""}, &(argument === &1.id or argument in &1.keywords))
      {:flavor, flavor.id}
    end
  end

  defp split(""), do: {nil, []}
  defp split(data) do
    case String.split(data) do
      [command] -> {command, []}
      [command | arguments] -> {command, arguments}
    end
  end

  defp join_arguments(arguments) do
    arguments
      |> Enum.reduce("", &("#{&2} #{&1}"))
      |> String.downcase
      |> String.trim
  end
end
