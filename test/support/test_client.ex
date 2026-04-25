defmodule TestClient do
  @port 4040
  @default_timeout 300

  def connect do
    {:ok, socket} =
      :gen_tcp.connect(~c"localhost", @port, [:binary, packet: :line, active: false])

    socket
  end

  def send_and_recv(socket, command, timeout \\ @default_timeout) do
    :ok = :gen_tcp.send(socket, command <> "\r\n")
    recv_all(socket, "", timeout)
  end

  def drain(socket, timeout \\ @default_timeout) do
    recv_all(socket, "", timeout)
  end

  # Returns the final recv output (Welcome + room description).
  # Follows the 7-step new-account happy path with no ANSI.
  def login_new(socket, username, password) do
    # → "User does not exist..."
    send_and_recv(socket, username)
    # → creation wizard welcome + username prompt
    send_and_recv(socket, "new")
    # → password prompt
    send_and_recv(socket, username)
    # → confirm prompt
    send_and_recv(socket, password)
    # → ANSI color check
    send_and_recv(socket, password)
    # → Congratulations (Finalize state)
    send_and_recv(socket, "n")
    # → Welcome + room description (Game.Init)
    send_and_recv(socket, "")
  end

  defp recv_all(socket, output, timeout) do
    case :gen_tcp.recv(socket, 0, timeout) do
      {:ok, line} -> recv_all(socket, output <> line, timeout)
      _ -> output
    end
  end
end
