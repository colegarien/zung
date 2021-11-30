defmodule Zung.Client do
  @enforce_keys [:session_id, :connection_id]
  defstruct [
    :session_id,
    :connection_id,
    :game_state,
    input_buffer: :queue.new,
    output_buffer: :queue.new
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
      connection_id: connection_id,
    }
  end

  def pop_input(%Zung.Client{} = client) do
    msg = Connection.read(client.connection_id)
    case msg do
      {:none} -> {client, nil}
      {:ok, data} ->
        Session.refresh_session(client.session_id)
        {client, data}
    end
  end

  def push_output(%Zung.Client{} = client, output) do
    %Zung.Client{client | output_buffer: :queue.in(output, client.output_buffer)}
  end

  def flush_output(%Zung.Client{} = client) do
    if :queue.is_empty(client.output_buffer) do
      client
    else
      {message, new_queue} = build_output({"", client.output_buffer})
      Zung.Client.raw_write(client, message)
      %Zung.Client{client | output_buffer: new_queue}
    end
  end

  defp build_output({message, queue}) do
    if :queue.is_empty(queue) do
      {message <> "||NL||||RESET||> ", queue}
    else
      {{:value, value}, new_queue} = :queue.out(queue)
      {message <> value <> "||NL||", new_queue} |> build_output
    end
  end

  def authenticate_as(%Zung.Client{} = client, username) do
    use_ansi? = User.get_setting(username, :use_ansi?)

    User.log_login(username)
    Session.authenticate_session(client.session_id, username)
    Connection.use_ansi(client.connection_id, use_ansi?)

    client
  end

  def subscribe(%Zung.Client{} = client, channels=[]), do: Enum.reduce(channels, client, fn channel, new_client -> subscribe(new_client, channel) end)
  def subscribe(%Zung.Client{} = client, channel) do
    if(client.game_state !== nil and channel not in client.game_state.subscribed_channels) do
      Connection.subscribe(client.connection_id, String.to_atom(channel))
      Map.put(client, :game_state, Map.put(client.game_state, :subscribed_channels, [channel | client.game_state.subscribed_channels]))
    else
      client
    end
  end

  def publish(%Zung.Client{} = client, channel, message) do
    Connection.publish(client.connection_id, channel, {client.game_state.username, message})
    client
  end

  def force_ansi(%Zung.Client{} = client, use_ansi?) do
    Connection.use_ansi(client.connection_id, use_ansi?)
  end

  def shutdown(%Zung.Client{} = client) do
    Session.end_session(client.session_id)
    Connection.end_connection(client.connection_id)
  end

  # TODO deprecate "raw" function
  def raw_read(%Zung.Client{} = client) do
    msg = Connection.read(client.connection_id)
    case msg do
      {:none} -> raw_read(%Zung.Client{} = client)
      {:ok, data} ->
        Session.refresh_session(client.session_id)
        data
      _ -> raise Zung.Error.Connection.Lost
    end
  end
  def raw_clear_screen(%Zung.Client{} = client), do: raw_write(client, Enum.reduce(1..40, "", fn _e, acc -> "||NL||" <> acc end))
  def raw_write_line(%Zung.Client{} = client, data), do: raw_write(client, "#{data}||NL||")
  def raw_write(%Zung.Client{} = client, data) do
    Connection.write(client.connection_id, data)
  end
end
