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
        ],
        locations: %{
          "ozzy" => "newbie/room_1",
        },
        rooms: %{
          "newbie/room_1" => %Zung.Game.Room{
            id: "newbie/room_1",
            title: "The Brig",
            description: "A small, cramped room in the bottom of a ship",
            exits: %{ north: "newbie/room_2" },
          },
          "newbie/room_2" => %Zung.Game.Room{
            id: "newbie/room_2",
            title: "The Lower Deck",
            description: "The damp, musty underbelly of a ship.",
            exits: %{up: "newbie/room_3", south: "newbie/room_1"},
          },
          "newbie/room_3" => %Zung.Game.Room{
            id: "newbie/room_3",
            title: "The Main Deck",
            description: "The top deck of this vessel.||NL||The ship is docked and ready for disembarkment.",
            exits: %{down: "newbie/room_2"},
          },
        },
      }},
      {Task.Supervisor, name: Zung.Server.TaskSupervisor},
      Supervisor.child_spec({Task, fn -> Zung.Server.accept(port) end}, restart: :permanent)
    ]

    opts = [strategy: :one_for_one, name: Zung.Server.Supervisor]
    Supervisor.start_link(children, opts)
  end

end
