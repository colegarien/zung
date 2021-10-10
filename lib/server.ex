defmodule Zung.Server do
  require Logger

  def accept(port) do
    {:ok, socket} = :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])
    Logger.info "Accepting connections on port #{port}"
    loop_accept(socket)
  end

  defp loop_accept(socket) do
    {:ok, client_socket} = :gen_tcp.accept(socket)
    {:ok, pid} = Task.Supervisor.start_child(Zung.Server.TaskSupervisor, fn -> serve_client(%Zung.Client{socket: client_socket}) end)
    :ok = :gen_tcp.controlling_process(client_socket, pid)
    loop_accept(socket)
  end

  def serve_client(%Zung.Client{} = client) do
    try do
      Zung.State.Manager.run({Zung.State.Login.Intro, %{}}, client)
    rescue
      Zung.Error.ConnectionClosed -> Logger.info("Client connection closed.")
      e in Zung.Error.SecurityConcern ->
        Logger.info("Security Concern Raised: #{e.message}")
        msg = if e.show_client, do: e.message, else: "An error occurred."
        Zung.Client.write_line(client, "||BOLD||||RED||#{msg}||RESET||")
      e ->
        Logger.error(Exception.format(:error, e, __STACKTRACE__))
        Zung.Client.write_line(client, "||BOLD||||RED||An error occurred.||RESET||")
    end

    shutdown_client(client)
  end

  def shutdown_client(%Zung.Client{} = client) do
    # TODO close session, shutdown any pending data, maybe do some logging etc etc
    Zung.Client.write_line(client, "||BOLD||||GRN||Bye bye!||RESET||")
  end

end
