defmodule Zung.State.Game.Game do
  require Logger
  @behaviour Zung.State.State

  def run(%Zung.Client{} = client, _) do
    do_game(client) |> run(%{})
  end

  def do_game(%Zung.Client{} = client) do
    client
    |> process_events
    |> process_input
    |> Zung.Client.flush_output()
  end

  defp process_events(%Zung.Client{} = client) do
    pending_items = Zung.Client.Connection.drain_pending_items(client.connection)

    if Enum.empty?(pending_items) do
      client
    else
      %Zung.Client.GameState{} = game_state = client.game_state

      %Zung.Client{
        client
        | game_state: %Zung.Client.GameState{
            game_state
            | inventory: pending_items ++ game_state.inventory
          }
      }
    end
  end

  defp process_input(%Zung.Client{} = client) do
    {new_client, input} = Zung.Client.pop_input(client)

    if input !== nil do
      case Zung.Game.Parser.parse(new_client, input) do
        {:move, target} ->
          case Zung.Game.Room.move(new_client.game_state.room, target) do
            {:ok, new_room} ->
              moved_client =
                if new_client.game_state.following != nil do
                  old_following = new_client.game_state.following

                  Zung.Client.Connection.unsubscribe(
                    new_client.connection,
                    {:follow, old_following}
                  )

                  %Zung.Client.GameState{} = game_state = new_client.game_state

                  %Zung.Client{
                    new_client
                    | game_state: %Zung.Client.GameState{game_state | following: nil}
                  }
                  |> Zung.Client.push_output("You stop following #{old_following}.")
                else
                  new_client
                end

              moved_client
              |> Zung.Client.leave_room(client.game_state.room)
              |> Zung.Client.enter_room(new_room)
              |> notify_followers()

            {:error, error_message} ->
              Zung.Client.push_output(new_client, error_message)
          end

        {:look, room} ->
          Zung.Client.push_output(new_client, Zung.Game.Room.describe(room))

        {:look, _room, {:object, id}} ->
          all_objects = new_client.game_state.room.objects ++ new_client.game_state.inventory
          Zung.Client.push_output(new_client, Zung.Game.Object.describe_target(all_objects, id))

        {:look, room, target} ->
          Zung.Client.push_output(new_client, Zung.Game.Room.look_at(room, target))

        {:examine, _room, {:object, id}} ->
          all_objects = new_client.game_state.room.objects ++ new_client.game_state.inventory
          Zung.Client.push_output(new_client, Zung.Game.Object.examine_target(all_objects, id))

        {:examine, room, target} ->
          Zung.Client.push_output(new_client, Zung.Game.Room.examine(room, target))

        {:say, room, message} ->
          Zung.Client.say_to_room(new_client, room.id, message)

        {:csay, chat_room, message} ->
          Zung.Client.publish_to_chat(new_client, chat_room, message)

        {:help} ->
          Zung.Client.push_output(new_client, Zung.Game.Help.list_commands())

        {:help, name} ->
          Zung.Client.push_output(new_client, Zung.Game.Help.describe_command(name))

        :who ->
          usernames = Zung.Client.Session.get_active_usernames()
          Zung.Client.push_output(new_client, format_who_list(usernames))

        :inventory ->
          inventory = new_client.game_state.inventory

          if Enum.empty?(inventory) do
            Zung.Client.push_output(new_client, "You are not carrying anything.")
          else
            header = "||BOLD||||CYA||You are carrying:||RESET||||NL||"

            items =
              Enum.reduce(inventory, "", fn object, acc ->
                acc <> "  #{object.name}||NL||"
              end)

            Zung.Client.push_output(new_client, header <> items)
          end

        {:get, _room, object_id} ->
          case Zung.DataStore.remove_object_from_room(
                 new_client.game_state.room.id,
                 object_id
               ) do
            {:ok, object} ->
              updated_room = Zung.DataStore.get_room(new_client.game_state.room.id)
              %Zung.Client.GameState{} = game_state = new_client.game_state

              %Zung.Client{
                new_client
                | game_state: %Zung.Client.GameState{
                    game_state
                    | inventory: [object | game_state.inventory],
                      room: updated_room
                  }
              }
              |> Zung.Client.push_output("You pick up #{object.name}.")

            {:error, message} ->
              Zung.Client.push_output(new_client, "||RED||#{message}||RESET||")
          end

        {:drop, _room, object_id} ->
          object = Enum.find(new_client.game_state.inventory, &(&1.id === object_id))
          Zung.DataStore.add_object_to_room(new_client.game_state.room.id, object)
          updated_room = Zung.DataStore.get_room(new_client.game_state.room.id)
          %Zung.Client.GameState{} = game_state = new_client.game_state

          %Zung.Client{
            new_client
            | game_state: %Zung.Client.GameState{
                game_state
                | inventory: Enum.reject(game_state.inventory, &(&1.id === object_id)),
                  room: updated_room
              }
          }
          |> Zung.Client.push_output("You drop #{object.name}.")

        {:read, _room, object_id} ->
          all_objects = new_client.game_state.room.objects ++ new_client.game_state.inventory

          Zung.Client.push_output(
            new_client,
            Zung.Game.Object.read_target(all_objects, object_id)
          )

        {:search, room} ->
          if room.search_text != nil do
            Zung.Client.push_output(new_client, room.search_text)
          else
            Zung.Client.push_output(new_client, "You search but find nothing of interest.")
          end

        {:use, _room, object_id} ->
          all_objects = new_client.game_state.room.objects ++ new_client.game_state.inventory
          Zung.Client.push_output(new_client, Zung.Game.Object.use_target(all_objects, object_id))

        {:use_on, _room, _object_id, _target} ->
          Zung.Client.push_output(new_client, "You can't figure out how to use that on it.")

        {:open, _room, exit_target} ->
          handle_exit_action(new_client, exit_target, :open)

        {:close, _room, exit_target} ->
          handle_exit_action(new_client, exit_target, :close)

        {:lock, _room, exit_target} ->
          handle_exit_action(new_client, exit_target, :lock)

        {:unlock, _room, exit_target} ->
          handle_exit_action(new_client, exit_target, :unlock)

        {:talk, room, npc_id} ->
          npc = Zung.Game.Npc.find(room.npcs, npc_id)

          if npc != nil do
            Zung.Client.push_output(new_client, npc.greeting)
          else
            Zung.Client.push_output(new_client, "They don't seem interested in talking.")
          end

        {:ask, room, npc_id, topic} ->
          npc = Zung.Game.Npc.find(room.npcs, npc_id)

          if npc != nil do
            case Map.get(npc.topics, topic) do
              nil ->
                Zung.Client.push_output(
                  new_client,
                  "#{npc.name} doesn't seem to know anything about that."
                )

              response ->
                Zung.Client.push_output(new_client, response)
            end
          else
            Zung.Client.push_output(new_client, "They don't seem interested in talking.")
          end

        :list_aliases ->
          aliases = new_client.game_state.command_aliases

          if map_size(aliases) == 0 do
            Zung.Client.push_output(new_client, "You have no aliases defined.")
          else
            header = "||BOLD||||CYA||Aliases:||RESET||||NL||"

            list =
              Enum.reduce(aliases, "", fn {name, expansion}, acc ->
                acc <> "  ||GRN||#{name}||RESET|| -> #{expansion}||NL||"
              end)

            Zung.Client.push_output(new_client, header <> list)
          end

        {:set_alias, name, expansion} ->
          %Zung.Client.GameState{} = game_state = new_client.game_state
          new_aliases = Map.put(game_state.command_aliases, name, expansion)

          %Zung.Client{
            new_client
            | game_state: %Zung.Client.GameState{game_state | command_aliases: new_aliases}
          }
          |> Zung.Client.push_output("Alias set: ||GRN||#{name}||RESET|| -> #{expansion}")

        {:remove_alias, name} ->
          %Zung.Client.GameState{} = game_state = new_client.game_state

          if Map.has_key?(game_state.command_aliases, name) do
            new_aliases = Map.delete(game_state.command_aliases, name)

            %Zung.Client{
              new_client
              | game_state: %Zung.Client.GameState{game_state | command_aliases: new_aliases}
            }
            |> Zung.Client.push_output("Alias removed: #{name}")
          else
            Zung.Client.push_output(new_client, "||RED||No alias found for \"#{name}\".||RESET||")
          end

        {:emote, room, action} ->
          Zung.Client.emote_to_room(new_client, room.id, action)

        {:shout, room, message} ->
          Zung.Client.shout(new_client, room, message)

        {:whisper, _room, target, message} ->
          usernames = Zung.Client.Session.get_active_usernames()

          if target in usernames do
            Zung.Client.whisper_to_room(
              new_client,
              new_client.game_state.room.id,
              target,
              message
            )
          else
            Zung.Client.push_output(new_client, "||RED||#{target} is not online.||RESET||")
          end

        {:tell, target, message} ->
          usernames = Zung.Client.Session.get_active_usernames()

          if target in usernames do
            Zung.Client.tell_player(new_client, target, message)
          else
            Zung.Client.push_output(new_client, "||RED||#{target} is not online.||RESET||")
          end

        {:follow, target} ->
          username = new_client.game_state.username
          usernames = Zung.Client.Session.get_active_usernames()

          cond do
            target == username ->
              Zung.Client.push_output(new_client, "||RED||You can't follow yourself.||RESET||")

            target not in usernames ->
              Zung.Client.push_output(new_client, "||RED||#{target} is not online.||RESET||")

            true ->
              %Zung.Client.GameState{} = game_state = new_client.game_state

              updated_client =
                if game_state.following != nil do
                  Zung.Client.Connection.unsubscribe(
                    new_client.connection,
                    {:follow, game_state.following}
                  )

                  new_client
                else
                  new_client
                end

              Zung.Client.Connection.subscribe(updated_client.connection, {:follow, target})

              %Zung.Client{
                updated_client
                | game_state: %Zung.Client.GameState{game_state | following: target}
              }
              |> Zung.Client.push_output("You begin following #{target}.")
          end

        :stop_following ->
          %Zung.Client.GameState{} = game_state = new_client.game_state

          if game_state.following == nil do
            Zung.Client.push_output(new_client, "You are not following anyone.")
          else
            old_target = game_state.following
            Zung.Client.Connection.unsubscribe(new_client.connection, {:follow, old_target})

            %Zung.Client{
              new_client
              | game_state: %Zung.Client.GameState{game_state | following: nil}
            }
            |> Zung.Client.push_output("You stop following #{old_target}.")
          end

        :lead ->
          Zung.Client.push_output(new_client, "Anyone following you will move when you do.")

        {:follow_move, leader, room_id} ->
          new_room = Zung.DataStore.get_room(room_id)

          if new_room != nil do
            game_state = new_client.game_state

            new_client
            |> Zung.Client.leave_room(game_state.room)
            |> Zung.Client.enter_room(new_room)
            |> Zung.Client.push_output("You follow #{leader}.")
          else
            Zung.Client.push_output(new_client, "You can't seem to follow them there.")
          end

        :where ->
          usernames = Zung.Client.Session.get_active_usernames()
          Zung.Client.push_output(new_client, format_where_list(usernames))

        :score ->
          Zung.Client.push_output(new_client, format_score(new_client.game_state))

        :toggle_brief ->
          %Zung.Client.GameState{} = game_state = new_client.game_state
          new_brief = !game_state.brief_mode

          %Zung.Client{
            new_client
            | game_state: %Zung.Client.GameState{game_state | brief_mode: new_brief}
          }
          |> Zung.Client.push_output("Brief mode is now #{if new_brief, do: "on", else: "off"}.")

        :list_settings ->
          game_state = new_client.game_state
          use_ansi? = Zung.Client.User.get_setting(game_state.username, :use_ansi?)

          settings_text =
            "||BOLD||||CYA||Settings:||RESET||||NL||" <>
              "  ||GRN||ansi#{String.duplicate(" ", 8)}||RESET|| #{if use_ansi?, do: "on", else: "off"}||NL||" <>
              "  ||GRN||brief#{String.duplicate(" ", 7)}||RESET|| #{if game_state.brief_mode, do: "on", else: "off"}||NL||"

          Zung.Client.push_output(new_client, settings_text)

        {:set_setting, "ansi", value} ->
          Zung.Client.User.set_setting(new_client.game_state.username, :use_ansi?, value)
          Zung.Client.Connection.use_ansi(new_client.connection, value)

          Zung.Client.push_output(
            new_client,
            "ANSI colors #{if value, do: "enabled", else: "disabled"}."
          )

        {:set_setting, "brief", value} ->
          %Zung.Client.GameState{} = game_state = new_client.game_state

          %Zung.Client{
            new_client
            | game_state: %Zung.Client.GameState{game_state | brief_mode: value}
          }
          |> Zung.Client.push_output("Brief mode is now #{if value, do: "on", else: "off"}.")

        {:set_setting, unknown, _value} ->
          Zung.Client.push_output(
            new_client,
            "||RED||Unknown setting: \"#{unknown}\". Available settings: ansi, brief||RESET||"
          )

        {:give, object_id, target} ->
          username = new_client.game_state.username
          usernames = Zung.Client.Session.get_active_usernames()
          object = Enum.find(new_client.game_state.inventory, &(&1.id === object_id))

          cond do
            target == username ->
              Zung.Client.push_output(
                new_client,
                "||RED||You can't give items to yourself.||RESET||"
              )

            target not in usernames ->
              Zung.Client.push_output(new_client, "||RED||#{target} is not online.||RESET||")

            Zung.DataStore.get_current_room_id(target) != new_client.game_state.room.id ->
              Zung.Client.push_output(
                new_client,
                "||RED||#{target} is not in the same room.||RESET||"
              )

            true ->
              %Zung.Client.GameState{} = game_state = new_client.game_state

              Zung.Client.Connection.publish(
                new_client.connection,
                {:player, target},
                {:give_item, username, object}
              )

              %Zung.Client{
                new_client
                | game_state: %Zung.Client.GameState{
                    game_state
                    | inventory: Enum.reject(game_state.inventory, &(&1.id === object_id))
                  }
              }
              |> Zung.Client.push_output("You give #{object.name} to #{target}.")
          end

        :quit ->
          raise Zung.Error.Connection.Closed

        {:bad_parse, message} ->
          Zung.Client.push_output(new_client, "||RED||#{message}||RESET||")

        _ ->
          Zung.Client.push_output(new_client, "||GRN||Wut?||RESET||")
      end
    else
      new_client
    end
  end

  defp handle_exit_action(%Zung.Client{} = client, exit_target, action) do
    room = client.game_state.room

    target_value =
      case exit_target do
        {:direction, dir} -> dir
        {:exit, name} -> name
      end

    matching_exit =
      Enum.find(room.exits, nil, &(&1.direction === target_value or &1.name === target_value))

    if matching_exit == nil do
      Zung.Client.push_output(client, "||RED||You don't see that here.||RESET||")
    else
      case {action, matching_exit.state} do
        {:open, :open} ->
          Zung.Client.push_output(client, "It's already open.")

        {:open, :locked} ->
          Zung.Client.push_output(client, "It's locked.")

        {:open, :closed} ->
          Zung.DataStore.update_exit_state(room.id, target_value, :open)
          updated_room = Zung.DataStore.get_room(room.id)
          %Zung.Client.GameState{} = game_state = client.game_state

          %Zung.Client{
            client
            | game_state: %Zung.Client.GameState{game_state | room: updated_room}
          }
          |> Zung.Client.push_output("You open it.")

        {:close, :closed} ->
          Zung.Client.push_output(client, "It's already closed.")

        {:close, :locked} ->
          Zung.Client.push_output(client, "It's already closed and locked.")

        {:close, :open} ->
          Zung.DataStore.update_exit_state(room.id, target_value, :closed)
          updated_room = Zung.DataStore.get_room(room.id)
          %Zung.Client.GameState{} = game_state = client.game_state

          %Zung.Client{
            client
            | game_state: %Zung.Client.GameState{game_state | room: updated_room}
          }
          |> Zung.Client.push_output("You close it.")

        {:unlock, :open} ->
          Zung.Client.push_output(client, "It's already open.")

        {:unlock, :closed} ->
          Zung.Client.push_output(client, "It isn't locked.")

        {:unlock, :locked} ->
          if matching_exit.key_id == nil do
            Zung.Client.push_output(client, "You can't figure out how to unlock it.")
          else
            has_key = Enum.any?(client.game_state.inventory, &(&1.id === matching_exit.key_id))

            if has_key do
              Zung.DataStore.update_exit_state(room.id, target_value, :closed)
              updated_room = Zung.DataStore.get_room(room.id)
              %Zung.Client.GameState{} = game_state = client.game_state

              %Zung.Client{
                client
                | game_state: %Zung.Client.GameState{game_state | room: updated_room}
              }
              |> Zung.Client.push_output("||GRN||You unlock it.||RESET||")
            else
              Zung.Client.push_output(client, "You don't have the right key.")
            end
          end

        {:lock, :open} ->
          Zung.Client.push_output(client, "You need to close it first.")

        {:lock, :locked} ->
          Zung.Client.push_output(client, "It's already locked.")

        {:lock, :closed} ->
          if matching_exit.key_id == nil do
            Zung.Client.push_output(client, "You can't figure out how to lock it.")
          else
            has_key = Enum.any?(client.game_state.inventory, &(&1.id === matching_exit.key_id))

            if has_key do
              Zung.DataStore.update_exit_state(room.id, target_value, :locked)
              updated_room = Zung.DataStore.get_room(room.id)
              %Zung.Client.GameState{} = game_state = client.game_state

              %Zung.Client{
                client
                | game_state: %Zung.Client.GameState{game_state | room: updated_room}
              }
              |> Zung.Client.push_output("||GRN||You lock it.||RESET||")
            else
              Zung.Client.push_output(client, "You don't have the right key.")
            end
          end
      end
    end
  end

  defp notify_followers(%Zung.Client{} = client) do
    username = client.game_state.username
    room_id = client.game_state.room.id

    Zung.Client.Connection.publish(
      client.connection,
      {:follow, username},
      {:leader_moved, username, room_id}
    )

    client
  end

  defp format_who_list(usernames) do
    count = length(usernames)
    header = "||BOLD||||CYA||Players Online (#{count}):||RESET||||NL||"

    list =
      Enum.reduce(usernames, "", fn username, acc ->
        acc <> "  #{username}||NL||"
      end)

    header <> list
  end

  defp format_where_list(usernames) do
    count = length(usernames)
    header = "||BOLD||||CYA||Player Locations (#{count}):||RESET||||NL||"

    list =
      Enum.reduce(usernames, "", fn username, acc ->
        room_id = Zung.DataStore.get_current_room_id(username)
        room = Zung.DataStore.get_room(room_id)
        room_title = if room != nil, do: room.title, else: "Unknown"
        acc <> "  #{String.pad_trailing(username, 16)}#{room_title}||NL||"
      end)

    header <> list
  end

  defp format_score(%Zung.Client.GameState{} = game_state) do
    room_title = game_state.room.title
    item_count = length(game_state.inventory)
    alias_count = map_size(game_state.command_aliases)
    chat_count = length(game_state.joined_chat_rooms)

    following_text =
      if game_state.following != nil, do: game_state.following, else: "nobody"

    brief_text = if game_state.brief_mode, do: "on", else: "off"

    "||BOLD||||CYA||Character Summary:||RESET||||NL||" <>
      "  ||GRN||Name:#{String.duplicate(" ", 7)}||RESET|| #{game_state.username}||NL||" <>
      "  ||GRN||Location:#{String.duplicate(" ", 3)}||RESET|| #{room_title}||NL||" <>
      "  ||GRN||Items:#{String.duplicate(" ", 6)}||RESET|| #{item_count}||NL||" <>
      "  ||GRN||Aliases:#{String.duplicate(" ", 4)}||RESET|| #{alias_count}||NL||" <>
      "  ||GRN||Chats:#{String.duplicate(" ", 6)}||RESET|| #{chat_count}||NL||" <>
      "  ||GRN||Following:#{String.duplicate(" ", 2)}||RESET|| #{following_text}||NL||" <>
      "  ||GRN||Brief mode:#{String.duplicate(" ", 1)}||RESET|| #{brief_text}||NL||"
  end
end
