defmodule Zung.Application do
  use Application

  def start(_type, _args) do
    port = String.to_integer(System.get_env("PORT") || "4040")

    children = [
      {Zung.DataStore, %{
        users: [
          %{
            account_name: "ozzy",
            password: "pass123",
          },
        ]
      }},
      {Task.Supervisor, name: Zung.Server.TaskSupervisor},
      Supervisor.child_spec({Task, fn -> Zung.Server.accept(port) end}, restart: :permanent)
    ]

    opts = [strategy: :one_for_one, name: Zung.Server.Supervisor]
    Supervisor.start_link(children, opts)
  end

end
