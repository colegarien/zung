defmodule Zung.Client.Connection do
  require Logger
  use GenServer

  def start_link(socket) do
    GenServer.start_link(__MODULE__, %{socket: socket, use_ansi?: false, queue: :queue.new, is_closed: false})
  end
  def init(state), do: {:ok, state}

  # CLIENT SIDE
  def read(pid) do
    GenServer.call(pid, :read)
  end

  def write(pid, data) do
    GenServer.cast(pid, {:write, data})
  end

  def use_ansi(pid, use_ansi?) do
    GenServer.cast(pid, {:use_ansi, use_ansi?})
  end

  def end_connection(pid) do
    GenServer.cast(pid, :end)
  end

  # SERVER SIDE
  def handle_call(:read, _from, %{queue: queue, is_closed: is_closed} = state) do
    cond do
      is_closed -> {:reply, {:error, :closed}, state}
      :queue.len(queue) > 0 ->
        {{:value, data}, new_queue} = :queue.out(queue)
        {:reply, {:ok, data}, %{state | queue: new_queue}}
      true -> {:reply, {:none}, state}
    end
  end

  def handle_cast({:write, data}, %{socket: socket, use_ansi?: use_ansi?} = state) do
    send_data(socket, data, use_ansi?)
    {:noreply, state}
  end

  def handle_cast({:use_ansi, use_ansi?}, state), do: {:noreply, %{state | use_ansi?: use_ansi?}}

  def handle_cast(:end, %{socket: socket, use_ansi?: use_ansi?} = state) do
    send_data(socket, "||BOLD||||GRN||Bye bye!||RESET||||NL||", use_ansi?)
    {:stop, :normal, %{state|is_closed: true}}
  end

  defp send_data(socket, data, use_ansi?) do
    :gen_tcp.send(socket, Zung.Game.Templater.template(data, use_ansi?))
  end


  def handle_info({:tcp, _, data}, %{queue: queue} = state) do
    # TODO consider actually handling the negotiations, might be able to wrestle puTTY to not act weird by default
    # For info on telnet negotiations check out https://www.iana.org/assignments/telnet-options/telnet-options.xhtml
    # Currently, this strips out Telnet Negotiations and Trims Whitespace
    clean_data = data
      |> String.replace(~r/(\xFF[\xFE\xFD\xFC\xFB][\x01-\x31])*/, "")
      |> String.trim()

    {:noreply, %{state | queue: :queue.in(clean_data, queue)}}
  end
  def handle_info({:tcp_closed, _}, state), do: {:noreply, %{state|is_closed: true}}
  def handle_info({:tcp_error, _}, state), do: {:noreply, %{state|is_closed: true}}

end
