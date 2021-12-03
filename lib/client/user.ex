defmodule Zung.Client.User do
  defmodule State do
    defstruct [
      :username, :password,
      :created, :last_login,
      settings: %{
        use_ansi?: false,
      },
    ]

    defp get_now(), do: :os.system_time(:millisecond)

    def new() do
      %State{
        created: get_now(),
        last_login: get_now()
      }
    end

    def get_setting(user = %State{}, setting) do
      Map.get(user.settings, setting)
    end

    def set_setting(user = %State{}, setting, value) do
      if not Map.has_key?(user.settings, setting) do
        user
      else
        %State{user | settings: Map.put(user.settings, setting, value)}
      end
    end

    def log_login(user = %State{}) do
      %State{user | last_login: get_now()}
    end
  end

  use GenServer
  def start_link(intial_state \\ %{}) do
    GenServer.start_link(__MODULE__, intial_state, name: __MODULE__)
  end
  def init(state), do: {:ok, state}

  # CLIENT SIDE
  def hash_password(username, password) do
    salt = Application.get_env(:zung, :secret_salt)
    :crypto.hash(:sha256, password <> username <> salt)
      |> Base.encode16()
      |> String.downcase()
  end

  def validate_username_format(username, is_adding? \\ true) do
    cond do
      username == "new" -> if is_adding?, do: {:error, "Username cannot be 'new'."}, else: {:ok, "new" }
      not String.match?(username, ~r/^[a-z][a-z0-9\_]{2,11}$/) -> {:error, "Username is invalid."}
      is_adding? and not Zung.Client.User.username_available?(username) -> {:error, "Username already taken."}
      not is_adding? and Zung.Client.User.username_available?(username) -> {:error, "User does not exist. Please try again."}
      true -> {:ok, username}
    end
  end

  def validate_password_format(password) do
    cond do
      not String.match?(password, ~r/^[a-zA-Z0-9\!\@\#\$\%\^\&\*\(\)\_]{8,32}$/) -> {:error, "Password is invalid."}
      true -> {:ok, password}
    end
  end

  def create_user(username, password, settings) do
    GenServer.call(__MODULE__, {:new, %State{State.new | username: username, password: password, settings: settings }})
  end

  def username_available?(username) do
    GenServer.call(__MODULE__, {:username_available?, username})
  end

  def password_matches?(username, password) do
    GenServer.call(__MODULE__, {:password_matches?, username, password})
  end

  def get_setting(username, setting) do
    GenServer.call(__MODULE__, {:get_setting, username, setting})
  end

  def set_setting(username, setting, value) do
    GenServer.cast(__MODULE__, {:set_setting, username, setting, value})
  end

  def log_login(username) do
    GenServer.cast(__MODULE__, {:log_login, username})
  end

  # SERVER SIDE
  def handle_call({:new, user}, _from, state) do
    {:reply, user, Map.put(state, user.username, user)}
  end

  def handle_call({:username_available?, username}, _from, state) do
    {:reply, not Map.has_key?(state, username), state}
  end

  def handle_call({:password_matches?, username, password}, _from, state) do
    {:reply, Map.has_key?(state, username) and state[username].password === password, state}
  end

  def handle_call({:get_setting, username, setting}, _from, state) do
    {:reply, State.get_setting(state[username], setting), state}
  end

  def handle_cast({:set_setting, username, setting, value}, state) do
    {:noreply, Map.update(state, username, %State{}, &(State.set_setting(&1, setting, value)))}
  end

  def handle_cast({:log_login, username}, state) do
    {:noreply, Map.update(state, username, %State{}, &(State.log_login(&1)))}
  end
end
