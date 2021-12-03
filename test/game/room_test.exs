defmodule Zung.Game.RoomTest do
  use ExUnit.Case, async: true
  use MecksUnit.Case

  alias Zung.Game.Room, as: Room

  defmock Zung.DataStore, preserve: true do
    def get_room(room_id) do
      case room_id do
        "test_room" -> %Zung.Game.Room{
          id: "test_room",
          title: "The Test Room",
          description: "A simple test room for testing units",
          flavor_texts: [],
          exits: [ %{ direction: :north, to: "test_room2" } ],
        }
      end
    end
  end

  # TODO Features needing testing
  # ~~ - moving toward exits
  # ~~ - look at exits
  # ~~   + optional direction descriptions
  # ~~   + if no description either say "nothing of interest to see to the [direction]"
  # ~~       or "nothing to see, just an [exit] to the [direction]"
  # ~~   + also optional description of the exit itself, i.e. instead of "an [exit]" it could be "an [iron door]"
  # ~~ - add "extra" decriptions (essential a keyword list with a description tied that players can "look" at)
  #  - lock/unlockable exits,
  #  - add sizing to exits (i.e. anything can fit, giants can fit, only normal size exit, tiny exit etc)
  #  - add "room flags" -> http://www.forgottenkingdoms.org/builders/rlesson2.php
  #  - add "exit flags" -> http://www.forgottenkingdoms.org/builders/rlesson3.php (and other stuff -> https://www.aardwolf.com/building/editing-exits.html )
  #  - add behaviors/programs to rooms/doors/objects/etc -> http://www.forgottenkingdoms.org/builders/rlesson5.php
  #                                                      -> http://www.forgottenkingdoms.org/builders/mobprogs.php
  mocked_test "move in a direction without an exit" do
    # Arrange
    room = %Room{
      exits: [%{ direction: :north, to: "test_room" }]
    }

    # Act
    actual = Room.move(room, {:direction, :south})

    # Assert
    assert {:error, "There is no where to go in that direction."} = actual
  end

  mocked_test "move in toward an open exit" do
    # Arrange
    room = %Room{
      exits: [%{ direction: :north, to: "test_room" }]
    }

    # Act
    actual = Room.move(room, {:direction, :north})

    # Assert
    assert {:ok, _} = actual
  end

  mocked_test "move into a named exit that doesnt exist" do
    # Arrange
    room = %Room{
      exits: [%{ name: "iron door", to: "test_room" }]
    }

    # Act
    actual = Room.move(room, {:exit, "fake door"})

    # Assert
    assert {:error, "There is no exit there."} = actual
  end

  mocked_test "move into an open named exit" do
    # Arrange
    room = %Room{
      exits: [%{ name: "iron door", to: "test_room" }]
    }

    # Act
    actual = Room.move(room, {:exit, "iron door"})

    # Assert
    assert {:ok, _} = actual
  end


  mocked_test "look at nothing" do
    # Arrange
    room = %Room{}

    # Act
    actual = Room.look_at(room, "nothing in the room matches this")

    # Assert
    assert "You see nothing of interest." == actual
  end

  mocked_test "look at a non exit horizontal direction" do
    # Arrange
    room = %Room{}

    # Act
    actual_north = Room.look_at(room, {:direction, :north})
    actual_east = Room.look_at(room, {:direction, :east})
    actual_south = Room.look_at(room, {:direction, :south})
    actual_west = Room.look_at(room, {:direction, :west})

    # Assert
    assert "There is nothing of interest to see to the north." == actual_north
    assert "There is nothing of interest to see to the east." == actual_east
    assert "There is nothing of interest to see to the south." == actual_south
    assert "There is nothing of interest to see to the west." == actual_west
  end

  mocked_test "look at a non exit vertical direction" do
    # Arrange
    room = %Room{}

    # Act
    actual_above = Room.look_at(room, {:direction, :up})
    actual_below = Room.look_at(room, {:direction, :down})

    # Assert
    assert "There is nothing of interest to see above." == actual_above
    assert "There is nothing of interest to see below." == actual_below
  end

  mocked_test "look at a non-descript exit of the room" do
    # Arrange
    room = %Room{
      exits: [
        %{ direction: :north, to: "some/room" },
        %{ direction: :up, to: "some/room" },
      ]
    }

    # Act
    actual_north = Room.look_at(room, {:direction, :north})
    actual_above = Room.look_at(room, {:direction, :up})

    # Assert
    assert "Nothing to see, just an exit to the north." == actual_north
    assert "Nothing to see, just an exit above." == actual_above
  end

  mocked_test "look at a named exit of the room" do
    # Arrange
    room = %Room{
      exits: [
        %{
          direction: :north,
          name: "iron door",
          to: "some/room"
        },
        %{
          direction: :up,
          name: "steel hatch",
          to: "some/room"
        },
      ]
    }

    # Act
    actual_north = Room.look_at(room, {:direction, :north})
    actual_above = Room.look_at(room, {:direction, :up})

    # Assert
    assert "Nothing to see, just an iron door to the north." == actual_north
    assert "Nothing to see, just a steel hatch above." == actual_above
  end

  mocked_test "look at a customly describe exit of the room" do
    # Arrange
    room = %Room{
      exits: [
        %{
          direction: :north,
          description: "You see a bright meadow just over the horizon to the north.",
          to: "some/room"
        },
        %{
          direction: :up,
          name: "steel hatch",
          description: "Complete garbage truck nonsense",
          to: "some/room"
        },
      ]
    }

    # Act
    actual_north = Room.look_at(room, {:direction, :north})
    actual_above = Room.look_at(room, {:direction, :up})

    # Assert
    assert "You see a bright meadow just over the horizon to the north." == actual_north
    assert "Complete garbage truck nonsense" == actual_above
  end

  mocked_test "look at flavor text" do
    # Arrange
    room = %Room{
      flavor_texts: [
        %{
          id: "splosh_text",
          keywords: ["splish splash", "splish", "splash"],
          text: "This splishy sploshly splish splosh appears to splish and splosh."
        }
      ]
    }

    # Arrange
    actual = Room.look_at(room, {:flavor, "splosh_text"})

    # Assert
    assert "This splishy sploshly splish splosh appears to splish and splosh." == actual
  end

  mocked_test "look at named exit that doesnt exist" do
    # Arrange
    room = %Room{
      exits: []
    }

    # Arrange
    actual = Room.look_at(room, {:exit, "iron door"})

    # Assert
    assert "There is nothing of interest to see." == actual
  end

  mocked_test "look at named exit" do
    # Arrange
    room = %Room{
      exits: [
        %{name: "iron door"}
      ]
    }

    # Arrange
    actual = Room.look_at(room, {:exit, "iron door"})

    # Assert
    assert "Nothing to see, just an iron door." == actual
  end

  mocked_test "look at a directional named exit" do
    # Arrange
    room = %Room{
      exits: [
        %{name: "iron door", direction: :north}
      ]
    }

    # Arrange
    actual = Room.look_at(room, {:exit, "iron door"})

    # Assert
    assert "Nothing to see, just an iron door to the north." == actual
  end

  mocked_test "look at a customly described named exits of the room" do
    # Arrange
    room = %Room{
      exits: [
        %{
          direction: :north,
          name: "meadow",
          description: "You see a bright meadow just over the horizon to the north.",
          to: "some/room"
        },
        %{
          name: "steel hatch",
          description: "Complete garbage truck nonsense",
          to: "some/room"
        },
      ]
    }

    # Act
    actual_meadow = Room.look_at(room, {:exit, "meadow"})
    actual_hatch = Room.look_at(room, {:exit, "steel hatch"})

    # Assert
    assert "You see a bright meadow just over the horizon to the north." == actual_meadow
    assert "Complete garbage truck nonsense" == actual_hatch
  end
end
