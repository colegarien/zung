defmodule Zung.Game.Parser do
  require Logger

  # TODO ideas for commands -> https://github.com/sneezymud/dikumud/blob/master/lib/help_table
  # TODO cool alias section -> https://github.com/Yuffster/CircleMUD/blob/master/lib/text/help/commands.hlp
  # TODO nice website -> https://dslmud.fandom.com/wiki/Commands
  # TODO neat thing about room/area building -> http://www.forgottenkingdoms.org/builders/blessons.php

  def parse(%Zung.Client{} = client, input) do
    {command, arguments} = input |> apply_aliases(client) |> split
    case command do
      "north" -> {:move, {:direction, :north}}
      "south" -> {:move, {:direction, :south}}
      "east" -> {:move, {:direction, :east}}
      "west" -> {:move, {:direction, :west}}
      "up" -> {:move, {:direction, :up}}
      "down" -> {:move, {:direction, :down}}
      "look" -> parse_look(client, arguments)
      "csay" -> parse_csay(client, arguments)
      "enter" -> parse_enter(client, arguments)
      "quit" -> :quit
      _ -> :unknown_command
    end
  end

  defp parse_look(%Zung.Client{} = client, arguments) do
    current_room = client.game_state.room
    valid_arguments = arguments |> Enum.filter(&(&1 not in ["to", "the", "at", "in"]))
    case valid_arguments do
      # look/0
      [] -> {:look, current_room}
      # look/1
      _ -> {:look, current_room, parse_look_target(current_room, valid_arguments)}
    end
  end

  defp parse_look_target(%Zung.Game.Room{} = room, arguments) do
    argument = join_arguments(arguments)
      |> String.downcase
      |> String.replace(~r/\bn\b/, "north")
      |> String.replace(~r/\bs\b/, "south")
      |> String.replace(~r/\be\b/, "east")
      |> String.replace(~r/\bw\b/, "west")
      |> String.replace(~r/\bu\b/, "up")
      |> String.replace(~r/\bd\b/, "down")

    matching_exit = Enum.find(room.exits, nil, &(Map.has_key?(&1, :name) and argument === &1.name))
    matching_flavor = Enum.find(room.flavor_texts, nil, &(argument === &1.id or argument in &1.keywords))
    cond do
      argument in ["north", "south", "east", "west", "up", "down"] -> {:direction, String.to_atom(argument)}
      matching_exit !== nil -> {:exit, matching_exit.name}
      matching_flavor !== nil -> {:flavor, matching_flavor.id}
      true -> {:flavor, ""}
    end
  end

  defp parse_csay(%Zung.Client{} = client, arguments) do
    if Enum.count(arguments) < 2 do
      {:bad_parse, "You must specify a channel and message."}
    else
      [channel | message_pieces] = arguments
      if channel not in client.game_state.subscribed_channels do
        {:bad_parse, "You are not part of the \"#{channel}\" channel."}
      else
        {:csay, String.to_atom(channel), join_arguments(message_pieces)}
      end
    end
  end

  defp parse_enter(%Zung.Client{} = client, arguments) do
    valid_arguments = arguments |> Enum.filter(&(&1 not in ["to", "the", "at", "in", "into"]))
    if Enum.count(valid_arguments) < 1 do
      {:bad_parse, "You must specify an exit."}
    else
      argument = join_arguments(valid_arguments)
        |> String.downcase
        |> String.replace(~r/\bn\b/, "north")
        |> String.replace(~r/\bs\b/, "south")
        |> String.replace(~r/\be\b/, "east")
        |> String.replace(~r/\bw\b/, "west")
        |> String.replace(~r/\bu\b/, "up")
        |> String.replace(~r/\bd\b/, "down")

      room = client.game_state.room
      matching_exit = Enum.find(room.exits, nil, &(Map.has_key?(&1, :name) and argument === &1.name))
      cond do
        argument in ["north", "south", "east", "west", "up", "down"] -> {:move, {:direction, String.to_atom(argument)}}
        matching_exit !== nil -> {:move, {:exit, matching_exit.name}}
        true -> {:move, {:exit, ""}}
      end

    end
  end

  defp apply_aliases("", _), do: ""
  defp apply_aliases(input, %Zung.Client{} = client) when client.game_state.command_aliases === %{}, do: input
  defp apply_aliases(input, %Zung.Client{} = client) do
    {:ok, alias_regex} = Regex.compile(~S"^\b(" <> Enum.reduce(Map.keys(client.game_state.command_aliases), "", fn cmd, acc ->
      if acc === "" do
        cmd
      else
         cmd <> "|" <> acc
      end
    end) <> ~S")\b")

    Regex.replace(alias_regex, input, fn _, match -> client.game_state.command_aliases[match] end)
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
      |> String.trim
  end
end
