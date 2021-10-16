defmodule Zung.Game.Room do
  defstruct [
    id: "the_void",
    title: "Void",
    description: "The blank, never-ending void.",
    flavor_texts: [],
    exits: [],
    # TODO custom_exits (non-standard direction exits, the syntax would be like "enter secret hatch" or whatever)
    # TODO cool stuff on exits -> https://www.aardwolf.com/building/editing-exits.html
  ]

  # TODO write a whole bunch of tests for ROOM and expand functionality like hidden exits and such!?
  # TODO how for to do objects (might need to implement some kinda selector syntax?)

  def describe(%Zung.Game.Room{} = room) do
    title_string = "||BOLD||||GRN||#{room.title}||RESET||"
    description_string = "#{room.description}"
    exits_string = "||BOLD||||CYA||-{ Exits:"
      <> Enum.reduce(room.exits, "", fn room_exit, acc -> "#{acc} #{room_exit.direction}" end)
      <> " }-||RESET||"

    """
#{title_string}
   #{description_string}
#{exits_string}

"""
  end

  def move(room, direction) do
    exits_in_direction = Enum.filter(room.exits, &(&1.direction == direction))
    if Enum.count(exits_in_direction) > 0 do
      {:ok, hd(exits_in_direction).to}
    else
      {:error, "There is no where to go in that direction."}
    end
  end

  def look(room, target) do
    cond do
      is_atom(target) -> look_direction(room, target)
      is_flavor_text(room, target) -> look_flavor_text(room, target)
      true -> "You see nothing of interest."
    end
  end

  # Stuff for looking directions (make an Exit module?)
  defp look_direction(room, direction) do
    exits_in_direction = Enum.filter(room.exits, &(&1.direction == direction))
    if Enum.count(exits_in_direction) > 0 do
      exits_in_direction
        |> hd
        |> describe_exit
    else
      "There is nothing of interest to see #{direction_to_text(direction)}."
    end
  end

  defp describe_exit(room_exit) do
    case room_exit do
      %{description: description} -> description
      %{name: name} ->
        an_or_a = if name =~ ~r"^[aeiouAEIOU]", do: "an", else: "a"
        "Nothing to see, just #{an_or_a} #{name} #{direction_to_text(room_exit.direction)}."
      _ -> "Nothing to see, just an exit #{direction_to_text(room_exit.direction)}."
    end
  end

  defp direction_to_text(direction) do
    case direction do
      :up -> "above"
      :down -> "below"
      _ -> "to the #{to_string(direction)}"
    end
  end

  # Stuff for looking at flavor text
  defp is_flavor_text(room, target) do
    room.flavor_texts
      |> Enum.any?(&(target in &1.keywords))
  end

  defp look_flavor_text(room, target) do
    flavor_text = Enum.find(room.flavor_texts, %{text: ""}, &(target in &1.keywords))
    flavor_text.text
  end
end
