defmodule Zung.Game.Room do
  defstruct id: "the_void",
            title: "Void",
            description: "The blank, never-ending void.",
            flavor_texts: [],
            exits: [],
            objects: []

  def get_room(room_id), do: Zung.DataStore.get_room(room_id)

  def describe(%Zung.Game.Room{} = room) do
    title_string = "||BOLD||||GRN||#{room.title}||RESET||"
    description_string = "#{room.description}"
    exits_string = Zung.Game.Room.Exit.describe(room.exits)
    objects_string = Zung.Game.Object.describe(room.objects)

    """
    #{title_string}
       #{description_string}
    #{exits_string}
    #{objects_string}
    """
  end

  def look_at(room, {:flavor, flavor_text_id}) do
    Enum.find(
      room.flavor_texts,
      %{text: "You see nothing of interest."},
      &(flavor_text_id === &1.id)
    ).text
  end

  def look_at(room, {:direction, direction}),
    do: Zung.Game.Room.Exit.describe_target(room.exits, direction)

  def look_at(room, {:exit, name}), do: Zung.Game.Room.Exit.describe_target(room.exits, name)

  def look_at(room, {:object, object_id}),
    do: Zung.Game.Object.describe_target(room.objects, object_id)

  def look_at(_room, _target), do: "You see nothing of interest."

  def move(room, {:direction, direction}),
    do: do_move(room, direction, "There is no where to go in that direction.")

  def move(room, {:exit, name}), do: do_move(room, name, "There is no exit there.")
  def move(_room, _target), do: {:error, "There is no where to go."}

  defp do_move(room, target, fail_message) do
    exits = Zung.Game.Room.Exit.match(room.exits, target)

    if Enum.count(exits) > 0 do
      {:ok, hd(exits).to |> get_room()}
    else
      {:error, fail_message}
    end
  end
end

defmodule Zung.Game.Room.Exit do
  @enforce_keys [:to]
  defstruct [:to, :direction, :name, :description]

  def describe(exits) when is_list(exits) do
    "||BOLD||||CYA||-{ Exits:" <>
      Enum.reduce(exits, "", fn room_exit, acc ->
        if room_exit.direction !== nil do
          "#{acc} #{room_exit.direction}"
        else
          acc
        end
      end) <>
      if(Enum.any?(exits, &(&1.direction === nil)), do: " other", else: "") <>
      " }-||RESET||"
  end

  def describe(%Zung.Game.Room.Exit{name: name, direction: direction, description: description}) do
    cond do
      description !== nil ->
        description

      name !== nil and direction !== nil ->
        an_or_a = if name =~ ~r"^[aeiouAEIOU]", do: "an", else: "a"
        "Nothing to see, just #{an_or_a} #{name} #{direction_to_text(direction)}."

      name !== nil ->
        an_or_a = if name =~ ~r"^[aeiouAEIOU]", do: "an", else: "a"
        "Nothing to see, just #{an_or_a} #{name}."

      direction !== nil ->
        "Nothing to see, just an exit #{direction_to_text(direction)}."

      true ->
        "Nothing to see, just an exit."
    end
  end

  def match(exits, target) do
    Enum.filter(exits, &(&1.direction === target or &1.name === target))
  end

  def describe_target(exits, target) do
    matching_exits = match(exits, target)

    if Enum.count(matching_exits) > 0 do
      matching_exits
      |> hd
      |> describe
    else
      cond do
        target in [:north, :south, :east, :west, :up, :down] ->
          "There is nothing of interest to see #{direction_to_text(target)}."

        true ->
          "There is nothing of interest to see."
      end
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
