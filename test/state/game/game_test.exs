defmodule Zung.State.Game.GameTest do
  use ExUnit.Case, async: true
  use MecksUnit.Case

  alias Zung.State.Game.Game

  defmock Zung.Client, preserve: true do
    def new(_socket) do
      %Zung.Client {
        session_id: 1234,
        connection: %{
          id: 5678,
          input_buffer: :queue.new,
          output_buffer: :queue.new,
        },
      }
    end

    def pop_input(%Zung.Client{} = client) do
      if :queue.is_empty(client.connection.input_buffer) do
        {client, nil}
      else
        {{:value, input}, new_queue} = :queue.out(client.connection.input_buffer)
        {%Zung.Client{client | connection: %{client.connection | input_buffer: new_queue}}, input}
      end
    end

    def push_output(%Zung.Client{} = client, output) do
      %Zung.Client{client | connection: %{client.connection | output_buffer: :queue.in(output, client.connection.output_buffer)}}
    end

    def flush_output(%Zung.Client{} = client) do
      # don't actually flush output so we can pick at it during testing
      client
    end

    def publish(%Zung.Client{} = client, _channel, _message) do
      # do nothing during testing
      client
    end

  end

  defmock Zung.DataStore, preserve: true do
    def get_room(room_id) do
      case room_id do
        "test_room" -> %Zung.Game.Room{
          id: "test_room",
          title: "The Test Room",
          description: "A simple test room for testing units",
          flavor_texts: [
            %{
              id: "simple_flavor",
              keywords: ["tasty"],
              text: "You see something quite flavorful"
            },
            %{
              id: "compound_flavor",
              keywords: ["big time"],
              text: "You see something the has some big time flavor"
            },
            %{
              id: "complex_flavor",
              keywords: ["this and that", "that and this", "this", "that"],
              text: "You see a little bit of this and a little bit of that"
            }
          ],
          exits: [ %{ direction: :north, to: "test_room2" } ],
        }
        "test_room2" -> %Zung.Game.Room{
          id: "test_room2",
          title: "The Second Test Room",
          description: "Another simple test room for testing units",
          flavor_texts: [],
          exits: [ %{ direction: :south, to: "test_room", description: "You glance down a tight and southern-winding hallway." } ],
        }
        "upper_left" -> %Zung.Game.Room{
          id: "upper_left",
          title: "North West Corner",
          description: "The northwestern corner of a big square room",
          flavor_texts: [],
          exits: [
            %{ direction: :east, to: "upper_right" },
            %{ direction: :south, to: "lower_left" },
          ],
        }
        "upper_right" -> %Zung.Game.Room{
          id: "upper_right",
          title: "North East Corner",
          description: "The northeastern corner of a big square room",
          flavor_texts: [],
          exits: [
            %{ direction: :west, to: "upper_left" },
            %{ direction: :south, to: "lower_right" },
          ],
        }
        "lower_left" -> %Zung.Game.Room{
          id: "lower_left",
          title: "South West Corner",
          description: "The southwestern corner of a big square room",
          flavor_texts: [],
          exits: [
            %{ direction: :east, to: "lower_right" },
            %{ direction: :north, to: "upper_left" },
          ],
        }
        "lower_right" -> %Zung.Game.Room{
          id: "lower_right",
          title: "South East Corner",
          description: "The southeastern corner of a big square room",
          flavor_texts: [],
          exits: [
            %{ direction: :west, to: "lower_left" },
            %{ direction: :north, to: "upper_right" },
          ],
        }
        "infinite_shaft_1" -> %Zung.Game.Room{
          id: "infinite_shaft_1",
          title: "Dark Mineshaft",
          description: "A deep dark and dirty mineshaft",
          flavor_texts: [],
          exits: [
            %{ direction: :up, to: "infinite_shaft_2" },
            %{ direction: :down, to: "infinite_shaft_2" },
          ],
        }
        "infinite_shaft_2" -> %Zung.Game.Room{
          id: "infinite_shaft_2",
          title: "Dark Mineshaft",
          description: "A deep dark and dirty mineshaft",
          flavor_texts: [],
          exits: [
            %{ direction: :up, to: "infinite_shaft_1" },
            %{ direction: :down, to: "infinite_shaft_1" },
          ],
        }
        _ -> %Zung.Game.Room{}
      end
    end
  end

  defp build_client(room_id, input_buffer \\ :queue.new) do
    default_client = Zung.Client.new(nil)
    default_client
      |> Map.put(:game_state, %Zung.Client.GameState{ username: "tim_allen", room: Zung.Game.Room.get_room(room_id), subscribed_channels: [ "ooc" ]})
      |> Map.put(:connection, %{default_client.connection | input_buffer: input_buffer})
  end

  mocked_test "no input do nothing loop" do
    # Arrange
    client = build_client("test_room")

    # Act
    actual_client = Game.do_game(client)

    # Assert
    assert actual_client.session_id === 1234
    assert actual_client.connection.id === 5678
    assert actual_client.game_state.username === "tim_allen"
  end

  mocked_test "garbage input" do
    # Arrange
    client = build_client("test_room", :queue.in("ladwijlaiwjd awkod awdj\n" , :queue.new))

    # Act
    actual_client = Game.do_game(client)

    # Assert
    assert :queue.is_empty(actual_client.connection.input_buffer)
    assert not :queue.is_empty(actual_client.connection.output_buffer)
    {:value, actual_output } = :queue.peek(actual_client.connection.output_buffer)
    assert actual_output === "||GRN||Wut?||RESET||"
  end

  mocked_test "simple look command" do
    # Arrange
    client = build_client("test_room", :queue.in("look\n" , :queue.new))

    # Act
    actual_client = Game.do_game(client)

    # Assert
    assert :queue.is_empty(actual_client.connection.input_buffer)
    assert not :queue.is_empty(actual_client.connection.output_buffer)
    {:value, actual_output } = :queue.peek(actual_client.connection.output_buffer)
    assert actual_output === """
||BOLD||||GRN||The Test Room||RESET||
   A simple test room for testing units
||BOLD||||CYA||-{ Exits: north }-||RESET||

"""
  end

  mocked_test "look at flavor command" do
    # Arrange
    client = build_client("test_room", :queue.in("look tasty\n" , :queue.new))

    # Act
    actual_client = Game.do_game(client)

    # Assert
    assert :queue.is_empty(actual_client.connection.input_buffer)
    assert not :queue.is_empty(actual_client.connection.output_buffer)
    {:value, actual_output } = :queue.peek(actual_client.connection.output_buffer)
    assert actual_output === "You see something quite flavorful"
  end

  mocked_test "look at missing flavor command" do
    # Arrange
    client = build_client("test_room", :queue.in("look absolute garbage\n" , :queue.new))

    # Act
    actual_client = Game.do_game(client)

    # Assert
    assert :queue.is_empty(actual_client.connection.input_buffer)
    assert not :queue.is_empty(actual_client.connection.output_buffer)
    {:value, actual_output } = :queue.peek(actual_client.connection.output_buffer)
    assert actual_output === "You see nothing of interest."
  end

  mocked_test "look at a direction with no exit command" do
    # Arrange
    client = build_client("test_room", :queue.in("look west\n" , :queue.new))

    # Act
    actual_client = Game.do_game(client)

    # Assert
    assert :queue.is_empty(actual_client.connection.input_buffer)
    assert not :queue.is_empty(actual_client.connection.output_buffer)
    {:value, actual_output } = :queue.peek(actual_client.connection.output_buffer)
    assert actual_output === "There is nothing of interest to see to the west."
  end

  mocked_test "look at uninteresting direction command" do
    # Arrange
    client = build_client("test_room", :queue.in("look north\n" , :queue.new))

    # Act
    actual_client = Game.do_game(client)

    # Assert
    assert :queue.is_empty(actual_client.connection.input_buffer)
    assert not :queue.is_empty(actual_client.connection.output_buffer)
    {:value, actual_output } = :queue.peek(actual_client.connection.output_buffer)
    assert actual_output === "Nothing to see, just an exit to the north."
  end

  mocked_test "look at descriptive direction command" do
    # Arrange
    client = build_client("test_room2", :queue.in("look south\n" , :queue.new))

    # Act
    actual_client = Game.do_game(client)

    # Assert
    assert :queue.is_empty(actual_client.connection.input_buffer)
    assert not :queue.is_empty(actual_client.connection.output_buffer)
    {:value, actual_output } = :queue.peek(actual_client.connection.output_buffer)
    assert actual_output === "You glance down a tight and southern-winding hallway."
  end

  mocked_test "move north" do
    # Arrange
    client = build_client("test_room", :queue.in("north\n" , :queue.new))

    # Act
    actual_client = Game.do_game(client)

    # Assert
    assert actual_client.game_state.room.id === "test_room2"
  end

  mocked_test "move invalid direction" do
    # Arrange
    client = build_client("test_room2", :queue.in("north\n" , :queue.new))

    # Act
    actual_client = Game.do_game(client)

    # Assert
    assert :queue.is_empty(actual_client.connection.input_buffer)
    assert not :queue.is_empty(actual_client.connection.output_buffer)
    {:value, actual_output } = :queue.peek(actual_client.connection.output_buffer)
    assert actual_output === "There is no where to go in that direction."
    assert actual_client.game_state.room.id === "test_room2"
  end

  mocked_test "walk the square" do
    # Arrange
    # client setup to walk east then south then west then north around the square
    client = build_client("upper_left", :queue.in("north\n" ,:queue.in("west\n" ,:queue.in("south\n" ,:queue.in("east\n" , :queue.new)))))

    # Act
    actual_client_east = Game.do_game(client)
    actual_client_south = Game.do_game(actual_client_east)
    actual_client_west = Game.do_game(actual_client_south)
    actual_client_north = Game.do_game(actual_client_west)

    # Assert
    assert client.game_state.room.id === "upper_left"
    assert actual_client_east.game_state.room.id === "upper_right"
    assert actual_client_south.game_state.room.id === "lower_right"
    assert actual_client_west.game_state.room.id === "lower_left"
    assert actual_client_north.game_state.room.id === "upper_left"
  end

  mocked_test "climb the square" do
    # Arrange
    # client setup to walk east then south then west then north around the square
    client = build_client("infinite_shaft_1", :queue.in("down\n" ,:queue.in("up\n" , :queue.new)))

    # Act
    actual_client_up = Game.do_game(client)
    actual_client_down = Game.do_game(actual_client_up)

    # Assert
    assert client.game_state.room.id === "infinite_shaft_1"
    assert actual_client_up.game_state.room.id === "infinite_shaft_2"
    assert actual_client_down.game_state.room.id === "infinite_shaft_1"
  end

  mocked_test "quit the game" do
    # Arrange
    client = build_client("upper_left", :queue.in("quit\n" , :queue.new))

    # Act
    do_game = fn -> Game.do_game(client) end

    # Assert
    assert_raise(Zung.Error.Connection.Closed, do_game)
  end

  mocked_test "csay missing channel, test bad parse" do
    # Arrange
    client = build_client("test_room", :queue.in("csay\n" , :queue.new))

    # Act
    actual_client = Game.do_game(client)

    # Assert
    assert :queue.is_empty(actual_client.connection.input_buffer)
    assert not :queue.is_empty(actual_client.connection.output_buffer)
    {:value, actual_output } = :queue.peek(actual_client.connection.output_buffer)
    assert actual_output === "||RED||You must specify a channel and message.||RESET||"
  end

  mocked_test "csay to ooc" do
    # Arrange
    client = build_client("test_room", :queue.in("csay ooc howdy y'all\n" , :queue.new))

    # Act
    actual_client = Game.do_game(client)

    # Assert
    assert :queue.is_empty(actual_client.connection.input_buffer)
    assert :queue.is_empty(actual_client.connection.output_buffer)
  end
end
