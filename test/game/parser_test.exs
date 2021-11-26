defmodule Zung.Game.ParserTest do
  use ExUnit.Case, async: true
  use MecksUnit.Case

  alias Zung.Game.Parser

  defmock Zung.Client, preserve: true do
    def new(_socket) do
      %Zung.Client {
        session_id: 1234,
        connection_id: 5678,
      }
    end
  end

  mocked_test "no input is an unknown command" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil) |
      game_state: %Zung.Client.GameState{ username: "tim_allen", room_id: "test_room" },
    }
    input = ""

    # Act
    actual = Parser.parse(client, input)

    # Assert
    assert actual === :unknown_command
  end

  mocked_test "look/0 test" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil) |
      game_state: %Zung.Client.GameState{ username: "tim_allen", room_id: "test_room" },
    }
    input = "look"

    # Act
    actual = Parser.parse(client, input)

    # Assert
    assert actual === {:look, {:room, "test_room"}}
  end

  mocked_test "north/0 test" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil) |
      game_state: %Zung.Client.GameState{ username: "tim_allen", room_id: "test_room" },
    }
    input = "north"

    # Act
    actual = Parser.parse(client, input)

    # Assert
    assert actual === {:move, {:direction, :north}}
  end

  mocked_test "south/0 test" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil) |
      game_state: %Zung.Client.GameState{ username: "tim_allen", room_id: "test_room" },
    }
    input = "south"

    # Act
    actual = Parser.parse(client, input)

    # Assert
    assert actual === {:move, {:direction, :south}}
  end

  mocked_test "east/0 test" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil) |
      game_state: %Zung.Client.GameState{ username: "tim_allen", room_id: "test_room" },
    }
    input = "east"

    # Act
    actual = Parser.parse(client, input)

    # Assert
    assert actual === {:move, {:direction, :east}}
  end

  mocked_test "west/0 test" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil) |
      game_state: %Zung.Client.GameState{ username: "tim_allen", room_id: "test_room" },
    }
    input = "west"

    # Act
    actual = Parser.parse(client, input)

    # Assert
    assert actual === {:move, {:direction, :west}}
  end

  mocked_test "quit/0 test" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil) |
      game_state: %Zung.Client.GameState{ username: "tim_allen", room_id: "test_room" },
    }
    input = "quit"

    # Act
    actual = Parser.parse(client, input)

    # Assert
    assert actual === :quit
  end
end
