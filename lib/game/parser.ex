defmodule Zung.Game.Parser do
  require Logger

  # TODO ideas for commands -> https://github.com/sneezymud/dikumud/blob/master/lib/help_table
  # TODO cool alias section -> https://github.com/Yuffster/CircleMUD/blob/master/lib/text/help/commands.hlp
  # TODO nice website -> https://dslmud.fandom.com/wiki/Commands
  # TODO neat thing about room/area building -> http://www.forgottenkingdoms.org/builders/blessons.php

  @type exit_target :: {:direction, atom()} | {:exit, String.t()}

  @type command ::
          {:move, {:direction, atom()}}
          | {:move, {:exit, String.t()}}
          | {:look, Zung.Game.Room.t()}
          | {:look, Zung.Game.Room.t(), Zung.Game.Room.look_target()}
          | {:examine, Zung.Game.Room.t(), Zung.Game.Room.look_target()}
          | {:say, Zung.Game.Room.t(), String.t()}
          | {:csay, atom(), String.t()}
          | {:help}
          | {:help, String.t()}
          | :who
          | {:get, Zung.Game.Room.t(), String.t()}
          | {:drop, Zung.Game.Room.t(), String.t()}
          | :inventory
          | {:read, Zung.Game.Room.t(), String.t()}
          | {:search, Zung.Game.Room.t()}
          | {:use, Zung.Game.Room.t(), String.t()}
          | {:use_on, Zung.Game.Room.t(), String.t(), Zung.Game.Room.look_target()}
          | {:open, Zung.Game.Room.t(), exit_target()}
          | {:close, Zung.Game.Room.t(), exit_target()}
          | {:lock, Zung.Game.Room.t(), exit_target()}
          | {:unlock, Zung.Game.Room.t(), exit_target()}
          | {:talk, Zung.Game.Room.t(), String.t()}
          | {:ask, Zung.Game.Room.t(), String.t(), String.t()}
          | :list_aliases
          | {:set_alias, String.t(), String.t()}
          | {:remove_alias, String.t()}
          | {:emote, Zung.Game.Room.t(), String.t()}
          | {:shout, Zung.Game.Room.t(), String.t()}
          | {:whisper, Zung.Game.Room.t(), String.t(), String.t()}
          | {:tell, String.t(), String.t()}
          | {:follow, String.t()}
          | :stop_following
          | :lead
          | {:follow_move, String.t(), String.t()}
          | :quit
          | :unknown_command
          | {:bad_parse, String.t()}

  @spec parse(Zung.Client.t(), String.t()) :: command()
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
      "examine" -> parse_examine(client, arguments)
      "say" -> parse_say(client, arguments)
      "csay" -> parse_csay(client, arguments)
      "enter" -> parse_enter(client, arguments)
      "help" -> parse_help(arguments)
      "who" -> :who
      "get" -> parse_get(client, arguments)
      "take" -> parse_get(client, arguments)
      "drop" -> parse_drop(client, arguments)
      "inventory" -> :inventory
      "read" -> parse_read(client, arguments)
      "search" -> {:search, client.game_state.room}
      "use" -> parse_use(client, arguments)
      "open" -> parse_exit_action(client, arguments, :open)
      "close" -> parse_exit_action(client, arguments, :close)
      "lock" -> parse_exit_action(client, arguments, :lock)
      "unlock" -> parse_exit_action(client, arguments, :unlock)
      "talk" -> parse_talk(client, arguments)
      "ask" -> parse_ask(client, arguments)
      "alias" -> parse_alias(client, arguments)
      "unalias" -> parse_unalias(arguments)
      "emote" -> parse_emote(client, arguments)
      "me" -> parse_emote(client, arguments)
      "bow" -> {:emote, client.game_state.room, "bows gracefully."}
      "wave" -> {:emote, client.game_state.room, "waves."}
      "nod" -> {:emote, client.game_state.room, "nods."}
      "shrug" -> {:emote, client.game_state.room, "shrugs."}
      "shout" -> parse_shout(client, arguments)
      "yell" -> parse_shout(client, arguments)
      "whisper" -> parse_whisper(client, arguments)
      "tell" -> parse_tell(arguments)
      "follow" -> parse_follow(arguments)
      "lead" -> :lead
      "__follow_move" -> parse_follow_move(arguments)
      "quit" -> :quit
      _ -> :unknown_command
    end
  end

  defp parse_look(%Zung.Client{} = client, arguments) do
    current_room = client.game_state.room
    inventory = client.game_state.inventory
    valid_arguments = arguments |> Enum.filter(&(&1 not in ["to", "the", "at", "in"]))

    case valid_arguments do
      # look/0
      [] -> {:look, current_room}
      # look/1
      _ -> {:look, current_room, parse_look_target(current_room, valid_arguments, inventory)}
    end
  end

  defp parse_examine(%Zung.Client{} = client, arguments) do
    current_room = client.game_state.room
    inventory = client.game_state.inventory
    valid_arguments = arguments |> Enum.filter(&(&1 not in ["to", "the", "at", "in"]))

    case valid_arguments do
      [] -> {:bad_parse, "What do you want to examine?"}
      _ -> {:examine, current_room, parse_look_target(current_room, valid_arguments, inventory)}
    end
  end

  defp parse_look_target(%Zung.Game.Room{} = room, arguments, inventory) do
    argument =
      join_arguments(arguments)
      |> String.downcase()
      |> String.replace(~r/\bn\b/, "north")
      |> String.replace(~r/\bs\b/, "south")
      |> String.replace(~r/\be\b/, "east")
      |> String.replace(~r/\bw\b/, "west")
      |> String.replace(~r/\bu\b/, "up")
      |> String.replace(~r/\bd\b/, "down")

    matching_exit =
      Enum.find(room.exits, nil, &(Map.has_key?(&1, :name) and argument === &1.name))

    matching_flavor =
      Enum.find(room.flavor_texts, nil, &(argument === &1.id or argument in &1.keywords))

    matching_object =
      Enum.find(room.objects ++ inventory, nil, &(argument === &1.id or argument in &1.keywords))

    cond do
      argument in ["north", "south", "east", "west", "up", "down"] ->
        {:direction, String.to_atom(argument)}

      matching_exit !== nil ->
        {:exit, matching_exit.name}

      matching_flavor !== nil ->
        {:flavor, matching_flavor.id}

      matching_object !== nil ->
        {:object, matching_object.id}

      true ->
        {:flavor, ""}
    end
  end

  defp parse_say(%Zung.Client{} = client, arguments) do
    message = join_arguments(arguments)

    if message === "" do
      {:bad_parse, "You must specify a message."}
    else
      {:say, client.game_state.room, message}
    end
  end

  defp parse_csay(%Zung.Client{} = client, arguments) do
    if Enum.count(arguments) < 2 do
      {:bad_parse, "You must specify a chat and message."}
    else
      [chat_room | message_pieces] = arguments

      if chat_room not in client.game_state.joined_chat_rooms do
        {:bad_parse, "You are not part of the \"#{chat_room}\" chat."}
      else
        {:csay, String.to_atom(chat_room), join_arguments(message_pieces)}
      end
    end
  end

  defp parse_enter(%Zung.Client{} = client, arguments) do
    valid_arguments = arguments |> Enum.filter(&(&1 not in ["to", "the", "at", "in", "into"]))

    if Enum.count(valid_arguments) < 1 do
      {:bad_parse, "You must specify an exit."}
    else
      argument =
        join_arguments(valid_arguments)
        |> String.downcase()
        |> String.replace(~r/\bn\b/, "north")
        |> String.replace(~r/\bs\b/, "south")
        |> String.replace(~r/\be\b/, "east")
        |> String.replace(~r/\bw\b/, "west")
        |> String.replace(~r/\bu\b/, "up")
        |> String.replace(~r/\bd\b/, "down")

      room = client.game_state.room

      matching_exit =
        Enum.find(room.exits, nil, &(Map.has_key?(&1, :name) and argument === &1.name))

      cond do
        argument in ["north", "south", "east", "west", "up", "down"] ->
          {:move, {:direction, String.to_atom(argument)}}

        matching_exit !== nil ->
          {:move, {:exit, matching_exit.name}}

        true ->
          {:move, {:exit, ""}}
      end
    end
  end

  defp parse_help(arguments) do
    case arguments do
      [] -> {:help}
      _ -> {:help, join_arguments(arguments)}
    end
  end

  defp parse_get(%Zung.Client{} = client, arguments) do
    valid_arguments = arguments |> Enum.filter(&(&1 not in ["the", "a", "an"]))

    if Enum.empty?(valid_arguments) do
      {:bad_parse, "What do you want to pick up?"}
    else
      current_room = client.game_state.room
      argument = join_arguments(valid_arguments) |> String.downcase()

      matching_object =
        Enum.find(current_room.objects, nil, &(argument === &1.id or argument in &1.keywords))

      if matching_object !== nil do
        {:get, current_room, matching_object.id}
      else
        {:bad_parse, "You don't see that here."}
      end
    end
  end

  defp parse_drop(%Zung.Client{} = client, arguments) do
    valid_arguments = arguments |> Enum.filter(&(&1 not in ["the", "a", "an"]))

    if Enum.empty?(valid_arguments) do
      {:bad_parse, "What do you want to drop?"}
    else
      inventory = client.game_state.inventory
      argument = join_arguments(valid_arguments) |> String.downcase()

      matching_object =
        Enum.find(inventory, nil, &(argument === &1.id or argument in &1.keywords))

      if matching_object !== nil do
        {:drop, client.game_state.room, matching_object.id}
      else
        {:bad_parse, "You don't have that."}
      end
    end
  end

  defp parse_read(%Zung.Client{} = client, arguments) do
    valid_arguments = arguments |> Enum.filter(&(&1 not in ["the", "a", "an"]))

    if Enum.empty?(valid_arguments) do
      {:bad_parse, "What do you want to read?"}
    else
      current_room = client.game_state.room
      inventory = client.game_state.inventory
      argument = join_arguments(valid_arguments) |> String.downcase()

      matching_object =
        Enum.find(current_room.objects ++ inventory, nil, &(argument === &1.id or argument in &1.keywords))

      if matching_object !== nil do
        {:read, current_room, matching_object.id}
      else
        {:bad_parse, "You don't see that here."}
      end
    end
  end

  defp parse_use(%Zung.Client{} = client, arguments) do
    valid_arguments = arguments |> Enum.filter(&(&1 not in ["the", "a", "an"]))

    if Enum.empty?(valid_arguments) do
      {:bad_parse, "What do you want to use?"}
    else
      on_index = Enum.find_index(valid_arguments, &(&1 === "on"))

      if on_index != nil and on_index > 0 do
        {object_args, target_args} = Enum.split(valid_arguments, on_index)
        target_args = Enum.drop(target_args, 1) |> Enum.filter(&(&1 not in ["the", "a", "an"]))
        parse_use_on(client, object_args, target_args)
      else
        current_room = client.game_state.room
        inventory = client.game_state.inventory
        argument = join_arguments(valid_arguments) |> String.downcase()

        matching_object =
          Enum.find(inventory ++ current_room.objects, nil, &(argument === &1.id or argument in &1.keywords))

        if matching_object !== nil do
          {:use, current_room, matching_object.id}
        else
          {:bad_parse, "You don't see that here."}
        end
      end
    end
  end

  defp parse_use_on(%Zung.Client{} = client, object_args, target_args) do
    current_room = client.game_state.room
    inventory = client.game_state.inventory

    if Enum.empty?(target_args) do
      {:bad_parse, "Use it on what?"}
    else
      object_argument = join_arguments(object_args) |> String.downcase()
      matching_object =
        Enum.find(inventory ++ current_room.objects, nil, &(object_argument === &1.id or object_argument in &1.keywords))

      if matching_object !== nil do
        target = parse_look_target(current_room, target_args, inventory)
        {:use_on, current_room, matching_object.id, target}
      else
        {:bad_parse, "You don't see that here."}
      end
    end
  end

  defp parse_exit_action(%Zung.Client{} = client, arguments, action) do
    valid_arguments = arguments |> Enum.filter(&(&1 not in ["the", "a", "an"]))
    action_word = Atom.to_string(action)

    if Enum.empty?(valid_arguments) do
      {:bad_parse, "What do you want to #{action_word}?"}
    else
      current_room = client.game_state.room
      argument = join_arguments(valid_arguments) |> String.downcase()

      direction_atom =
        case argument do
          "north" -> :north
          "south" -> :south
          "east" -> :east
          "west" -> :west
          "up" -> :up
          "down" -> :down
          _ -> nil
        end

      matching_exit =
        if direction_atom do
          Enum.find(current_room.exits, nil, &(&1.direction === direction_atom))
        else
          Enum.find(current_room.exits, nil, &(Map.has_key?(&1, :name) and argument === &1.name))
        end

      cond do
        matching_exit != nil and direction_atom != nil ->
          {action, current_room, {:direction, direction_atom}}

        matching_exit != nil ->
          {action, current_room, {:exit, matching_exit.name}}

        true ->
          {:bad_parse, "You don't see that here."}
      end
    end
  end

  defp parse_talk(%Zung.Client{} = client, arguments) do
    valid_arguments = arguments |> Enum.filter(&(&1 not in ["to", "the", "a", "an", "with"]))

    if Enum.empty?(valid_arguments) do
      {:bad_parse, "Who do you want to talk to?"}
    else
      current_room = client.game_state.room
      argument = join_arguments(valid_arguments) |> String.downcase()

      matching_npc = Zung.Game.Npc.find(current_room.npcs, argument)

      if matching_npc !== nil do
        {:talk, current_room, matching_npc.id}
      else
        {:bad_parse, "You don't see anyone by that name."}
      end
    end
  end

  defp parse_ask(%Zung.Client{} = client, arguments) do
    valid_arguments = arguments |> Enum.filter(&(&1 not in ["the", "a", "an"]))

    about_index = Enum.find_index(valid_arguments, &(&1 === "about"))

    if about_index == nil or about_index == 0 do
      {:bad_parse, "Try: ask <person> about <topic>"}
    else
      {npc_args, topic_args} = Enum.split(valid_arguments, about_index)
      topic_args = Enum.drop(topic_args, 1)

      if Enum.empty?(topic_args) do
        {:bad_parse, "What do you want to ask about?"}
      else
        current_room = client.game_state.room
        npc_argument = join_arguments(npc_args) |> String.downcase()
        topic = join_arguments(topic_args) |> String.downcase()

        matching_npc = Zung.Game.Npc.find(current_room.npcs, npc_argument)

        if matching_npc !== nil do
          {:ask, current_room, matching_npc.id, topic}
        else
          {:bad_parse, "You don't see anyone by that name."}
        end
      end
    end
  end

  defp parse_alias(%Zung.Client{} = _client, arguments) do
    case arguments do
      [] -> :list_aliases
      [_single] -> {:bad_parse, "Usage: alias <name> <command>"}
      [name | expansion] -> {:set_alias, name, join_arguments(expansion)}
    end
  end

  defp parse_unalias(arguments) do
    case arguments do
      [] -> {:bad_parse, "Usage: unalias <name>"}
      [name | _] -> {:remove_alias, name}
    end
  end

  defp parse_emote(%Zung.Client{} = client, arguments) do
    action = join_arguments(arguments)

    if action === "" do
      {:bad_parse, "What do you want to do?"}
    else
      {:emote, client.game_state.room, action}
    end
  end

  defp parse_shout(%Zung.Client{} = client, arguments) do
    message = join_arguments(arguments)

    if message === "" do
      {:bad_parse, "What do you want to shout?"}
    else
      {:shout, client.game_state.room, message}
    end
  end

  defp parse_whisper(%Zung.Client{} = client, arguments) do
    valid_arguments = arguments |> Enum.filter(&(&1 not in ["to"]))

    if Enum.count(valid_arguments) < 2 do
      {:bad_parse, "Usage: whisper <player> <message>"}
    else
      [target | message_parts] = valid_arguments
      {:whisper, client.game_state.room, target, join_arguments(message_parts)}
    end
  end

  defp parse_tell(arguments) do
    if Enum.count(arguments) < 2 do
      {:bad_parse, "Usage: tell <player> <message>"}
    else
      [target | message_parts] = arguments
      {:tell, target, join_arguments(message_parts)}
    end
  end

  defp parse_follow(arguments) do
    case arguments do
      [] -> :stop_following
      [target | _] -> {:follow, target}
    end
  end

  defp parse_follow_move(arguments) do
    case arguments do
      [leader, room_id] -> {:follow_move, leader, room_id}
      _ -> :unknown_command
    end
  end

  defp apply_aliases("", _), do: ""

  defp apply_aliases(input, %Zung.Client{} = client)
       when client.game_state.command_aliases === %{},
       do: input

  defp apply_aliases(input, %Zung.Client{} = client) do
    {:ok, alias_regex} =
      Regex.compile(
        ~S"^\b(" <>
          Enum.reduce(Map.keys(client.game_state.command_aliases), "", fn cmd, acc ->
            if acc === "" do
              cmd
            else
              cmd <> "|" <> acc
            end
          end) <> ~S")\b"
      )

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
    |> Enum.reduce("", &"#{&2} #{&1}")
    |> String.trim()
  end
end
