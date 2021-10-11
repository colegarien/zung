defmodule Zung.IntegrationTest do
  use ExUnit.Case
  @moduletag :capture_log

  setup do
    Application.stop(:zung)
    :ok = Application.start(:zung)
  end

  setup do
    opts = [:binary, packet: :line, active: false]
    {:ok, socket} = :gen_tcp.connect('localhost', 4040, opts)
    %{socket: socket}
  end

  test "new account and room navigation", %{socket: socket} do
    # User doesn't exist yet
    assert send_and_recv(socket, "cool_name") =~ "does not exist"

    # Start user creation
    assert send_and_recv(socket, "new") =~ "Welcome\ to\ Zung"

    # Try invalid user names
    assert send_and_recv(socket, "new") =~ "cannot"
    assert send_and_recv(socket, "a") =~ "invalid"
    assert send_and_recv(socket, "_wad") =~ "invalid"
    assert send_and_recv(socket, "+!_@#)*WADsdaw") =~ "invalid"

    # Give good user name a try a bad password
    send_and_recv(socket, "cool_name")
    assert send_and_recv(socket, "123") =~ "Password is invalid"

    # Mis-match passwords entered
    send_and_recv(socket, "password123!")
    assert send_and_recv(socket, "password") =~ "match"

    # Enter matching passwords and finish user creation
    send_and_recv(socket, "password123!")
    assert send_and_recv(socket, "password123!") =~ "Success"

    # Log in as new user
    send_and_recv(socket, "cool_name")
    assert send_and_recv(socket, "bad_pass") =~ "Password"
    assert send_and_recv(socket, "password123!") =~ "cool_name"

    # Navigate rooms
    assert send_and_recv(socket, "look") =~ "Brig"
    send_and_recv(socket, "north")
    assert send_and_recv(socket, "look") =~ "Lower Deck"
    send_and_recv(socket, "up")
    assert send_and_recv(socket, "look") =~ "Main Deck"
    send_and_recv(socket, "down")
    assert send_and_recv(socket, "look") =~ "Lower Deck"
    send_and_recv(socket, "south")
    assert send_and_recv(socket, "look") =~ "Brig"

    # Log out
    assert send_and_recv(socket, "quit") =~ "Bye"
  end


  defp send_and_recv(socket, command) do
    :ok = :gen_tcp.send(socket, command <> "\r\n")
    recv_all(socket, "")
  end

  defp recv_all(socket, output) do
    case :gen_tcp.recv(socket, 0, 300) do
      {:ok, line} -> recv_all(socket, output <> line)
      _ -> output
    end
  end
end
