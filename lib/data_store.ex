defmodule Zung.DataStore do
  use GenServer

  def start_link(intial_state \\ %{}) do
    GenServer.start_link(__MODULE__, intial_state, name: DataStore)
  end

  def init(state \\ %{}), do: {:ok, state}

  # CLIENT SIDE

  def get_current_room_id(username) do
    GenServer.call(DataStore, {:get_current_room_id, username})
  end

  def update_current_room_id(username, new_room_id) do
    GenServer.cast(DataStore, {:update_current_room_id, {username, new_room_id}})
  end

  def get_room(room_id) do
    GenServer.call(DataStore, {:get_room, room_id})
  end

  def remove_object_from_room(room_id, object_id) do
    GenServer.call(DataStore, {:remove_object_from_room, room_id, object_id})
  end

  def add_object_to_room(room_id, object) do
    GenServer.cast(DataStore, {:add_object_to_room, room_id, object})
  end

  def update_exit_state(room_id, exit_target, new_state) do
    GenServer.call(DataStore, {:update_exit_state, room_id, exit_target, new_state})
  end

  # SERVER SIDE

  def handle_call({:get_current_room_id, username}, _from, state) do
    room_id =
      Map.get(state, :locations, %{})
      |> Map.get(username, "the_void")

    {:reply, room_id, state}
  end

  def handle_call({:get_room, room_id}, _from, state) do
    room =
      Map.get(state, :rooms, %{})
      |> Map.get(room_id, %Zung.Game.Room{})

    {:reply, room, state}
  end

  def handle_call({:remove_object_from_room, room_id, object_id}, _from, state) do
    room = Map.get(state, :rooms, %{}) |> Map.get(room_id, %Zung.Game.Room{})
    object = Enum.find(room.objects, nil, &(&1.id === object_id))

    cond do
      object == nil ->
        {:reply, {:error, "You don't see that here."}, state}

      not object.takeable? ->
        {:reply, {:error, "You can't take that."}, state}

      true ->
        updated_objects = Enum.reject(room.objects, &(&1.id === object_id))
        updated_room = %{room | objects: updated_objects}
        updated_rooms = Map.put(Map.get(state, :rooms, %{}), room_id, updated_room)
        {:reply, {:ok, object}, Map.put(state, :rooms, updated_rooms)}
    end
  end

  def handle_call({:update_exit_state, room_id, exit_target, new_state}, _from, state) do
    room = Map.get(state, :rooms, %{}) |> Map.get(room_id, %Zung.Game.Room{})

    matching_index =
      Enum.find_index(room.exits, &(&1.direction === exit_target or &1.name === exit_target))

    if matching_index != nil do
      updated_exit = %{Enum.at(room.exits, matching_index) | state: new_state}
      updated_exits = List.replace_at(room.exits, matching_index, updated_exit)
      updated_room = %{room | exits: updated_exits}
      updated_rooms = Map.put(Map.get(state, :rooms, %{}), room_id, updated_room)
      {:reply, {:ok, updated_exit}, Map.put(state, :rooms, updated_rooms)}
    else
      {:reply, {:error, "You don't see that here."}, state}
    end
  end

  def handle_cast({:update_current_room_id, {username, new_room_id}}, state) do
    {:noreply,
     Map.update(
       state,
       :locations,
       %{username => new_room_id},
       &Map.put(&1, username, new_room_id)
     )}
  end

  def handle_cast({:add_object_to_room, room_id, object}, state) do
    room = Map.get(state, :rooms, %{}) |> Map.get(room_id, %Zung.Game.Room{})
    updated_room = %{room | objects: room.objects ++ [object]}
    updated_rooms = Map.put(Map.get(state, :rooms, %{}), room_id, updated_room)
    {:noreply, Map.put(state, :rooms, updated_rooms)}
  end
end
