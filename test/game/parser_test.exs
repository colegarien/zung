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

  @test_room %Zung.Game.Room{
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

  mocked_test "no input is an unknown command" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil) |
      game_state: %Zung.Client.GameState{ username: "tim_allen", room: @test_room },
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
      game_state: %Zung.Client.GameState{ username: "tim_allen", room: @test_room },
    }
    input = "look"

    # Act
    actual = Parser.parse(client, input)

    # Assert
    assert actual === {:look, @test_room}
  end

  mocked_test "look/1 unknown flavor test" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil) |
      game_state: %Zung.Client.GameState{ username: "tim_allen", room: @test_room },
    }
    input = "look some straight garbage"

    # Act
    actual = Parser.parse(client, input)

    # Assert
    assert actual === {:look, @test_room, {:flavor, ""}}
  end

  mocked_test "look/1 direct flavor reference test" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil) |
      game_state: %Zung.Client.GameState{ username: "tim_allen", room: @test_room },
    }
    input = "look simple_flavor"

    # Act
    actual = Parser.parse(client, input)

    # Assert
    assert actual === {:look, @test_room, {:flavor, "simple_flavor"}}
  end

  mocked_test "look/1 simple flavor test" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil) |
      game_state: %Zung.Client.GameState{ username: "tim_allen", room: @test_room },
    }
    input = "look tasty"

    # Act
    actual = Parser.parse(client, input)

    # Assert
    assert actual === {:look, @test_room, {:flavor, "simple_flavor"}}
  end

  mocked_test "look/1 compound flavor test" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil) |
      game_state: %Zung.Client.GameState{ username: "tim_allen", room: @test_room },
    }
    input = "look big time"

    # Act
    actual = Parser.parse(client, input)

    # Assert
    assert actual === {:look, @test_room, {:flavor, "compound_flavor"}}
  end

  mocked_test "look/1 complex flavor test" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil) |
      game_state: %Zung.Client.GameState{ username: "tim_allen", room: @test_room },
    }
    input_a = "look this and that"
    input_b = "look that and this"
    input_c = "look this"
    input_d = "look that"

    # Act
    actual_a = Parser.parse(client, input_a)
    actual_b = Parser.parse(client, input_b)
    actual_c = Parser.parse(client, input_c)
    actual_d = Parser.parse(client, input_d)

    # Assert
    assert actual_a === {:look, @test_room, {:flavor, "complex_flavor"}}
    assert actual_b === {:look, @test_room, {:flavor, "complex_flavor"}}
    assert actual_c === {:look, @test_room, {:flavor, "complex_flavor"}}
    assert actual_d === {:look, @test_room, {:flavor, "complex_flavor"}}
  end

  mocked_test "look/1 direction test" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil) |
      game_state: %Zung.Client.GameState{ username: "tim_allen", room: @test_room },
    }
    input_north = "look north"
    input_south = "look south"
    input_east = "look east"
    input_west = "look west"

    # Act
    actual_north = Parser.parse(client, input_north)
    actual_south = Parser.parse(client, input_south)
    actual_east = Parser.parse(client, input_east)
    actual_west = Parser.parse(client, input_west)

    # Assert
    assert actual_north === {:look, @test_room, {:direction, :north}}
    assert actual_south === {:look, @test_room, {:direction, :south}}
    assert actual_east === {:look, @test_room, {:direction, :east}}
    assert actual_west === {:look, @test_room, {:direction, :west}}
  end

  mocked_test "north/0 test" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil) |
      game_state: %Zung.Client.GameState{ username: "tim_allen", room: @test_room },
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
      game_state: %Zung.Client.GameState{ username: "tim_allen", room: @test_room },
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
      game_state: %Zung.Client.GameState{ username: "tim_allen", room: @test_room },
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
      game_state: %Zung.Client.GameState{ username: "tim_allen", room: @test_room },
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
      game_state: %Zung.Client.GameState{ username: "tim_allen", room: @test_room },
    }
    input = "quit"

    # Act
    actual = Parser.parse(client, input)

    # Assert
    assert actual === :quit
  end
end
