defmodule Zung.Application do
  use Application

  def start(_type, _args) do
    port = String.to_integer(System.get_env("PORT") || "4040")

    children = [
      {Zung.Client.User,
       %{
         "ozzy" => %Zung.Client.User.State{
           Zung.Client.User.State.new()
           | username: "ozzy",
             password: Zung.Client.User.hash_password("ozzy", "pass1234"),
             settings: %{
               use_ansi?: true
             }
         }
       }},
      {Zung.Client.Session, %{}},
      {Zung.DataStore,
       %{
         locations: %{
           "ozzy" => "newbie/room_1"
         },
         rooms: %{
           "newbie/room_1" => %Zung.Game.Room{
             id: "newbie/room_1",
             title: "The Brig",
             description:
               "A small, cramped room in the bottom of a ship.||NL||The walls are carved up with cryptic scratchings.||NL||The water pipe in the corner of the room looks just big enough to enter.",
             flavor_texts: [
               %{
                 id: "scratchings",
                 keywords: ["cryptic scratchings", "scratchings", "carvings", "scratches"],
                 text:
                   "You barely make out one of the scrathings, ||BOLD||||ITALIC||\"2021-01-08\"||RESET||"
               }
             ],
             exits: [
               %Zung.Game.Room.Exit{direction: :north, to: "newbie/room_2"},
               %Zung.Game.Room.Exit{name: "water pipe", to: "newbie/room_3"}
             ]
           },
           "newbie/room_2" => %Zung.Game.Room{
             id: "newbie/room_2",
             title: "The Lower Deck",
             description: "The damp, musty underbelly of a ship.",
             exits: [
               %Zung.Game.Room.Exit{direction: :up, to: "newbie/room_3"},
               %Zung.Game.Room.Exit{direction: :south, to: "newbie/room_1"}
             ],
             objects: [
               %Zung.Game.Object{
                 id: "stack_of_planks",
                 name: "a stack of planks",
                 description: "A big stack of old wooden planks lies here.",
                 keywords: [
                   "stack of old wooden planks",
                   "stack of planks",
                   "old wooden planks",
                   "wooden planks",
                   "planks"
                 ]
               },
               %Zung.Game.Object{
                 id: "another_stack_of_planks",
                 name: "another stack of planks",
                 description: "Another big stack of old wooden planks lies here.",
                 keywords: ["another stack of planks"]
               }
             ]
           },
           "newbie/room_3" => %Zung.Game.Room{
             id: "newbie/room_3",
             title: "The Main Deck",
             description:
               "The top deck of this vessel.||NL||The ship is docked and ready for disembarkment.",
             exits: [%Zung.Game.Room.Exit{direction: :down, to: "newbie/room_2"}]
           }
         }
       }},
      {Task.Supervisor, name: Zung.Server.TaskSupervisor},
      Supervisor.child_spec({Task, fn -> Zung.Server.accept(port) end}, restart: :permanent)
    ]

    opts = [strategy: :one_for_one, name: Zung.Server.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
