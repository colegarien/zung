defmodule Zung.DataStore do
  use GenServer

  #TODO should split data-store into different pieces of mutable data (i.e. userstore vs character vs location etc stores?)

  # CLIENT-SIDE
  def start_link(intial_state \\ %{}) do
    GenServer.start_link(__MODULE__, intial_state, name: DataStore)
  end

  # TODO prolly wanna simplify this to just a simple CRUD operations with less logic!
  def account_exists?(account_name) do
    GenServer.call(DataStore, {:account_exists, account_name})
  end

  def password_matches?(account_name, password) do
    GenServer.call(DataStore, {:password_matches, account_name, password})
  end

  def add_user(new_user) do
    GenServer.cast(DataStore, {:add_user, new_user})
  end

  def get_location(account_name) do
    GenServer.call(DataStore, {:get_location, account_name})
  end
  def update_location(account_name, new_location) do
    GenServer.cast(DataStore, {:update_location, {account_name, new_location}})
  end

  # SERVER-SIDE
  def init(state \\ %{}) do
    {:ok, state}
  end

  def handle_call({:account_exists, account_name}, _from, state) do
    exists? = Map.has_key?(state, :users) and Enum.any?(state[:users], &(&1[:account_name] == account_name))
    {:reply, exists?, state}
  end

  def handle_call({:password_matches, account_name, password}, _from, state) do
    matches? = Map.has_key?(state, :users) and Enum.any?(state[:users], &(&1[:account_name] == account_name && &1[:password] == password))
    {:reply, matches?, state}
  end

  def handle_call({:get_location, account_name}, _from, state) do
    location = Map.get(state, :locations, %{})
      |> Map.get(account_name, :void) # TODO make default error "void" room
    {:reply, location, state}
  end

  def handle_call(_request, _from, state), do: {:reply, state, state}


  def handle_cast({:add_user, new_user}, state) do
    {:noreply, Map.update(state, :users, [new_user], &([new_user | &1]))}
  end
  def handle_cast({:update_location, {account_name, new_location}}, state) do
    {:noreply, Map.update(state, :locations, %{account_name => new_location}, &Map.put(&1, account_name, new_location))}
  end
  def handle_cast(_request, state), do: {:noreply, state}
end
