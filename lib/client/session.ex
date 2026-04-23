defmodule Zung.Client.Session do
  defmodule State do
    defstruct [
      :id,
      :connection,
      :username,
      :created,
      :last_activity,
      # 30 minutes by default
      timeout: 30 * 60 * 1000,
      is_authenticated: false,
      is_disconnected: true
    ]

    @type t :: %__MODULE__{
            id: pos_integer() | nil,
            connection: Zung.Client.Connection.t() | nil,
            username: String.t() | nil,
            created: non_neg_integer(),
            last_activity: non_neg_integer(),
            timeout: non_neg_integer(),
            is_authenticated: boolean(),
            is_disconnected: boolean()
          }

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
      if force and session.connection != nil do
        Zung.Client.Connection.force_closed(
          session.connection,
          "||NL||[ Disconnected due to Session Timeout ]||NL||"
        )
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

  @spec start_link(map()) :: GenServer.on_start()
  def start_link(initial_state \\ %{}) do
    GenServer.start_link(__MODULE__, initial_state, name: __MODULE__)
  end

  # HEART BEATS
  def schedule_cleanup(frequency),
    do: Process.send_after(self(), {:cleanup, frequency}, frequency)

  def schedule_timeout(frequency),
    do: Process.send_after(self(), {:expire_sessions, frequency}, frequency)

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
  @spec new_session(Zung.Client.Connection.t()) :: pos_integer()
  def new_session(connection) do
    GenServer.call(
      __MODULE__,
      {:new, %State{State.new() | connection: connection, is_disconnected: false}}
    )
  end

  @spec is_expired?(pos_integer()) :: boolean()
  def is_expired?(session_id) do
    GenServer.call(__MODULE__, {:is_expired, session_id})
  end

  @spec get_session_count() :: non_neg_integer()
  def get_session_count() do
    GenServer.call(__MODULE__, :active_session_count)
  end

  @spec get_active_usernames() :: [String.t()]
  def get_active_usernames() do
    GenServer.call(__MODULE__, :active_usernames)
  end

  @spec refresh_session(pos_integer()) :: :ok
  def refresh_session(session_id) do
    GenServer.cast(__MODULE__, {:refresh, session_id})
  end

  @spec authenticate_session(pos_integer(), String.t()) :: :ok
  def authenticate_session(session_id, username) do
    GenServer.cast(__MODULE__, {:authenticate, session_id, username})
  end

  @spec end_session(pos_integer()) :: :ok
  def end_session(session_id) do
    GenServer.cast(__MODULE__, {:end, session_id})
  end

  @spec end_all() :: :ok
  def end_all() do
    GenServer.cast(__MODULE__, :end_all)
  end

  # SERVER SIDE
  def handle_call({:new, %State{} = session}, _from, state) do
    session_with_id = %State{session | id: get_next_available_id(state)}
    {:reply, session_with_id.id, Map.put(state, session_with_id.id, session_with_id)}
  end

  def handle_call({:is_expired, session_id}, _from, state) do
    {:reply, !Map.has_key?(state, session_id) or State.is_expired?(state[session_id]), state}
  end

  def handle_call(:active_session_count, _from, state) do
    {:reply,
     Enum.reduce(state, 0, fn {_k, session}, acc ->
       if State.is_active?(session) and session.is_authenticated, do: acc + 1, else: acc
     end), state}
  end

  def handle_call(:active_usernames, _from, state) do
    usernames =
      state
      |> Enum.filter(fn {_k, session} ->
        State.is_active?(session) and session.is_authenticated
      end)
      |> Enum.map(fn {_k, session} -> session.username end)
      |> Enum.sort()

    {:reply, usernames, state}
  end

  def handle_cast({:refresh, session_id}, state) do
    {:noreply, Map.update(state, session_id, %State{}, &State.refresh(&1))}
  end

  def handle_cast({:authenticate, session_id, username}, state) do
    {:noreply, Map.update(state, session_id, %State{}, &State.authenticate(&1, username))}
  end

  def handle_cast({:end, session_id}, state) do
    {:noreply, Map.update(state, session_id, %State{}, &State.close(&1))}
  end

  def handle_cast(:end_all, state) do
    {:noreply, for({id, session} <- state, into: %{}, do: {id, State.close(session, true)})}
  end

  # UTILITY
  defp get_next_available_id(state) do
    max_id =
      state
      |> Map.keys()
      |> Enum.max(fn -> 0 end)

    max_id + 1
  end
end
