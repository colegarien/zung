defmodule Zung.Session do
  defmodule State do
    defstruct [
      :id, :socket, :username,
      :created, :last_activity,
      timeout: 30 * 60 * 1000, # 30 minutes by default
      is_authenticated: false,
      is_disconnected: true,
    ]

    defp get_now(), do: :os.system_time(:millisecond)

    def new() do
      %State{
        created: get_now(),
        last_activity: get_now()
      }
    end

    def is_active?(session = %State{}) do
      session.id != nil and not session.is_disconnected
    end

    def is_expired?(session = %State{}) do
      session.last_activity + session.timeout < get_now()
    end

    def close(session = %State{}, force \\ false) do
      if force and session.socket != nil do
        :gen_tcp.send(session.socket, "\r\n[ Disconnected due to Session Timeout ]\r\n")
        :gen_tcp.close(session.socket)
      end
      %State{session | is_authenticated: false, is_disconnected: true}
    end

    def refresh(session = %State{}) do
      %State{session | last_activity: get_now()}
    end

    def authenticate(session = %State{}, username) do
      %State{session | username: username, is_authenticated: true}
    end
  end

  use GenServer

  def init(initial_state \\ %{}, cleanup_frequency \\ 30, expiration_frequency \\ 10) do
    schedule_cleanup(trunc(cleanup_frequency * 60 * 1000))
    schedule_timeout(trunc(expiration_frequency * 60 * 1000))
    {:ok, initial_state}
  end
  def start_link(intial_state \\ %{}) do
    GenServer.start_link(__MODULE__, intial_state, name: __MODULE__)
  end

  # HEART BEATS
  def schedule_cleanup(frequency), do: Process.send_after(self(), {:cleanup, frequency}, frequency)
  def schedule_timeout(frequency), do: Process.send_after(self(), {:expire_sessions, frequency}, frequency)
  def handle_info({:cleanup, frequency}, state) do
    schedule_timeout(frequency)
    {:noreply, remove_inactive_sessions(state)}
  end
  def handle_info({:expire_sessions, frequency}, state) do
    schedule_timeout(frequency)
    {:noreply, close_expired_sessions(state)}
  end

  def remove_inactive_sessions(state) do
    :maps.filter(fn _, session -> State.is_active?(session) end, state)
  end

  def close_expired_sessions(state) do
    for {id, session} <- state, into: %{} do
      if State.is_expired?(session) do
        {id, State.close(session, true)}
      else
        {id, session}
      end
    end
  end

  # CLIENT SIDE
  def new_session(socket) do
    GenServer.call(__MODULE__, {:new, %State{State.new | socket: socket, is_disconnected: false }})
  end

  def is_expired?(session_id) do
    GenServer.call(__MODULE__, {:is_expired, session_id})
  end

  def get_session_count() do
    GenServer.call(__MODULE__, :active_session_count)
  end

  def refresh_session(session_id) do
    GenServer.cast(__MODULE__, { :refresh, session_id })
  end

  def authenticate_session(session_id, username) do
    GenServer.cast(__MODULE__, {:authenticate, session_id, username })
  end

  def end_session(session_id) do
    GenServer.cast(__MODULE__, {:end, session_id })
  end

  def end_all() do
    GenServer.cast(__MODULE__, :end_all)
  end

  # SERVER SIDE
  def handle_call({:new, session}, _from, state) do
    session_with_id = %State{session | id: get_next_available_id(state)}
    {:reply, session_with_id.id, Map.put(state, session_with_id.id, session_with_id)}
  end

  def handle_call({:is_expired, session_id}, _from, state) do
    {:reply, !Map.has_key?(state, session_id) or State.is_expired?(state[session_id]), state}
  end

  def handle_call(:active_session_count, _from, state) do
    {:reply, Enum.reduce(state, 0, fn {_k, session}, acc -> if State.is_active?(session) and session.is_authenticated, do: acc+1, else: acc end), state}
  end

  def handle_cast({:refresh, session_id}, state) do
    {:noreply, Map.update(state, session_id, %State{}, &(State.refresh(&1)))}
  end

  def handle_cast({:authenticate, session_id, username }, state) do
    {:noreply, Map.update(state, session_id, %State{}, &(State.authenticate(&1, username)))}
  end

  def handle_cast({:end, session_id }, state) do
    {:noreply, Map.update(state, session_id, %State{}, &(State.close(&1)))}
  end

  def handle_cast(:endall, state) do
    {:noreply, Enum.map(state, fn ({id, session}) -> {id, State.close(session, true)} end)}
  end


  # UTILITY
  defp get_next_available_id(state) do
    max_id = state
      |> Map.keys
      |> Enum.max(fn -> 0 end)
    max_id + 1
  end
end
