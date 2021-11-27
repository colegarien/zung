defmodule Zung.State.Game.GameTest do
  use ExUnit.Case, async: true
  use MecksUnit.Case

  alias Zung.State.Game.Game

  defmock Zung.Client, preserve: true do
    def new(_socket) do
      %Zung.Client {
        session_id: 1234,
        connection_id: 5678,
      }
    end

    def flush_output(%Zung.Client{} = client) do
      # don't actually flush output so we can pick at it during testing
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
        _ -> %Zung.Game.Room{}
      end
    end
  end

  mocked_test "no input do nothing loop" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil) |
      game_state: %Zung.Client.GameState{ username: "tim_allen", room: Zung.Game.Room.get_room("test_room") },
    }

    # Act
    actual_client = Game.do_game(client)

    # Assert
    assert actual_client.session_id === 1234
    assert actual_client.connection_id === 5678
    assert actual_client.game_state.username === "tim_allen"
  end

  mocked_test "garbage input" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil) |
      game_state: %Zung.Client.GameState{ username: "tim_allen", room: Zung.Game.Room.get_room("test_room") },
      input_buffer: :queue.in("ladwijlaiwjd awkod awdj\n" , :queue.new),
    }

    # Act
    actual_client = Game.do_game(client)

    # Assert
    assert :queue.is_empty(actual_client.input_buffer)
    assert not :queue.is_empty(actual_client.output_buffer)
    {:value, actual_output } = :queue.peek(actual_client.output_buffer)
    assert actual_output === "||GRN||Wut?||RESET||"
  end

  mocked_test "simple look command" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil) |
      game_state: %Zung.Client.GameState{ username: "tim_allen", room: Zung.Game.Room.get_room("test_room") },
      input_buffer: :queue.in("look\n" , :queue.new),
    }

    # Act
    actual_client = Game.do_game(client)

    # Assert
    assert :queue.is_empty(actual_client.input_buffer)
    assert not :queue.is_empty(actual_client.output_buffer)
    {:value, actual_output } = :queue.peek(actual_client.output_buffer)
    assert actual_output === """
||BOLD||||GRN||The Test Room||RESET||
   A simple test room for testing units
||BOLD||||CYA||-{ Exits: north }-||RESET||

"""
  end

  mocked_test "look at flavor command" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil) |
      game_state: %Zung.Client.GameState{ username: "tim_allen", room: Zung.Game.Room.get_room("test_room") },
      input_buffer: :queue.in("look tasty\n" , :queue.new),
    }

    # Act
    actual_client = Game.do_game(client)

    # Assert
    assert :queue.is_empty(actual_client.input_buffer)
    assert not :queue.is_empty(actual_client.output_buffer)
    {:value, actual_output } = :queue.peek(actual_client.output_buffer)
    assert actual_output === "You see something quite flavorful"
  end

  mocked_test "look at missing flavor command" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil) |
      game_state: %Zung.Client.GameState{ username: "tim_allen", room: Zung.Game.Room.get_room("test_room") },
      input_buffer: :queue.in("look absolute garbage\n" , :queue.new),
    }

    # Act
    actual_client = Game.do_game(client)

    # Assert
    assert :queue.is_empty(actual_client.input_buffer)
    assert not :queue.is_empty(actual_client.output_buffer)
    {:value, actual_output } = :queue.peek(actual_client.output_buffer)
    assert actual_output === "You see nothing of interest."
  end

  mocked_test "look at a direction with no exit command" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil) |
      game_state: %Zung.Client.GameState{ username: "tim_allen", room: Zung.Game.Room.get_room("test_room") },
      input_buffer: :queue.in("look west\n" , :queue.new),
    }

    # Act
    actual_client = Game.do_game(client)

    # Assert
    assert :queue.is_empty(actual_client.input_buffer)
    assert not :queue.is_empty(actual_client.output_buffer)
    {:value, actual_output } = :queue.peek(actual_client.output_buffer)
    assert actual_output === "There is nothing of interest to see to the west."
  end

  mocked_test "look at uninteresting direction command" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil) |
      game_state: %Zung.Client.GameState{ username: "tim_allen", room: Zung.Game.Room.get_room("test_room") },
      input_buffer: :queue.in("look north\n" , :queue.new),
    }

    # Act
    actual_client = Game.do_game(client)

    # Assert
    assert :queue.is_empty(actual_client.input_buffer)
    assert not :queue.is_empty(actual_client.output_buffer)
    {:value, actual_output } = :queue.peek(actual_client.output_buffer)
    assert actual_output === "Nothing to see, just an exit to the north."
  end

  mocked_test "look at descriptive direction command" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil) |
      game_state: %Zung.Client.GameState{ username: "tim_allen", room: Zung.Game.Room.get_room("test_room2") },
      input_buffer: :queue.in("look south\n" , :queue.new),
    }

    # Act
    actual_client = Game.do_game(client)

    # Assert
    assert :queue.is_empty(actual_client.input_buffer)
    assert not :queue.is_empty(actual_client.output_buffer)
    {:value, actual_output } = :queue.peek(actual_client.output_buffer)
    assert actual_output === "You glance down a tight and southern-winding hallway."
  end

  mocked_test "move north" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil) |
      game_state: %Zung.Client.GameState{ username: "tim_allen", room: Zung.Game.Room.get_room("test_room") },
      input_buffer: :queue.in("north\n" , :queue.new),
    }

    # Act
    actual_client = Game.do_game(client)

    # Assert
    assert actual_client.game_state.room.id === "test_room2"
  end

  mocked_test "move invalid direction" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil) |
      game_state: %Zung.Client.GameState{ username: "tim_allen", room: Zung.Game.Room.get_room("test_room2") },
      input_buffer: :queue.in("north\n" , :queue.new),
    }

    # Act
    actual_client = Game.do_game(client)

    # Assert
    assert :queue.is_empty(actual_client.input_buffer)
    assert not :queue.is_empty(actual_client.output_buffer)
    {:value, actual_output } = :queue.peek(actual_client.output_buffer)
    assert actual_output === "There is no where to go in that direction."
    assert actual_client.game_state.room.id === "test_room2"
  end

  mocked_test "walk the square" do
    # Arrange
    # client setup to walk east then south then west then north around the square
    client = %Zung.Client{
      Zung.Client.new(nil) |
      game_state: %Zung.Client.GameState{ username: "tim_allen", room: Zung.Game.Room.get_room("upper_left") },
      input_buffer: :queue.in("north\n" ,:queue.in("west\n" ,:queue.in("south\n" ,:queue.in("east\n" , :queue.new)))),
    }

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

  mocked_test "quit the game" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil) |
      game_state: %Zung.Client.GameState{ username: "tim_allen", room: Zung.Game.Room.get_room("upper_left") },
      input_buffer: :queue.in("quit\n" , :queue.new),
    }

    # Act
    do_game = fn -> Game.do_game(client) end

    # Assert
    assert_raise(Zung.Error.Connection.Closed, do_game)
  end

end
