defmodule Zung.Server do
  require Logger

  def accept(port) do
    {:ok, socket} = :gen_tcp.listen(port, [:binary, packet: :line, active: true, reuseaddr: true])
    Logger.info "Accepting connections on port #{port}"
    loop_accept(socket)
  end

  defp loop_accept(socket) do
    {:ok, client_socket} = :gen_tcp.accept(socket)
    {:ok, pid} = Task.Supervisor.start_child(Zung.Server.TaskSupervisor, fn ->
      client_socket
        |> Zung.Client.Connection.new_connection
        |> Zung.Client.new
        |> serve_client
    end)
    :ok = :gen_tcp.controlling_process(client_socket, pid)
    loop_accept(socket)
  end

  def serve_client(%Zung.Client{} = client) do
    try do
      Zung.State.Manager.run({Zung.State.Login.Intro, client, %{}})
    rescue
      e in [Zung.Error.Connection.Closed,Zung.Error.Connection.Lost,Zung.Error.Connection.SessionExpired] -> Logger.info(e.message)
      e in Zung.Error.SecurityConcern ->
        Logger.info("Security Concern Raised: #{e.message}")
        msg = if e.show_client, do: e.message, else: "An error occurred."
        Zung.Client.raw_write_line(client, "||BOLD||||RED||#{msg}||RESET||")
      e ->
        Logger.error(Exception.format(:error, e, __STACKTRACE__))
        Zung.Client.raw_write_line(client, "||BOLD||||RED||An error occurred.||RESET||")
    end

    # shutdown connections "gracefully"
    Zung.Client.shutdown(client)
  end


end
