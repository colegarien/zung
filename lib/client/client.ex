defmodule Zung.Client do
  @enforce_keys [:session_id, :connection_id]
  defstruct [:session_id, :connection_id, :game_state, input_buffer: :queue.new, output_buffer: :queue.new]

  alias Zung.Client.Connection
  alias Zung.Client.Session
  alias Zung.Client.User

  defmodule GameState do
    defstruct [:username, :room_id]
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
    if :queue.is_empty(client.input_buffer) do
      {client, nil}
    else
      {{:value, input}, new_queue} = :queue.out(client.input_buffer)
      {%Zung.Client{client | input_buffer: new_queue}, input}
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
      Zung.Client.write_data(client, message)
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

    # TODO should this go somewhere else?
    Connection.subscribe(client.connection_id, :ooc)
  end

  def publish(%Zung.Client{} = client, channel, message) do
    Connection.publish(client.connection_id, channel, message)
  end

  def force_ansi(%Zung.Client{} = client, use_ansi?) do
    Connection.use_ansi(client.connection_id, use_ansi?)
  end

  def shutdown(%Zung.Client{} = client) do
    Session.end_session(client.session_id)
    Connection.end_connection(client.connection_id)
  end

  def read_line(%Zung.Client{} = client) do
    msg = Connection.read(client.connection_id)
    case msg do
      {:none} -> read_line(%Zung.Client{} = client)
      {:ok, data} ->
        Session.refresh_session(client.session_id)
        data
      _ -> raise Zung.Error.Connection.Lost
    end
  end

  def clear_screen(%Zung.Client{} = client) do
    write_data(client, Enum.reduce(1..40, "", fn _e, acc -> "||NL||" <> acc end))
  end

  def write_line(%Zung.Client{} = client, data), do: write_data(client, "#{data}||NL||")
  def write_data(%Zung.Client{} = client, data) do
    Connection.write(client.connection_id, data)
  end
end
