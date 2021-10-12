defmodule Zung.Game.Room do
  defstruct [
    id: "the_void",
    title: "Void",
    description: "The blank, never-ending void.",
    exits: %{},
  ]

  # TODO write a whole bunch of tests for ROOM and expand functionality like hidden exits and such!?
  # TODO how for todo objects (might need to implement some kinda selector syntax?)

  def describe(%Zung.Game.Room{} = room) do
    title_string = "||BOLD||||GRN||#{room.title}||RESET||"
    description_string = "||YEL||#{room.description}||RESET||"
    exits_string = "exits: " <> Enum.reduce(Map.keys(room.exits), "", fn direction, acc ->
      separator = (if acc != "", do: ", ", else: "")
      "#{acc}#{separator}||BOLD||||CYA||#{direction}||RESET||"
    end)

    "||NL||#{title_string}||NL||||NL||#{description_string}||NL||||NL||#{exits_string}||NL||||NL||"
  end

  def move(room, direction) do
    if Map.has_key?(room.exits, direction) do
      {:ok, room.exits[direction]}
    else
      {:error, "||RED||There is no where to go in the direction.||RESET||"}
    end
  end
end
