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
    client
  end

  defp process_input(%Zung.Client{} = client) do
    {new_client, input} = Zung.Client.pop_input(client)

    if input !== nil do
      case Zung.Game.Parser.parse(new_client, input) do
        {:move, target} ->
          case Zung.Game.Room.move(new_client.game_state.room, target) do
            {:ok, new_room} ->
              new_client
              |> Zung.Client.leave_room(client.game_state.room)
              |> Zung.Client.enter_room(new_room)

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
          Zung.Client.push_output(new_client, Zung.Game.Object.read_target(all_objects, object_id))

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

    matching_exit = Enum.find(room.exits, nil, &(&1.direction === target_value or &1.name === target_value))

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

  defp format_who_list(usernames) do
    count = length(usernames)
    header = "||BOLD||||CYA||Players Online (#{count}):||RESET||||NL||"

    list =
      Enum.reduce(usernames, "", fn username, acc ->
        acc <> "  #{username}||NL||"
      end)

    header <> list
  end
end
