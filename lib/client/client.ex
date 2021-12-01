defmodule Zung.Client do
  @enforce_keys [:session_id, :connection]
  defstruct [
    :session_id,
    :connection,
    :game_state
  ]

  alias Zung.Client.Connection
  alias Zung.Client.Session
  alias Zung.Client.User

  defmodule GameState do
    defstruct [
      :username,
      room: %Zung.Game.Room{},
      command_aliases: %{
        "l" => "look",
        "n" => "north",
        "s" => "south",
        "e" => "east",
        "w" => "west",
        "u" => "up",
        "d" => "down",
        "ooc" => "csay ooc"
      },
      subscribed_channels: [],
    ]
  end


  def new(socket) do
    {:ok, connection_id} = Connection.start_link(socket)
    :ok = :gen_tcp.controlling_process(socket, connection_id)

    session_id = Session.new_session(socket)
    %Zung.Client{
      session_id: session_id,
      connection: %Connection{id: connection_id},
    }
  end

  def pop_input(%Zung.Client{} = client) do
    msg = Connection.read(client.connection)
    case msg do
      {:none} -> {client, nil}
      {:ok, data} ->
        Session.refresh_session(client.session_id)
        {client, data}
      _ -> raise Zung.Error.Connection.Lost
    end
  end

  def push_output(%Zung.Client{} = client, output) do
    Connection.write(client.connection, output)
    client
  end
  def flush_output(%Zung.Client{} = client, prompt? \\ true) do
    Connection.flush_output(client.connection, prompt?)
    client
  end

  def authenticate_as(%Zung.Client{} = client, username) do
    use_ansi? = User.get_setting(username, :use_ansi?)

    User.log_login(username)
    Session.authenticate_session(client.session_id, username)
    Connection.use_ansi(client.connection, use_ansi?)

    client
  end

  def subscribe(%Zung.Client{} = client, channels=[]), do: Enum.reduce(channels, client, fn channel, new_client -> subscribe(new_client, channel) end)
  def subscribe(%Zung.Client{} = client, channel) do
    if(client.game_state !== nil and channel not in client.game_state.subscribed_channels) do
      Connection.subscribe(client.connection, String.to_atom(channel))
      Map.put(client, :game_state, Map.put(client.game_state, :subscribed_channels, [channel | client.game_state.subscribed_channels]))
    else
      client
    end
  end

  def publish(%Zung.Client{} = client, channel, message) do
    Connection.publish(client.connection, channel, {client.game_state.username, message})
    client
  end

  def force_ansi(%Zung.Client{} = client, use_ansi?) do
    Connection.use_ansi(client.connection, use_ansi?)
  end

  def shutdown(%Zung.Client{} = client) do
    Session.end_session(client.session_id)
    Connection.end_connection(client.connection)
  end

  # TODO deprecate "raw" function
  def raw_read(%Zung.Client{} = client) do
    input = pop_input(client)
    case input do
      {new_client, nil} -> raw_read(new_client)
      {_, data} -> data
    end
  end
  def raw_clear_screen(%Zung.Client{} = client), do: raw_write(client, Enum.reduce(1..40, "", fn _e, acc -> "||NL||" <> acc end))
  def raw_write_line(%Zung.Client{} = client, data), do: raw_write(client, "#{data}||NL||")
  def raw_write(%Zung.Client{} = client, data) do
    client
      |> push_output(data)
      |> flush_output(false)
  end
end
