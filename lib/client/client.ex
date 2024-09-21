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
      joined_chat_rooms: []
    ]
  end

  def new(connection) do
    session_id = Session.new_session(connection)

    %Zung.Client{
      session_id: session_id,
      connection: connection
    }
  end

  def pop_input(%Zung.Client{} = client) do
    msg = Connection.read(client.connection)

    case msg do
      {:none} ->
        {client, nil}

      {:ok, data} ->
        Session.refresh_session(client.session_id)
        {client, data}

      _ ->
        raise Zung.Error.Connection.Lost
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

  def leave_room(%Zung.Client{} = client, old_room) do
    if(client.game_state !== nil) do
      Connection.unsubscribe(client.connection, {:room, old_room.id})
      client
    else
      client
    end
  end

  def enter_room(%Zung.Client{} = client, new_room) do
    if(client.game_state !== nil) do
      Zung.DataStore.update_current_room_id(client.game_state.username, new_room.id)
      Connection.subscribe(client.connection, {:room, new_room.id})

      %Zung.Client{
        client
        | game_state: %Zung.Client.GameState{client.game_state | room: new_room}
      }
      |> Zung.Client.push_output(Zung.Game.Room.describe(new_room))
    else
      client
    end
  end

  def join_chat(%Zung.Client{} = client, chat_rooms = []),
    do:
      Enum.reduce(chat_rooms, client, fn chat_room, new_client ->
        join_chat(new_client, chat_room)
      end)

  def join_chat(%Zung.Client{} = client, chat_room) do
    if(client.game_state !== nil and chat_room not in client.game_state.joined_chat_rooms) do
      Connection.subscribe(client.connection, {:chat, String.to_atom(chat_room)})

      Map.put(
        client,
        :game_state,
        Map.put(client.game_state, :joined_chat_rooms, [
          chat_room | client.game_state.joined_chat_rooms
        ])
      )
    else
      client
    end
  end

  def say_to_room(%Zung.Client{} = client, room_id, message) do
    Connection.publish(
      client.connection,
      {:room, room_id},
      {:say, client.game_state.username, message}
    )

    client
  end

  def publish_to_chat(%Zung.Client{} = client, chat_room, message) do
    Connection.publish(
      client.connection,
      {:chat, chat_room},
      {client.game_state.username, message}
    )

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

  def raw_clear_screen(%Zung.Client{} = client),
    do: raw_write(client, Enum.reduce(1..40, "", fn _e, acc -> "||NL||" <> acc end))

  def raw_write_line(%Zung.Client{} = client, data), do: raw_write(client, "#{data}||NL||")

  def raw_write(%Zung.Client{} = client, data) do
    client
    |> push_output(data)
    |> flush_output(false)
  end
end
