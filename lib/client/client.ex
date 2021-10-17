defmodule Zung.Client do
  @enforce_keys [:session_id, :connection_id]
  defstruct [:session_id, :connection_id]

  alias Zung.Client.Connection
  alias Zung.Client.Session
  alias Zung.Client.User

  def new(socket) do
    session_id = Session.new_session(socket)
    {:ok, connection_id} = Connection.start_link(socket)
    :ok = :gen_tcp.controlling_process(socket, connection_id)
    %Zung.Client{
      session_id: session_id,
      connection_id: connection_id,
    }
  end

  def authenticate_as(%Zung.Client{} = client, username) do
      use_ansi? = User.get_setting(username, :use_ansi?)

      User.log_login(username)
      Session.authenticate_session(client.session_id, username)
      Connection.use_ansi(client.connection_id, use_ansi?)
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
