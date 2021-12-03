defmodule Zung.Game.Room do
  defstruct [
    id: "the_void",
    title: "Void",
    description: "The blank, never-ending void.",
    flavor_texts: [],
    exits: [],
  ]

  def get_room(room_id), do: Zung.DataStore.get_room(room_id)

  def describe(%Zung.Game.Room{} = room) do
    title_string = "||BOLD||||GRN||#{room.title}||RESET||"
    description_string = "#{room.description}"
    exits_string = "||BOLD||||CYA||-{ Exits:"
      <> Enum.reduce(room.exits, "", fn room_exit, acc ->
        if Map.has_key?(room_exit, :direction) do
          "#{acc} #{room_exit.direction}"
        else
          acc
        end
      end)
      # TODO consider doing the following to add "other" for non-directional exits: <> if Enum.any?(room.exits, &(not Map.has_key?(&1, :direction))), do: " other"
      <> " }-||RESET||"

    """
#{title_string}
   #{description_string}
#{exits_string}

"""
  end

  def look_at(room, {:flavor, flavor_text_id}) do
    Enum.find(room.flavor_texts, %{text: "You see nothing of interest."}, &(flavor_text_id === &1.id)).text
  end
  def look_at(room, {:direction, direction}) do
    exits_in_direction = Enum.filter(room.exits, &(Map.has_key?(&1, :direction) and &1.direction == direction))
    if Enum.count(exits_in_direction) > 0 do
      exits_in_direction
        |> hd
        |> describe_exit
    else
      "There is nothing of interest to see #{direction_to_text(direction)}."
    end
  end
  def look_at(room, {:exit, name}) do
    exits_with_name = Enum.filter(room.exits,  &(Map.has_key?(&1, :name) and &1.name == name))
    if Enum.count(exits_with_name) > 0 do
      exits_with_name
        |> hd
        |> describe_exit
    else
      "There is nothing of interest to see."
    end
  end
  def look_at(_room, _target), do: "You see nothing of interest."

  def move(room, {:direction, direction}) do
    exits_in_direction = Enum.filter(room.exits, &(Map.has_key?(&1, :direction) and &1.direction === direction))
    if Enum.count(exits_in_direction) > 0 do
      {:ok, hd(exits_in_direction).to |> get_room() }
    else
      {:error, "There is no where to go in that direction."}
    end
  end
  def move(room, {:exit, name}) do
    exits_with_name = Enum.filter(room.exits, &(Map.has_key?(&1, :name) and &1.name === name))
    if Enum.count(exits_with_name) > 0 do
      {:ok, hd(exits_with_name).to |> get_room() }
    else
      {:error, "There is no exit there."}
    end
  end
  def move(_room, _target), do: {:error, "There is no where to go."}

  defp describe_exit(room_exit) do
    case room_exit do
      %{description: description} -> description
      %{name: name, direction: direction} ->
        an_or_a = if name =~ ~r"^[aeiouAEIOU]", do: "an", else: "a"
        "Nothing to see, just #{an_or_a} #{name} #{direction_to_text(direction)}."
      %{name: name} ->
        an_or_a = if name =~ ~r"^[aeiouAEIOU]", do: "an", else: "a"
        "Nothing to see, just #{an_or_a} #{name}."
      %{direction: direction} -> "Nothing to see, just an exit #{direction_to_text(direction)}."
      _ -> "Nothing to see, just an exit."
    end
  end

  defp direction_to_text(direction) do
    case direction do
      :up -> "above"
      :down -> "below"
      _ -> "to the #{to_string(direction)}"
    end
  end

end
