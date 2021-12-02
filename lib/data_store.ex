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

  # SERVER SIDE

  def handle_call({:get_current_room_id, username}, _from, state) do
    room_id = Map.get(state, :locations, %{})
      |> Map.get(username, "the_void")
    {:reply, room_id, state}
  end

  def handle_call({:get_room, room_id}, _from, state) do
    room = Map.get(state, :rooms, %{})
      |> Map.get(room_id, %Zung.Game.Room{})
    {:reply, room, state}
  end

  def handle_cast({:update_current_room_id, {username, new_room_id}}, state) do
    {:noreply, Map.update(state, :locations, %{username => new_room_id}, &Map.put(&1, username, new_room_id))}
  end
end
