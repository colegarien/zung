defmodule Zung.Client do
  @enforce_keys [:socket, :session_id, :use_ansi?]
  defstruct [:socket, :session_id, use_ansi?: false]

  def read_line(%Zung.Client{} = client) do
    # TODO consider actually handling the negotiations, might be able to wrestle puTTY to not act weird by default
    # For info on telnet negotiations check out https://www.iana.org/assignments/telnet-options/telnet-options.xhtml
    # Currently, this strips out Telnet Negotiations and Trims Whitespace
    msg = :gen_tcp.recv(client.socket, 0) # TODO restructure to use "active" sockets instead of passive (this will make it easier to respond to ALL kinds of events)
    if Zung.Session.is_expired?(client.session_id), do: raise Zung.Error.Connection.SessionExpired

    case msg do
      {:ok, data} ->
        Zung.Session.refresh_session(client.session_id)
        data |> String.replace(~r/(\xFF[\xFE\xFD\xFC\xFB][\x01-\x31])*/, "") |> String.trim()
      {:error, :timeout} -> read_line(client)
      _ -> raise Zung.Error.Connection.Lost
    end

  end

  def clear_screen(%Zung.Client{} = client) do
    write_data(client, Enum.reduce(1..40, "", fn _e, acc -> "||NL||" <> acc end))
  end

  def write_line(%Zung.Client{} = client, data), do: write_data(client, "#{data}||NL||")
  def write_data(%Zung.Client{} = client, data) do
    :gen_tcp.send(client.socket, Zung.Game.Templater.template(data, client.use_ansi?))
  end
end
