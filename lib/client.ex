defmodule Zung.Client do
  @enforce_keys [:socket, :session_id, :use_ansi?]
  defstruct [:socket, :session_id, use_ansi?: false]

  @templating_regex ~r/\|\|([A-Z_]+)?\|\|/ # ||TEMPLATE_WORD_HERE||
  @primitive_templating_replacements %{
    "NL" => "\r\n",
    "ECHO_OFF" => <<255, 251, 1>>,
    "ECHO_ON" => <<255, 252, 1>>,
  }
  @ansi_templating_replacements %{
    "NL" => "\r\n",
    "RESET" => "\e[0m",
    "BOLD" => "\e[1m",
    "ITALIC" => "\e[3m",
    "UNDERLINE" => "\e[4m",
    "BLINK_SLOW" => "\e[5m",
    "BLINK_FAST" => "\e[6m",
    "INVERT" => "\e[7m",
    "BLK" => "\e[30m",
    "RED" => "\e[31m",
    "GRN" => "\e[32m",
    "YEL" => "\e[33m",
    "BLU" => "\e[34m",
    "MAG" => "\e[35m",
    "CYA" => "\e[36m",
    "WHT" => "\e[37m",
    "BLK_BK" => "\e[40m",
    "RED_BK" => "\e[41m",
    "GRN_BK" => "\e[42m",
    "YEL_BK" => "\e[43m",
    "BLU_BK" => "\e[44m",
    "MAG_BK" => "\e[45m",
    "CYA_BK" => "\e[46m",
    "WHT_BK" => "\e[47m",
    "ECHO_OFF" => <<255, 251, 1>>,
    "ECHO_ON" => <<255, 252, 1>>,
  }

  def read_line(%Zung.Client{} = client) do
    # TODO consider actually handling the negotiations, might be able to wrestle puTTY to not act weird by default
    # For info on telnet negotiations check out https://www.iana.org/assignments/telnet-options/telnet-options.xhtml
    # Currently, this strips out Telnet Negotiations and Trims Whitespace
    msg = :gen_tcp.recv(client.socket, 0)
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
    replacements = if client.use_ansi?, do: @ansi_templating_replacements, else: @primitive_templating_replacements
    :gen_tcp.send(client.socket, Regex.replace(@templating_regex, data, fn _, match ->
      if Map.has_key?(replacements, match), do: replacements[match], else: ""
    end))
  end
end
