defmodule Zung.Client.Connection do
  @enforce_keys [:id]
  defstruct [:id]

  require Logger
  use GenServer

  def new_connection(socket) do
    {:ok, pid} = start_link(socket)
    take_over_socket(socket, pid)
    %Zung.Client.Connection{id: pid}
  end

  defp take_over_socket(socket, pid) do
    case :gen_tcp.controlling_process(socket, pid) do
      :ok -> true
      _ ->
        # wait for supervisor to transfer control
        Process.sleep(30)
        take_over_socket(socket, pid)
    end
  end

  def start_link(socket) do
    GenServer.start_link(__MODULE__, %{
        socket: socket,
        use_ansi?: false,
        input_buffer: :queue.new,
        output_buffer: :queue.new,
        is_closed: false
      })
  end
  def init(state), do: {:ok, state}

  # CLIENT SIDE
  def read(connection) do
    GenServer.call(connection.id, :read)
  end

  def write(connection, data) do
    GenServer.cast(connection.id, {:write, data})
  end

  def flush_output(connection, prompt?) do
    GenServer.cast(connection.id, {:flush_output, prompt?})
  end

  def use_ansi(connection, use_ansi?) do
    GenServer.cast(connection.id, {:use_ansi, use_ansi?})
  end

  def end_connection(connection) do
    GenServer.cast(connection.id, :end)
  end

  def force_closed(connection, reason) do
    GenServer.cast(connection.id, {:force_closed, reason})
  end

  def subscribe(connection, channel) do
    GenServer.cast(connection.id, {:subscribe, channel})
  end

  def publish(connection, channel, message) do
    GenServer.cast(connection.id, {:publish, channel, message})
  end

  def unsubscribe(connection, channel) do
    GenServer.cast(connection.id, {:unsubscribe, channel})
  end

  # SERVER SIDE
  def handle_call(:read, _from, %{input_buffer: input_buffer, is_closed: is_closed} = state) do
    cond do
      is_closed -> {:reply, {:error, :closed}, state}
      :queue.len(input_buffer) > 0 ->
        {{:value, data}, new_buffer} = :queue.out(input_buffer)
        {:reply, {:ok, data}, %{state | input_buffer: new_buffer}}
      true -> {:reply, {:none}, state}
    end
  end

  def handle_cast({:write, data}, state) do
    {:noreply, %{state | output_buffer: :queue.in(data, state.output_buffer)}}
  end

  def handle_cast({:flush_output, prompt?}, state) do
    if :queue.is_empty(state.output_buffer) do
      {:noreply, state}
    else
      {message, new_queue} = build_output({"||NL||", state.output_buffer}, prompt?)
      send_data(state.socket, message, state.use_ansi?)
      {:noreply, %{state |  output_buffer: new_queue}}
    end
  end

  def handle_cast({:use_ansi, use_ansi?}, state), do: {:noreply, %{state | use_ansi?: use_ansi?}}

  def handle_cast(:end, %{socket: socket, use_ansi?: use_ansi?} = state) do
    send_data(socket, "||BOLD||||GRN||Bye bye!||RESET||||NL||", use_ansi?)
    {:stop, :normal, %{state|is_closed: true}}
  end

  def handle_cast({:force_closed, reason}, %{socket: socket, use_ansi?: use_ansi?} = state) do
    send_data(socket, reason, use_ansi?)
    :gen_tcp.close(socket)
    {:stop, :normal, %{state|is_closed: true}}
  end

  def handle_cast({:subscribe, channel}, state) do
    Zung.PubSub.subscribe(channel)
    {:noreply, state}
  end

  def handle_cast({:publish, channel, message}, state) do
    Zung.PubSub.publish(channel, message)
    {:noreply, state}
  end


  def handle_cast({:unsubscribe, channel}, state) do
    Zung.PubSub.unsubscribe(channel)
    {:noreply, state}
  end

  defp send_data(socket, data, use_ansi?) do
    :gen_tcp.send(socket, Zung.Game.Templater.template(data, use_ansi?))
  end


  def handle_info({:tcp, _, data}, %{input_buffer: input_buffer} = state) do
    # For info on telnet negotiations check out https://www.iana.org/assignments/telnet-options/telnet-options.xhtml
    # Currently, this strips out Telnet Negotiations and Trims Whitespace
    clean_data = data
      |> String.replace(~r/(\xFF[\xFE\xFD\xFC\xFB][\x01-\x31])*/, "")
      |> String.trim()

    {:noreply, %{state | input_buffer: :queue.in(clean_data, input_buffer)}}
  end
  def handle_info({:tcp_closed, _}, state), do: {:noreply, %{state|is_closed: true}}
  def handle_info({:tcp_error, _}, state), do: {:noreply, %{state|is_closed: true}}

  def handle_info({publisher_pid, {:chat, chat_room}, {username, message}}, state) do
    from_user_text = if publisher_pid != self(), do: " #{username}", else: ""
    handle_cast({:write, "||BOLD||||YEL||[||MAG||#{chat_room |> to_string |> String.upcase}||YEL||]#{from_user_text}: #{message}||RESET||"}, state)
  end

  def handle_info({publisher_pid, {:room, _room_id}, {:say, username, message}}, state) do
    from_user_text = if publisher_pid != self(), do: "#{username} says: ", else: "You say: "
    handle_cast({:write, "||CYA||#{from_user_text}#{message}||RESET||"}, state)
  end

  def handle_info(msg, state) do
    Logger.info "received message by #{inspect self()} > #{inspect msg}"
    {:noreply, state}
  end

  defp build_output({message, queue}, prompt?) do
    if :queue.is_empty(queue) do
      prompt = if prompt?, do: "||NL||||RESET||> ", else: ""
      {message <> prompt, queue}
    else
      {{:value, value}, new_queue} = :queue.out(queue)
      {message <> value <> "||NL||", new_queue} |> build_output(prompt?)
    end
  end
end
