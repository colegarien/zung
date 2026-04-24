defmodule Zung.Game.ParserTest do
  use ExUnit.Case, async: true
  use MecksUnit.Case

  alias Zung.Game.Parser

  defmock Zung.Client, preserve: true do
    def new(_socket) do
      %Zung.Client{
        session_id: 1234,
        connection: %Zung.Client.Connection{id: 5678}
      }
    end
  end

  @test_room %Zung.Game.Room{
    id: "test_room",
    title: "The Test Room",
    description: "A simple test room for testing units",
    search_text: "You find a hidden compartment behind the wall.",
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
    exits: [
      %Zung.Game.Room.Exit{direction: :north, to: "test_room2"},
      %Zung.Game.Room.Exit{direction: :south, name: "named door", to: "test_room3"},
      %Zung.Game.Room.Exit{name: "custom exit door", to: "test_room3"},
      %Zung.Game.Room.Exit{direction: :west, to: "test_room4", state: :locked, key_id: "old_key"},
      %Zung.Game.Room.Exit{direction: :east, to: "test_room5", state: :closed}
    ],
    objects: [
      %Zung.Game.Object{
        id: "large_fountain",
        name: "a large fountain",
        description: "A large, glorious fountain is protuding from the ground here.",
        keywords: ["glorious fountain", "large fountain", "fountain"]
      },
      %Zung.Game.Object{
        id: "old_book",
        name: "an old book",
        description: "An old, dusty book lies here.",
        keywords: ["old book", "book"],
        read_text: "The pages tell a tale of a forgotten kingdom.",
        use_text: "You flip through the book absent-mindedly."
      }
    ],
    npcs: [
      %Zung.Game.Npc{
        id: "old_man",
        name: "An old man",
        keywords: ["old man", "man"],
        greeting: "The old man nods at you.",
        topics: %{
          "weather" => "He looks at the sky and shrugs.",
          "fountain" => "He points at the fountain and smiles."
        }
      }
    ]
  }

  mocked_test "no input is an unknown command" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
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
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
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
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
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
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
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
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
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
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
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
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
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
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    input_north = "look north"
    input_south = "look south"
    input_east = "look east"
    input_west = "look west"
    input_up = "look up"
    input_down = "look down"

    # Act
    actual_north = Parser.parse(client, input_north)
    actual_south = Parser.parse(client, input_south)
    actual_east = Parser.parse(client, input_east)
    actual_west = Parser.parse(client, input_west)
    actual_up = Parser.parse(client, input_up)
    actual_down = Parser.parse(client, input_down)

    # Assert
    assert actual_north === {:look, @test_room, {:direction, :north}}
    assert actual_south === {:look, @test_room, {:direction, :south}}
    assert actual_east === {:look, @test_room, {:direction, :east}}
    assert actual_west === {:look, @test_room, {:direction, :west}}
    assert actual_up === {:look, @test_room, {:direction, :up}}
    assert actual_down === {:look, @test_room, {:direction, :down}}
  end

  mocked_test "look/1 object id test" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    input = "look large_fountain"

    # Act
    actual = Parser.parse(client, input)

    # Assert
    # keywords: ["glorious fountain", "large fountain", "fountain"]
    assert actual === {:look, @test_room, {:object, "large_fountain"}}
  end

  mocked_test "look/1 object keywords test" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    input_a = "look glorious fountain"
    input_b = "look large fountain"
    input_c = "look fountain"

    # Act
    actual_a = Parser.parse(client, input_a)
    actual_b = Parser.parse(client, input_b)
    actual_c = Parser.parse(client, input_c)

    # Assert
    assert actual_a === {:look, @test_room, {:object, "large_fountain"}}
    assert actual_b === {:look, @test_room, {:object, "large_fountain"}}
    assert actual_c === {:look, @test_room, {:object, "large_fountain"}}
  end

  mocked_test "north/0 test" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
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
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
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
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
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
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    input = "west"

    # Act
    actual = Parser.parse(client, input)

    # Assert
    assert actual === {:move, {:direction, :west}}
  end

  mocked_test "up/0 test" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    input = "up"

    # Act
    actual = Parser.parse(client, input)

    # Assert
    assert actual === {:move, {:direction, :up}}
  end

  mocked_test "down/0 test" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    input = "down"

    # Act
    actual = Parser.parse(client, input)

    # Assert
    assert actual === {:move, {:direction, :down}}
  end

  mocked_test "quit/0 test" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    input = "quit"

    # Act
    actual = Parser.parse(client, input)

    # Assert
    assert actual === :quit
  end

  mocked_test "aliases - look and direction test" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    input_north = "l n"
    input_south = "l s"
    input_east = "l e"
    input_west = "l w"
    input_up = "l u"
    input_down = "l d"

    # Act
    actual_north = Parser.parse(client, input_north)
    actual_south = Parser.parse(client, input_south)
    actual_east = Parser.parse(client, input_east)
    actual_west = Parser.parse(client, input_west)
    actual_up = Parser.parse(client, input_up)
    actual_down = Parser.parse(client, input_down)

    # Assert
    assert actual_north === {:look, @test_room, {:direction, :north}}
    assert actual_south === {:look, @test_room, {:direction, :south}}
    assert actual_east === {:look, @test_room, {:direction, :east}}
    assert actual_west === {:look, @test_room, {:direction, :west}}
    assert actual_up === {:look, @test_room, {:direction, :up}}
    assert actual_down === {:look, @test_room, {:direction, :down}}
  end

  mocked_test "no aliases do unknown command" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{
          username: "tim_allen",
          room: @test_room,
          command_aliases: %{}
        }
    }

    input = "l"

    # Act
    actual = Parser.parse(client, input)

    # Assert
    assert actual === :unknown_command
  end

  mocked_test "multi-word aliases work" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{
          username: "tim_allen",
          room: @test_room,
          command_aliases: %{
            "this is a big one" => "look"
          }
        }
    }

    input = "this is a big one this and that"

    # Act
    actual = Parser.parse(client, input)

    # Assert
    assert actual === {:look, @test_room, {:flavor, "complex_flavor"}}
  end

  mocked_test "look allow syntactic sugar words test" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    input = "look at the tasty"

    # Act
    actual = Parser.parse(client, input)

    # Assert
    assert actual === {:look, @test_room, {:flavor, "simple_flavor"}}
  end

  mocked_test "csay missing chat_room do bad_parse" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    input = "csay"

    # Act
    actual = Parser.parse(client, input)

    # Assert
    assert actual === {:bad_parse, "You must specify a chat and message."}
  end

  mocked_test "csay non-subscribed chat_room do bad_parse" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    input = "csay bad_chat_room hi all"

    # Act
    actual = Parser.parse(client, input)

    # Assert
    assert actual === {:bad_parse, "You are not part of the \"bad_chat_room\" chat."}
  end

  mocked_test "csay to a subscribed chat_room" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{
          username: "tim_allen",
          room: @test_room,
          joined_chat_rooms: ["ooc"]
        }
    }

    input = "csay ooc hi all"

    # Act
    actual = Parser.parse(client, input)

    # Assert
    assert actual === {:csay, :ooc, "hi all"}
  end

  mocked_test "ooc alias to a ooc chat_room" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{
          username: "tim_allen",
          room: @test_room,
          joined_chat_rooms: ["ooc"]
        }
    }

    input = "ooc hi all in ooc"

    # Act
    actual = Parser.parse(client, input)

    # Assert
    assert actual === {:csay, :ooc, "hi all in ooc"}
  end

  mocked_test "look/1 at named exits" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    input_directional = "look at named door"
    input_custom = "look at the custom exit door"

    # Act
    actual_directional = Parser.parse(client, input_directional)
    actual_custom = Parser.parse(client, input_custom)

    # Assert
    assert actual_directional === {:look, @test_room, {:exit, "named door"}}
    assert actual_custom === {:look, @test_room, {:exit, "custom exit door"}}
  end

  mocked_test "enter/1 missing exit name error" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    input = "enter"

    # Act
    actual = Parser.parse(client, input)

    # Assert
    assert actual === {:bad_parse, "You must specify an exit."}
  end

  mocked_test "enter/1 but exit name doesnt exist" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    input = "enter fake door"

    # Act
    actual = Parser.parse(client, input)

    # Assert
    assert actual === {:move, {:exit, ""}}
  end

  mocked_test "enter/1 specify a directional named exit" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    input = "enter named door"

    # Act
    actual = Parser.parse(client, input)

    # Assert
    assert actual === {:move, {:exit, "named door"}}
  end

  mocked_test "enter/1 specify a custom named exit" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    input = "enter custom exit door"

    # Act
    actual = Parser.parse(client, input)

    # Assert
    assert actual === {:move, {:exit, "custom exit door"}}
  end

  mocked_test "enter/1 specify a direction" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    input = "enter north"

    # Act
    actual = Parser.parse(client, input)

    # Assert
    assert actual === {:move, {:direction, :north}}
  end

  mocked_test "enter/1 specify a direction alias" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    input = "enter n"

    # Act
    actual = Parser.parse(client, input)

    # Assert
    assert actual === {:move, {:direction, :north}}
  end

  mocked_test "say/1 no message bad parse" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    input = "say"

    # Act
    actual = Parser.parse(client, input)

    # Assert
    assert actual === {:bad_parse, "You must specify a message."}
  end

  mocked_test "say/1 to room" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    input = "say hi all!"

    # Act
    actual = Parser.parse(client, input)

    # Assert
    assert actual === {:say, @test_room, "hi all!"}
  end

  mocked_test "help/0 test" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    input = "help"

    # Act
    actual = Parser.parse(client, input)

    # Assert
    assert actual === {:help}
  end

  mocked_test "help/1 test" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    input = "help look"

    # Act
    actual = Parser.parse(client, input)

    # Assert
    assert actual === {:help, "look"}
  end

  mocked_test "who/0 test" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    input = "who"

    # Act
    actual = Parser.parse(client, input)

    # Assert
    assert actual === :who
  end

  mocked_test "examine/1 object id test" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    input = "examine large_fountain"

    # Act
    actual = Parser.parse(client, input)

    # Assert
    assert actual === {:examine, @test_room, {:object, "large_fountain"}}
  end

  mocked_test "examine/1 object keyword test" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    input = "examine fountain"

    # Act
    actual = Parser.parse(client, input)

    # Assert
    assert actual === {:examine, @test_room, {:object, "large_fountain"}}
  end

  mocked_test "examine/0 no target bad parse test" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    input = "examine"

    # Act
    actual = Parser.parse(client, input)

    # Assert
    assert actual === {:bad_parse, "What do you want to examine?"}
  end

  mocked_test "x alias for examine test" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    input = "x fountain"

    # Act
    actual = Parser.parse(client, input)

    # Assert
    assert actual === {:examine, @test_room, {:object, "large_fountain"}}
  end

  mocked_test "get/1 object by keyword test" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    input = "get fountain"

    # Act
    actual = Parser.parse(client, input)

    # Assert
    assert actual === {:get, @test_room, "large_fountain"}
  end

  mocked_test "get/1 with articles test" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    input = "get the fountain"

    # Act
    actual = Parser.parse(client, input)

    # Assert
    assert actual === {:get, @test_room, "large_fountain"}
  end

  mocked_test "get/0 no target bad parse test" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    input = "get"

    # Act
    actual = Parser.parse(client, input)

    # Assert
    assert actual === {:bad_parse, "What do you want to pick up?"}
  end

  mocked_test "get/1 nonexistent object bad parse test" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    input = "get nonexistent"

    # Act
    actual = Parser.parse(client, input)

    # Assert
    assert actual === {:bad_parse, "You don't see that here."}
  end

  mocked_test "take/1 alias for get test" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    input = "take fountain"

    # Act
    actual = Parser.parse(client, input)

    # Assert
    assert actual === {:get, @test_room, "large_fountain"}
  end

  mocked_test "drop/1 item from inventory test" do
    # Arrange
    item = %Zung.Game.Object{
      id: "magic_sword",
      name: "a magic sword",
      description: "A shiny magic sword.",
      keywords: ["magic sword", "sword"]
    }

    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{
          username: "tim_allen",
          room: @test_room,
          inventory: [item]
        }
    }

    input = "drop sword"

    # Act
    actual = Parser.parse(client, input)

    # Assert
    assert actual === {:drop, @test_room, "magic_sword"}
  end

  mocked_test "drop/0 no target bad parse test" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    input = "drop"

    # Act
    actual = Parser.parse(client, input)

    # Assert
    assert actual === {:bad_parse, "What do you want to drop?"}
  end

  mocked_test "drop/1 nonexistent item bad parse test" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    input = "drop nonexistent"

    # Act
    actual = Parser.parse(client, input)

    # Assert
    assert actual === {:bad_parse, "You don't have that."}
  end

  mocked_test "inventory/0 test" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    input = "inventory"

    # Act
    actual = Parser.parse(client, input)

    # Assert
    assert actual === :inventory
  end

  mocked_test "i alias for inventory test" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    input = "i"

    # Act
    actual = Parser.parse(client, input)

    # Assert
    assert actual === :inventory
  end

  # -- Tier 2: read --

  mocked_test "read/1 object by keyword test" do
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    actual = Parser.parse(client, "read book")
    assert actual === {:read, @test_room, "old_book"}
  end

  mocked_test "read/0 no target bad parse test" do
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    actual = Parser.parse(client, "read")
    assert actual === {:bad_parse, "What do you want to read?"}
  end

  mocked_test "read/1 nonexistent object bad parse test" do
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    actual = Parser.parse(client, "read nonexistent")
    assert actual === {:bad_parse, "You don't see that here."}
  end

  mocked_test "read/1 inventory item test" do
    item = %Zung.Game.Object{
      id: "scroll",
      name: "a scroll",
      description: "A scroll.",
      keywords: ["scroll"],
      read_text: "The scroll reads: beware."
    }

    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{
          username: "tim_allen",
          room: @test_room,
          inventory: [item]
        }
    }

    actual = Parser.parse(client, "read scroll")
    assert actual === {:read, @test_room, "scroll"}
  end

  # -- Tier 2: search --

  mocked_test "search/0 test" do
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    actual = Parser.parse(client, "search")
    assert actual === {:search, @test_room}
  end

  # -- Tier 2: use --

  mocked_test "use/1 object by keyword test" do
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    actual = Parser.parse(client, "use book")
    assert actual === {:use, @test_room, "old_book"}
  end

  mocked_test "use/0 no target bad parse test" do
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    actual = Parser.parse(client, "use")
    assert actual === {:bad_parse, "What do you want to use?"}
  end

  mocked_test "use/1 nonexistent object bad parse test" do
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    actual = Parser.parse(client, "use nonexistent")
    assert actual === {:bad_parse, "You don't see that here."}
  end

  mocked_test "use/2 object on target test" do
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    actual = Parser.parse(client, "use book on fountain")
    assert actual === {:use_on, @test_room, "old_book", {:object, "large_fountain"}}
  end

  mocked_test "use/2 on with no target bad parse test" do
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    actual = Parser.parse(client, "use book on")
    assert actual === {:bad_parse, "Use it on what?"}
  end

  # -- Tier 2: open / close / lock / unlock --

  mocked_test "open/1 direction test" do
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    actual = Parser.parse(client, "open east")
    assert actual === {:open, @test_room, {:direction, :east}}
  end

  mocked_test "open/1 named exit test" do
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    actual = Parser.parse(client, "open named door")
    assert actual === {:open, @test_room, {:exit, "named door"}}
  end

  mocked_test "open/0 no target bad parse test" do
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    actual = Parser.parse(client, "open")
    assert actual === {:bad_parse, "What do you want to open?"}
  end

  mocked_test "open/1 nonexistent exit bad parse test" do
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    actual = Parser.parse(client, "open fake door")
    assert actual === {:bad_parse, "You don't see that here."}
  end

  mocked_test "close/1 direction test" do
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    actual = Parser.parse(client, "close north")
    assert actual === {:close, @test_room, {:direction, :north}}
  end

  mocked_test "unlock/1 direction test" do
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    actual = Parser.parse(client, "unlock west")
    assert actual === {:unlock, @test_room, {:direction, :west}}
  end

  mocked_test "lock/1 direction test" do
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    actual = Parser.parse(client, "lock west")
    assert actual === {:lock, @test_room, {:direction, :west}}
  end

  # -- Tier 2: talk / ask --

  mocked_test "talk/1 npc by keyword test" do
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    actual = Parser.parse(client, "talk old man")
    assert actual === {:talk, @test_room, "old_man"}
  end

  mocked_test "talk/1 npc by id test" do
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    actual = Parser.parse(client, "talk old_man")
    assert actual === {:talk, @test_room, "old_man"}
  end

  mocked_test "talk/0 no target bad parse test" do
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    actual = Parser.parse(client, "talk")
    assert actual === {:bad_parse, "Who do you want to talk to?"}
  end

  mocked_test "talk/1 nonexistent npc bad parse test" do
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    actual = Parser.parse(client, "talk ghost")
    assert actual === {:bad_parse, "You don't see anyone by that name."}
  end

  mocked_test "talk/1 with syntactic sugar words test" do
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    actual = Parser.parse(client, "talk to the old man")
    assert actual === {:talk, @test_room, "old_man"}
  end

  mocked_test "ask/2 npc about topic test" do
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    actual = Parser.parse(client, "ask man about weather")
    assert actual === {:ask, @test_room, "old_man", "weather"}
  end

  mocked_test "ask/2 npc about multi-word topic test" do
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    actual = Parser.parse(client, "ask old man about the fountain")
    assert actual === {:ask, @test_room, "old_man", "fountain"}
  end

  mocked_test "ask/0 no about keyword bad parse test" do
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    actual = Parser.parse(client, "ask man weather")
    assert actual === {:bad_parse, "Try: ask <person> about <topic>"}
  end

  mocked_test "ask/1 no topic bad parse test" do
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    actual = Parser.parse(client, "ask man about")
    assert actual === {:bad_parse, "What do you want to ask about?"}
  end

  mocked_test "ask/2 nonexistent npc bad parse test" do
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    actual = Parser.parse(client, "ask ghost about weather")
    assert actual === {:bad_parse, "You don't see anyone by that name."}
  end

  # -- Tier 3: alias / unalias --

  mocked_test "alias/0 list aliases test" do
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    actual = Parser.parse(client, "alias")
    assert actual === :list_aliases
  end

  mocked_test "alias/1 one arg bad parse test" do
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    actual = Parser.parse(client, "alias hw")
    assert actual === {:bad_parse, "Usage: alias <name> <command>"}
  end

  mocked_test "alias/2 set alias test" do
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    actual = Parser.parse(client, "alias hw help who")
    assert actual === {:set_alias, "hw", "help who"}
  end

  mocked_test "unalias/0 no args bad parse test" do
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    actual = Parser.parse(client, "unalias")
    assert actual === {:bad_parse, "Usage: unalias <name>"}
  end

  mocked_test "unalias/1 remove alias test" do
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    actual = Parser.parse(client, "unalias hw")
    assert actual === {:remove_alias, "hw"}
  end

  # -- Tier 3: emote / me --

  mocked_test "emote/1 with text test" do
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    actual = Parser.parse(client, "emote waves hello")
    assert actual === {:emote, @test_room, "waves hello"}
  end

  mocked_test "me/1 alias for emote test" do
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    actual = Parser.parse(client, "me dances")
    assert actual === {:emote, @test_room, "dances"}
  end

  mocked_test "emote/0 no args bad parse test" do
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    actual = Parser.parse(client, "emote")
    assert actual === {:bad_parse, "What do you want to do?"}
  end

  mocked_test "bow built-in emote test" do
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    assert Parser.parse(client, "bow") === {:emote, @test_room, "bows gracefully."}
    assert Parser.parse(client, "wave") === {:emote, @test_room, "waves."}
    assert Parser.parse(client, "nod") === {:emote, @test_room, "nods."}
    assert Parser.parse(client, "shrug") === {:emote, @test_room, "shrugs."}
  end

  # -- Tier 3: shout / yell --

  mocked_test "shout/1 with message test" do
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    actual = Parser.parse(client, "shout hello everyone")
    assert actual === {:shout, @test_room, "hello everyone"}
  end

  mocked_test "yell/1 alias for shout test" do
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    actual = Parser.parse(client, "yell watch out")
    assert actual === {:shout, @test_room, "watch out"}
  end

  mocked_test "shout/0 no args bad parse test" do
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    actual = Parser.parse(client, "shout")
    assert actual === {:bad_parse, "What do you want to shout?"}
  end

  # -- Tier 3: whisper --

  mocked_test "whisper/2 with target and message test" do
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    actual = Parser.parse(client, "whisper bob hey there")
    assert actual === {:whisper, @test_room, "bob", "hey there"}
  end

  mocked_test "whisper/2 with to sugar word test" do
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    actual = Parser.parse(client, "whisper to bob secret stuff")
    assert actual === {:whisper, @test_room, "bob", "secret stuff"}
  end

  mocked_test "whisper/0 no args bad parse test" do
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    actual = Parser.parse(client, "whisper")
    assert actual === {:bad_parse, "Usage: whisper <player> <message>"}
  end

  mocked_test "whisper/1 only target no message bad parse test" do
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    actual = Parser.parse(client, "whisper bob")
    assert actual === {:bad_parse, "Usage: whisper <player> <message>"}
  end

  # -- Tier 3: tell --

  mocked_test "tell/2 with target and message test" do
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    actual = Parser.parse(client, "tell bob hello there")
    assert actual === {:tell, "bob", "hello there"}
  end

  mocked_test "tell/0 no args bad parse test" do
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    actual = Parser.parse(client, "tell")
    assert actual === {:bad_parse, "Usage: tell <player> <message>"}
  end

  mocked_test "tell/1 only target bad parse test" do
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    actual = Parser.parse(client, "tell bob")
    assert actual === {:bad_parse, "Usage: tell <player> <message>"}
  end

  # -- Tier 3: follow / lead --

  mocked_test "follow/1 with target test" do
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    actual = Parser.parse(client, "follow bob")
    assert actual === {:follow, "bob"}
  end

  mocked_test "follow/0 no args stop following test" do
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    actual = Parser.parse(client, "follow")
    assert actual === :stop_following
  end

  mocked_test "lead/0 test" do
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{username: "tim_allen", room: @test_room}
    }

    actual = Parser.parse(client, "lead")
    assert actual === :lead
  end

  mocked_test "__follow_move parsing test" do
    client = %Zung.Client{
      Zung.Client.new(nil)
      | game_state: %Zung.Client.GameState{
          username: "tim_allen",
          room: @test_room,
          command_aliases: %{}
        }
    }

    actual = Parser.parse(client, "__follow_move bob test_room2")
    assert actual === {:follow_move, "bob", "test_room2"}
  end
end
