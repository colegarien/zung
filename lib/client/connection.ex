defmodule Zung.Client.Connection do
  @enforce_keys [:id]
  defstruct [:id]

  require Logger
  use GenServer

# TODO implement swappable "input" and "output" buffers
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

  def flush_output(connection) do
    GenServer.cast(connection.id, :flush_output)
  end

  def use_ansi(connection, use_ansi?) do
    GenServer.cast(connection.id, {:use_ansi, use_ansi?})
  end

  def end_connection(connection) do
    GenServer.cast(connection.id, :end)
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

  def handle_cast(:flush_output, state) do
    if :queue.is_empty(state.output_buffer) do
      {:noreply, state}
    else
      {message, new_queue} = build_output({"", state.output_buffer})
      send_data(state.socket, message, state.use_ansi?)
      {:noreply, %{state |  output_buffer: new_queue}}
    end
  end

  def handle_cast({:use_ansi, use_ansi?}, state), do: {:noreply, %{state | use_ansi?: use_ansi?}}

  def handle_cast(:end, %{socket: socket, use_ansi?: use_ansi?} = state) do
    send_data(socket, "||BOLD||||GRN||Bye bye!||RESET||||NL||", use_ansi?)
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

  def handle_info({publisher_pid, channel, {username, message}}, %{socket: socket, use_ansi?: use_ansi?} = state) do
    from_user_text = if publisher_pid != self(), do: " #{username}", else: ""
    send_data(socket, "||NL||||BOLD||||YEL||[||MAG||#{channel |> to_string |> String.upcase}||YEL||]#{from_user_text}: #{message}||RESET||||NL||", use_ansi?)
    {:noreply, state}
  end

  def handle_info(msg, state) do
    Logger.info "received message by #{inspect self()} > #{inspect msg}"
    {:noreply, state}
  end


  # TODO move to "output buffer"
  defp build_output({message, queue}) do
    if :queue.is_empty(queue) do
      {message <> "||NL||||RESET||> ", queue}
    else
      {{:value, value}, new_queue} = :queue.out(queue)
      {message <> value <> "||NL||", new_queue} |> build_output
    end
  end
end
