defmodule Zung.Application do
  use Application

  def start(_type, _args) do
    port = String.to_integer(System.get_env("PORT") || "4040")

    children = [
      {Zung.Session, %{}},
      {Zung.DataStore, %{
        users: [
          %{
            account_name: "ozzy",
            password: "pass123",
            use_ansi?: true
          },
        ],
        locations: %{
          "ozzy" => "newbie/room_1",
        },
        rooms: %{
          "newbie/room_1" => %Zung.Game.Room{
            id: "newbie/room_1",
            title: "The Brig",
            description: "A small, cramped room in the bottom of a ship.||NL||The walls are carved up with cryptic scratchings.",
            flavor_texts: [
              %{
                keywords: ["cryptic scratchings", "scratchings", "carvings", "scratches"],
                text: "You barely make out one of the scrathings, ||BOLD||||ITALIC||\"2021-01-08\"||RESET||"
              },
            ],
            exits: [ %{ direction: :north, to: "newbie/room_2"} ],
          },
          "newbie/room_2" => %Zung.Game.Room{
            id: "newbie/room_2",
            title: "The Lower Deck",
            description: "The damp, musty underbelly of a ship.",
            exits: [ %{direction: :up, to: "newbie/room_3"}, %{direction: :south, to: "newbie/room_1"} ],
          },
          "newbie/room_3" => %Zung.Game.Room{
            id: "newbie/room_3",
            title: "The Main Deck",
            description: "The top deck of this vessel.||NL||The ship is docked and ready for disembarkment.",
            exits: [ %{direction: :down, to: "newbie/room_2"} ],
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
