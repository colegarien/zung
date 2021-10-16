defmodule Zung.Game.RoomTest do
  use ExUnit.Case, async: true

  alias Zung.Game.Room, as: Room

  # Features needing testing
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
  #  - add "exit flags" -> http://www.forgottenkingdoms.org/builders/rlesson3.php
  #  - add behaviors/programs to rooms/doors/objects/etc -> http://www.forgottenkingdoms.org/builders/rlesson5.php
  #                                                      -> http://www.forgottenkingdoms.org/builders/mobprogs.php
  test "move in a direction without an exit" do
    # Arrange
    room = %Room{
      exits: [%{ direction: :north, to: "some/room" }]
    }

    # Act
    actual = Room.move(room, :south)

    # Assert
    assert {:error, "There is no where to go in that direction."} = actual
  end

  test "move in toward an open exit" do
    # Arrange
    room = %Room{
      exits: [%{ direction: :north, to: "some/room" }]
    }

    # Act
    actual = Room.move(room, :north)

    # Assert
    assert {:ok, "some/room"} = actual
  end


  test "look at nothing" do
    # Arrange
    room = %Room{}

    # Act
    actual = Room.look(room, "nothing in the room matches this")

    # Assert
    assert "You see nothing of interest." == actual
  end

  test "look at a non exit horizontal direction" do
    # Arrange
    room = %Room{}

    # Act
    actual_north = Room.look(room, :north)
    actual_east = Room.look(room, :east)
    actual_south = Room.look(room, :south)
    actual_west = Room.look(room, :west)

    # Assert
    assert "There is nothing of interest to see to the north." == actual_north
    assert "There is nothing of interest to see to the east." == actual_east
    assert "There is nothing of interest to see to the south." == actual_south
    assert "There is nothing of interest to see to the west." == actual_west
  end

  test "look at a non exit vertical direction" do
    # Arrange
    room = %Room{}

    # Act
    actual_above = Room.look(room, :up)
    actual_below = Room.look(room, :down)

    # Assert
    assert "There is nothing of interest to see above." == actual_above
    assert "There is nothing of interest to see below." == actual_below
  end

  test "look at a non-descript exit of the room" do
    # Arrange
    room = %Room{
      exits: [
        %{ direction: :north, to: "some/room" },
        %{ direction: :up, to: "some/room" },
      ]
    }

    # Act
    actual_north = Room.look(room, :north)
    actual_above = Room.look(room, :up)

    # Assert
    assert "Nothing to see, just an exit to the north." == actual_north
    assert "Nothing to see, just an exit above." == actual_above
  end

  test "look at a named exit of the room" do
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
    actual_north = Room.look(room, :north)
    actual_above = Room.look(room, :up)

    # Assert
    assert "Nothing to see, just an iron door to the north." == actual_north
    assert "Nothing to see, just a steel hatch above." == actual_above
  end

  test "look at a customly describe exit of the room" do
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
    actual_north = Room.look(room, :north)
    actual_above = Room.look(room, :up)

    # Assert
    assert "You see a bright meadow just over the horizon to the north." == actual_north
    assert "Complete garbage truck nonsense" == actual_above
  end

  test "look at flavor text" do
    # Arrange
    room = %Room{
      flavor_texts: [
        %{
          keywords: ["splish splash", "splish", "splash"],
          text: "This splishy sploshly splish splosh appears to splish and splosh."
        }
      ]
    }

    # Arrange
    actual_first = Room.look(room, "splish splash")
    actual_second = Room.look(room, "splish")
    actual_third = Room.look(room, "splash")

    # Assert
    assert "This splishy sploshly splish splosh appears to splish and splosh." == actual_first
    assert "This splishy sploshly splish splosh appears to splish and splosh." == actual_second
    assert "This splishy sploshly splish splosh appears to splish and splosh." == actual_third
  end
end
