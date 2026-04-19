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
             exits: [
               %Zung.Game.Room.Exit{direction: :down, to: "newbie/room_2"},
               %Zung.Game.Room.Exit{
                 direction: :north,
                 to: "kralovice_mor/skalni_kraj/dolu_pristup"
               }
             ]
           },
           # region: kralovice_mor
           "kralovice_mor/skalni_kraj/dolu_pristup" => %Zung.Game.Room{
             id: "kralovice_mor/skalni_kraj/dolu_pristup",
             title: "Lower Quarry Level",
             description:
               "A vast underground cavern filled with mining equipment and rows of ore-filled crates, casting long shadows across the rough stone floor.",
             exits: [
               %Zung.Game.Room.Exit{
                 direction: :west,
                 to: "kralovice_mor/skalni_kraj/pristupna_cesta",
                 description:
                   "A narrow entrance leads back to the Quarry Entrance, where the sounds of the outside world are muffled by thick stone walls."
               },
               %Zung.Game.Room.Exit{
                 direction: :north,
                 to: "kralovice_mor/skalni_kraj/smyczny_tunnel",
                 description:
                   "A broken and twisted tunnel stretches into darkness, promising secrets of the Old Mine."
               },
               %Zung.Game.Room.Exit{
                 direction: :east,
                 to: "kralovice_mor/skalni_kraj/vysoke_cesta",
                 description:
                   "A steep staircase leads upward to the Upper Quarry Level, where the air is fresher and the noise of mining grows louder."
               },
               %Zung.Game.Room.Exit{
                 direction: :south,
                 to: "newbie/room_3",
                 description: "A narrow gang-plank back to the deck of the ship."
               }
             ]
           },
           "kralovice_mor/dokonalulice/east_gateway_bridgeway" => %Zung.Game.Room{
             id: "kralovice_mor/dokonalulice/east_gateway_bridgeway",
             title: "East Gateway Bridgeway",
             description:
               "The wide, straight bridge spans a narrow canal, lined with intricately carved stone statues that once proudly guarded the gateway to Upper Town.",
             exits: [
               %Zung.Game.Room.Exit{
                 direction: :west,
                 to: "kralovice_mor/dokonalulice/north_gate_entrance",
                 description:
                   "A grand entrance with ornate arches, guarded by two imposing stone statues that seem to watch all who pass through."
               },
               %Zung.Game.Room.Exit{
                 direction: :north,
                 to: "kralovice_mor/dokonalulice/east_town_hall",
                 description:
                   "A short staircase leads up to the heavy wooden doors of the East Town Hall, where the town's leaders convene in secret."
               },
               %Zung.Game.Room.Exit{
                 direction: :east,
                 to: "kralovice_mor/pohorenie_klasy/pristav_na_doke",
                 description:
                   "The canal widens out into a small lake, reflecting the fading light of day and casting an eerie glow over the surrounding buildings."
               }
             ],
             objects: [
               %Zung.Game.Object{
                 id: "worn_stone_bench_sits_at_the_midpoint_of_the_bridge",
                 name: "A worn stone bench sits at the midpoint of the bridge",
                 description: "Worn stone bench sits at the midpoint of the bridge lies here.",
                 keywords: [
                   "worn stone bench sits at the midpoint of the bridge",
                   "bridge",
                   "the bridge"
                 ]
               }
             ]
           },
           "kralovice_mor/dokonalulice/east_town_hall" => %Zung.Game.Room{
             id: "kralovice_mor/dokonalulice/east_town_hall",
             title: "East Town Hall",
             description:
               "A grand, high-ceilinged chamber filled with dusty records and flickering candles casts a warm, yet dim glow over the room.",
             exits: [
               %Zung.Game.Room.Exit{
                 direction: :south,
                 to: "kralovice_mor/dokonalulice/east_gateway_bridgeway",
                 description:
                   "A large, ornate gate made of dark wood and iron stands at the southern exit, adorned with symbols of power and protection."
               },
               %Zung.Game.Room.Exit{
                 direction: :west,
                 to: "kralovice_mor/dokonalulice/west_garden_path",
                 description:
                   "A narrow passageway lined with cobweb-covered portraits leads out to the West Garden Path."
               },
               %Zung.Game.Room.Exit{
                 direction: :north,
                 to: "kralovice_mor/dokonalulice/north_mansion_entrance",
                 description:
                   "A grand staircase curves upward, vanishing into the shadows of the North Mansion Entrance."
               }
             ]
           },
           "kralovice_mor/moravian_walls/eastern_wall_crossing" => %Zung.Game.Room{
             id: "kralovice_mor/moravian_walls/eastern_wall_crossing",
             title: "Eastern Wall Crossing",
             description:
               "The narrow tunnel stretches out before you, its rough stone walls lined with old cobwebs and dimly lit by flickering torches.",
             exits: [
               %Zung.Game.Room.Exit{
                 direction: :west,
                 to: "kralovice_mor/moravian_walls/south_gate_entrance",
                 description:
                   "A large stone gate looms in the distance, adorned with rusty iron hinges and a heavy-looking iron knocker in the shape of a snarling lion's head."
               },
               %Zung.Game.Room.Exit{
                 direction: :north,
                 to: "kralovice_mor/moravian_walls/inner_gate_entrance",
                 description:
                   "A smaller, more ornate gate comes into view, its intricate carvings depicting scenes of battles long past."
               }
             ],
             objects: [
               %Zung.Game.Object{
                 id: "small_rusty_key",
                 name: "a small, rusty key",
                 description: "Small, rusty key lies here.",
                 keywords: ["small, rusty key", "key", "rusty key"]
               }
             ]
           },
           "kralovice_mor/moravian_walls/inner_gate_entrance" => %Zung.Game.Room{
             id: "kralovice_mor/moravian_walls/inner_gate_entrance",
             title: "Inner Gate Entrance",
             description:
               "Weathered stone walls, a small iron gate with rusty hinges and a heavy-looking wooden door that appears to be locked.",
             exits: [
               %Zung.Game.Room.Exit{
                 direction: :south,
                 to: "kralovice_mor/moravian_walls/eastern_wall_crossing",
                 description: "A narrow passageway leads to the Eastern Wall Crossing."
               },
               %Zung.Game.Room.Exit{
                 direction: :west,
                 to: "kralovice_mor/moravian_walls/west_wall_crossing",
                 description: "A short corridor extends to the West Wall Crossing."
               }
             ]
           },
           "kralovice_mor/pohorenie_klasy/kancelar_skupce_borovy" => %Zung.Game.Room{
             id: "kralovice_mor/pohorenie_klasy/kancelar_skupce_borovy",
             title: "Kancelar Skupce Borovy",
             description:
               "The office is a cramped, dimly lit space with peeling paint and rusty metal accents.||NL||A large wooden desk dominates the room, behind which sits a hulking figure with a thick beard and a calculating gaze.",
             exits: [
               %Zung.Game.Room.Exit{
                 direction: :south,
                 to: "kralovice_mor/pohorenie_klasy/radnice_stavby",
                 description:
                   "A narrow corridor stretches out into the darkness, lined with cobweb-covered portraits of forgotten shipwrights."
               },
               %Zung.Game.Room.Exit{
                 direction: :east,
                 to: "kralovice_mor/pohorenie_klasy/kapitanova_kamera",
                 description:
                   "A heavy wooden door with iron hinges leads to a secure chamber, rumored to contain sensitive business dealings."
               }
             ]
           },
           "kralovice_mor/pohorenie_klasy/kapitanova_kamera" => %Zung.Game.Room{
             id: "kralovice_mor/pohorenie_klasy/kapitanova_kamera",
             title: "Kapitonska Kamera",
             description:
               "The small, cluttered office is dimly lit, with only a single, dusty lantern providing light.||NL||Shelves line the walls, overflowing with nautical charts, tattered maps, and various trinkets collected from years at sea.",
             exits: [
               %Zung.Game.Room.Exit{
                 direction: :south,
                 to: "kralovice_mor/pohorenie_klasy/vytoky_na_doke",
                 description: "A narrow corridor stretches out into the heart of the docks"
               },
               %Zung.Game.Room.Exit{
                 direction: :west,
                 to: "kralovice_mor/pohorenie_klasy/kancelar_skupce_borovy",
                 description:
                   "A door leads to a cramped storage room filled with barrels and crates"
               }
             ],
             objects: [
               %Zung.Game.Object{
                 id: "worn_leather_bound_logbook",
                 name: "a worn leather-bound logbook",
                 description: "Worn leather-bound logbook lies here.",
                 keywords: ["worn leather-bound logbook", "logbook", "leather-bound logbook"]
               },
               %Zung.Game.Object{
                 id: "tarnished_brass_compass",
                 name: "a tarnished brass compass",
                 description: "Tarnished brass compass lies here.",
                 keywords: ["tarnished brass compass", "compass", "brass compass"]
               }
             ]
           },
           "kralovice_mor/pohorenie_klasy/krajina_tovarne" => %Zung.Game.Room{
             id: "kralovice_mor/pohorenie_klasy/krajina_tovarne",
             title: "Krajina Tovarne",
             description:
               "A maze of warehouses filled with crates, barrels, and shelves stacked haphazardly with all manner of goods.",
             exits: [
               %Zung.Game.Room.Exit{
                 direction: :north,
                 to: "kralovice_mor/pohorenie_klasy/vytoky_na_doke",
                 description:
                   "A rickety wooden staircase leads up to a catwalk overlooking the docks."
               },
               %Zung.Game.Room.Exit{
                 direction: :west,
                 to: "kralovice_mor/skalni_kraj/pristupna_cesta",
                 description:
                   "A rusty iron gate creaks in the wind, leading into the darkness of The Quarry."
               }
             ],
             objects: [
               %Zung.Game.Object{
                 id: "crates",
                 name: "Crates",
                 description: "Crates lies here.",
                 keywords: ["Crates"]
               },
               %Zung.Game.Object{
                 id: "barrels",
                 name: "Barrels",
                 description: "Barrels lies here.",
                 keywords: ["Barrels"]
               },
               %Zung.Game.Object{
                 id: "shelves",
                 name: "Shelves",
                 description: "Shelves lies here.",
                 keywords: ["Shelves"]
               }
             ]
           },
           "kralovice_mor/vysoka_ulice/kropec_kavka" => %Zung.Game.Room{
             id: "kralovice_mor/vysoka_ulice/kropec_kavka",
             title: "Pawn Shop",
             description:
               "Graffiti-covered walls and musty smell conceal the treasures within this scavenger's paradise.",
             exits: [
               %Zung.Game.Room.Exit{
                 direction: :south,
                 to: "kralovice_mor/vysoka_ulice/tradi_cafe",
                 description:
                   "A narrow alleyway leads to the bustling streets, where merchants hawk their wares with a mixture of charm and desperation."
               },
               %Zung.Game.Room.Exit{
                 direction: :east,
                 to: "kralovice_mor/vysoka_ulice/ulice_celar",
                 description:
                   "A rickety staircase plunges into darkness, the air growing colder with each step."
               }
             ],
             objects: [
               %Zung.Game.Object{
                 id: "rusted_lockpick",
                 name: "rusted lockpick",
                 description: "Rusted lockpick lies here.",
                 keywords: ["rusted lockpick", "lockpick"]
               },
               %Zung.Game.Object{
                 id: "tattered_map",
                 name: "tattered map",
                 description: "Tattered map lies here.",
                 keywords: ["tattered map", "map"]
               }
             ]
           },
           "kralovice_mor/skalni_kraj/krovna_vysledek" => %Zung.Game.Room{
             id: "kralovice_mor/skalni_kraj/krovna_vysledek",
             title: "Quarry's Central Gathering Area",
             description:
               "A large hall with rough-hewn wooden beams and a low ceiling, lit by flickering lanterns that cast eerie shadows on the walls.",
             exits: [
               %Zung.Game.Room.Exit{
                 direction: :south,
                 to: "kralovice_mor/skalni_kraj/pristupna_cesta",
                 description:
                   "A rickety wooden staircase leads down to the Quarry Entrance, where a group of burly miners are gathered arguing over wages."
               },
               %Zung.Game.Room.Exit{
                 direction: :north,
                 to: "kralovice_mor/skalni_kraj/zahnicky_budynek",
                 description:
                   "The entrance to the Old Mine's Office Building is marked by a faded sign that reads 'Miner's Guild' in peeling letters."
               },
               %Zung.Game.Room.Exit{
                 direction: :east,
                 to: "kralovice_mor/skalni_kraj/smyczny_tunnel",
                 description:
                   "A narrow tunnel stretches out into darkness beyond the edge of the lanterns, the sound of scurrying rodents and dripping water echoing from within."
               }
             ],
             objects: [
               %Zung.Game.Object{
                 id:
                   "large_wooden_table_in_the_center_of_the_room_is_scarred_and_worn_with_several_crates_and_barrels_stacked_haphazardly_around_its_edges",
                 name:
                   "A large wooden table in the center of the room is scarred and worn, with several crates and barrels stacked haphazardly around its edges.",
                 description:
                   "Large wooden table in the center of the room is scarred and worn, with several crates and barrels stacked haphazardly around its edges. lies here.",
                 keywords: [
                   "large wooden table in the center of the room is scarred and worn, with several crates and barrels stacked haphazardly around its edges.",
                   "edges.",
                   "its edges."
                 ]
               }
             ]
           },
           "kralovice_mor/dokonalulice/north_gate_entrance" => %Zung.Game.Room{
             id: "kralovice_mor/dokonalulice/north_gate_entrance",
             title: "North Gate Entrance",
             description:
               "A grand, ornate gate with intricate carvings and heavy iron hinges stands tall, guarded by two heavily armed city watchmen who eye potential intruders with suspicion.",
             exits: [
               %Zung.Game.Room.Exit{
                 direction: :east,
                 to: "kralovice_mor/dokonalulice/east_gateway_bridgeway",
                 description:
                   "A wide, arched bridge spans a deep chasm, leading to the East Gateway Bridgeway beyond."
               },
               %Zung.Game.Room.Exit{
                 direction: :north,
                 to: "kralovice_mor/moravian_walls/south_gate_entrance",
                 description:
                   "A narrow alleyway stretches northward, terminating at the South Gate Entrance."
               }
             ],
             objects: [
               %Zung.Game.Object{
                 id:
                   "large_wooden_gate_with_iron_hinges_and_a_heavy_iron_knocker_in_the_shape_of_a_lion_s_head",
                 name:
                   "a large wooden gate with iron hinges and a heavy iron knocker in the shape of a lion's head",
                 description:
                   "Large wooden gate with iron hinges and a heavy iron knocker in the shape of a lion's head lies here.",
                 keywords: [
                   "large wooden gate with iron hinges and a heavy iron knocker in the shape of a lion's head",
                   "head",
                   "lion's head"
                 ]
               }
             ]
           },
           "kralovice_mor/dokonalulice/north_mansion_entrance" => %Zung.Game.Room{
             id: "kralovice_mor/dokonalulice/north_mansion_entrance",
             title: "North Mansion Entrance",
             description:
               "A grand, high-ceilinged entrance with intricately carved stone columns and a sweeping staircase, its once-polished surface now worn by time and neglect.",
             exits: [
               %Zung.Game.Room.Exit{
                 direction: :south,
                 to: "kralovice_mor/dokonalulice/east_town_hall",
                 description:
                   "A grand staircase leads down to a bustling town hall, filled with the sounds of commerce and politics."
               },
               %Zung.Game.Room.Exit{
                 direction: :west,
                 to: "kralovice_mor/dokonalulice/south_balcony_view",
                 description:
                   "A narrow balcony offers a view of the sun-baked rooftops and crumbling walls of South Town."
               }
             ],
             objects: [
               %Zung.Game.Object{
                 id: "dusty_chandelier",
                 name: "a dusty chandelier",
                 description: "Dusty chandelier lies here.",
                 keywords: ["dusty chandelier", "chandelier"]
               },
               %Zung.Game.Object{
                 id: "worn_leather_armchair",
                 name: "a worn leather armchair",
                 description: "Worn leather armchair lies here.",
                 keywords: ["worn leather armchair", "armchair", "leather armchair"]
               }
             ]
           },
           "kralovice_mor/vysoka_ulice/pazar_stanec" => %Zung.Game.Room{
             id: "kralovice_mor/vysoka_ulice/pazar_stanec",
             title: "Market Stand",
             description:
               "The market stand is a cramped, shaded stall overflowing with exotic spices, rare herbs, and questionable trinkets.||NL||Shelves groan under the weight of dusty jars and tangled skeins of yarn.||NL||The air is thick with the scent of decay.",
             exits: [
               %Zung.Game.Room.Exit{
                 direction: :south,
                 to: "kralovice_mor/vysoka_ulice/strojarne",
                 description:
                   "The entrance to a nearby smithy beckons, smoke drifting lazily from its chimney."
               },
               %Zung.Game.Room.Exit{
                 direction: :west,
                 to: "kralovice_mor/vysoka_ulice/tradi_cafe",
                 description:
                   "A sign above the door reads 'Traditional Cafe', promising a respite from the city's grime."
               },
               %Zung.Game.Room.Exit{
                 direction: :north,
                 to: "kralovice_mor/vysoka_ulice/ulice_celar",
                 description:
                   "A narrow stairway descends into darkness, leading down into the depths of the cellars."
               }
             ],
             objects: [
               %Zung.Game.Object{
                 id: "exotic_spices",
                 name: "exotic spices",
                 description: "Exotic spices lies here.",
                 keywords: ["exotic spices", "spices"]
               },
               %Zung.Game.Object{
                 id: "rare_herbs",
                 name: "rare herbs",
                 description: "Rare herbs lies here.",
                 keywords: ["rare herbs", "herbs"]
               },
               %Zung.Game.Object{
                 id: "questionable_trinkets",
                 name: "questionable trinkets",
                 description: "Questionable trinkets lies here.",
                 keywords: ["questionable trinkets", "trinkets"]
               }
             ]
           },
           "kralovice_mor/pohorenie_klasy/pristav_na_doke" => %Zung.Game.Room{
             id: "kralovice_mor/pohorenie_klasy/pristav_na_doke",
             title: "Pristav na Doke",
             description:
               "Cramped stalls and worn wooden planks line the narrow dock, with sailors and traders haggling over goods and ship repairs.||NL||The air is thick with the smell of saltwater, tar, and smoke from the nearby workshops.",
             exits: [
               %Zung.Game.Room.Exit{
                 direction: :north,
                 to: "kralovice_mor/pohorenie_klasy/radnice_stavby",
                 description:
                   "Leads to the town hall, where officials govern the dock's operations."
               },
               %Zung.Game.Room.Exit{
                 direction: :east,
                 to: "kralovice_mor/pohorenie_klasy/krajina_tovarne",
                 description:
                   "Takes you into a network of cramped warehouses filled with cargo and supplies."
               },
               %Zung.Game.Room.Exit{
                 direction: :west,
                 to: "kralovice_mor/dokonalulice/east_gateway_bridgeway",
                 description:
                   "Opens onto the East Gateway Bridgeway, leading out of the district."
               }
             ],
             objects: [
               %Zung.Game.Object{
                 id: "weathered_wooden_crate_a_worn_leather_satchel",
                 name: "A weathered wooden crate, a worn leather satchel",
                 description: "Weathered wooden crate, a worn leather satchel lies here.",
                 keywords: [
                   "weathered wooden crate, a worn leather satchel",
                   "satchel",
                   "leather satchel"
                 ]
               }
             ]
           },
           "kralovice_mor/skalni_kraj/pristupna_cesta" => %Zung.Game.Room{
             id: "kralovice_mor/skalni_kraj/pristupna_cesta",
             title: "The Quarry Entrance",
             description:
               "Dust and rock litter the air, while the sound of pickaxes echoes through the canyon.||NL||The stench of coal smoke and decay hangs heavy over the area.",
             exits: [
               %Zung.Game.Room.Exit{
                 direction: :north,
                 to: "kralovice_mor/skalni_kraj/krovna_vysledek",
                 description:
                   "A narrow path winds deeper into the quarry, lined with makeshift stalls selling basic supplies."
               },
               %Zung.Game.Room.Exit{
                 direction: :east,
                 to: "kralovice_mor/pohorenie_klasy/krajina_tovarne",
                 description:
                   "A rickety wooden gate leads to Krajina Tovarne, a hub of commerce and trade."
               }
             ]
           },
           "kralovice_mor/pohorenie_klasy/radnice_stavby" => %Zung.Game.Room{
             id: "kralovice_mor/pohorenie_klasy/radnice_stavby",
             title: "Radnice Stavby",
             description:
               "The room is cluttered with dusty maps, yellowed parchment, and scattered tools.||NL||The walls are lined with wooden crates and barrels, and a large wooden desk dominates one side of the room.",
             exits: [
               %Zung.Game.Room.Exit{
                 direction: :south,
                 to: "kralovice_mor/pohorenie_klasy/pristav_na_doke",
                 description:
                   "A narrow corridor leads down to the docks, where the sound of seagulls and shouting dockworkers grows louder."
               },
               %Zung.Game.Room.Exit{
                 direction: :north,
                 to: "kralovice_mor/pohorenie_klasy/kancelar_skupce_borovy",
                 description:
                   "A short staircase leads up to a small office, adorned with intricate carvings and symbols of the shipyard's guilds."
               },
               %Zung.Game.Room.Exit{
                 direction: :east,
                 to: "kralovice_mor/pohorenie_klasy/vytoky_na_doke",
                 description:
                   "A large wooden door, adorned with iron hinges and a heavy-looking knocker in the shape of a sea serpent, opens onto a bustling dockside area."
               }
             ],
             objects: [
               %Zung.Game.Object{
                 id: "large_wooden_desk_a_set_of_dusty_maps_a_collection_of_old_tools",
                 name: "a large wooden desk, a set of dusty maps, a collection of old tools",
                 description:
                   "Large wooden desk, a set of dusty maps, a collection of old tools lies here.",
                 keywords: [
                   "large wooden desk, a set of dusty maps, a collection of old tools",
                   "tools",
                   "old tools"
                 ]
               }
             ]
           },
           "kralovice_mor/skalni_kraj/smyczny_tunnel" => %Zung.Game.Room{
             id: "kralovice_mor/skalni_kraj/smyczny_tunnel",
             title: "Broken Tunnel to the Old Mine",
             description:
               "A narrow, partially destroyed tunnel with rough-hewn stone walls and a low ceiling.||NL||Dust and debris coat everything, making it difficult to see more than a few feet ahead.",
             exits: [
               %Zung.Game.Room.Exit{
                 direction: :south,
                 to: "kralovice_mor/skalni_kraj/dolu_pristup",
                 description:
                   "A rickety wooden ladder leads down into darkness, vanishing from view as you descend."
               },
               %Zung.Game.Room.Exit{
                 direction: :west,
                 to: "kralovice_mor/skalni_kraj/krovna_vysledek",
                 description:
                   "The tunnel opens up to reveal a bustling area filled with miners and supply carts."
               },
               %Zung.Game.Room.Exit{
                 direction: :east,
                 to: "kralovice_mor/skalni_kraj/vchod_do_docku",
                 description:
                   "The air grows heavy with the scent of saltwater and seaweed as you approach the docks."
               }
             ],
             objects: [
               %Zung.Game.Object{
                 id: "rusty_lantern_hangs_from_a_hook_on_the_wall",
                 name: "A rusty lantern hangs from a hook on the wall",
                 description: "Rusty lantern hangs from a hook on the wall lies here.",
                 keywords: ["rusty lantern hangs from a hook on the wall", "wall", "the wall"]
               }
             ]
           },
           "kralovice_mor/dokonalulice/south_balcony_view" => %Zung.Game.Room{
             id: "kralovice_mor/dokonalulice/south_balcony_view",
             title: "South Balcony View",
             description:
               "A narrow, stone-walled balcony stretches out before you, its worn flagstones bearing faint scars from centuries of weathering.||NL||Above, a tangle of overgrown vines and creepers wraps itself around the sturdy stonework, as if nature itself is attempting to reclaim this once-majestic space.",
             exits: [
               %Zung.Game.Room.Exit{
                 direction: :south,
                 to: "kralovice_mor/dokonalulice/west_garden_path",
                 description:
                   "A narrow path winds its way down into the West Garden Path, overgrown with weeds and vines that seem to be closing in on the crumbling stonework."
               },
               %Zung.Game.Room.Exit{
                 direction: :east,
                 to: "kralovice_mor/dokonalulice/north_mansion_entrance",
                 description:
                   "A grand entrance beckons from the North Mansion, flanked by ornate ironwork and guarded by imposing stone statues that appear to be watching your every move."
               }
             ],
             objects: [
               %Zung.Game.Object{
                 id:
                   "worn_leather_bound_journal_lies_abandoned_on_a_nearby_stone_bench_its_pages_fluttering_in_the_breeze",
                 name:
                   "A worn, leather-bound journal lies abandoned on a nearby stone bench, its pages fluttering in the breeze.",
                 description:
                   "Worn, leather-bound journal lies abandoned on a nearby stone bench, its pages fluttering in the breeze. lies here.",
                 keywords: [
                   "worn, leather-bound journal lies abandoned on a nearby stone bench, its pages fluttering in the breeze.",
                   "breeze.",
                   "the breeze."
                 ]
               }
             ]
           },
           "kralovice_mor/moravian_walls/south_gate_entrance" => %Zung.Game.Room{
             id: "kralovice_mor/moravian_walls/south_gate_entrance",
             title: "South Gate Entrance",
             description:
               "A large, heavy stone gate with iron hinges and a complex locking mechanism dominates the entrance.||NL||The walls surrounding it are covered in thick layers of grime and moss, giving the impression that they're slowly being consumed by the environment.",
             exits: [
               %Zung.Game.Room.Exit{
                 direction: :west,
                 to: "kralovice_mor/moravian_walls/wall_entry_point",
                 description: "A narrow, dimly lit passageway leads to the Wall Entrance."
               },
               %Zung.Game.Room.Exit{
                 direction: :north,
                 to: "kralovice_mor/moravian_walls/west_wall_crossing",
                 description:
                   "A rickety wooden bridge spans a deep chasm, leading to the West Wall Crossing."
               },
               %Zung.Game.Room.Exit{
                 direction: :east,
                 to: "kralovice_mor/moravian_walls/eastern_wall_crossing",
                 description:
                   "A broad, stone staircase descends into darkness, providing access to the Eastern Wall Crossing."
               },
               %Zung.Game.Room.Exit{
                 direction: :south,
                 to: "kralovice_mor/dokonalulice/north_gate_entrance",
                 description:
                   "The North Gate Entrance is situated on the opposite side of the gate."
               }
             ]
           },
           "kralovice_mor/moravian_walls/south_wall_gatehouse" => %Zung.Game.Room{
             id: "kralovice_mor/moravian_walls/south_wall_gatehouse",
             title: "South Wall Gatehouse",
             description:
               "Grey stone walls loom above, casting long shadows in the fading light.||NL||The air is thick with dust and grime.||NL||A large wooden gate dominates one wall, its iron hinges creaking ominously.",
             exits: [
               %Zung.Game.Room.Exit{
                 direction: :south,
                 to: "kralovice_mor/moravian_walls/west_wall_crossing",
                 description:
                   "A large wooden gate stretches across the wall, its iron hinges creaking ominously."
               },
               %Zung.Game.Room.Exit{
                 direction: :west,
                 to: "kralovice_mor/moravian_walls/watchtower_viewpoint",
                 description:
                   "A narrow staircase spirals upwards into darkness, vanishing from view at the top."
               }
             ]
           },
           "kralovice_mor/vysoka_ulice/strojarne" => %Zung.Game.Room{
             id: "kralovice_mor/vysoka_ulice/strojarne",
             title: "Smithy",
             description:
               "The cramped workshop is filled with hissing pipes and clanging hammers, casting a cacophonous glow over the space.",
             exits: [
               %Zung.Game.Room.Exit{
                 direction: :west,
                 to: "kralovice_mor/vysoka_ulice/ulice_jizba",
                 description:
                   "To the west lies the City Jail, a foreboding structure shrouded in darkness and despair."
               },
               %Zung.Game.Room.Exit{
                 direction: :north,
                 to: "kralovice_mor/vysoka_ulice/pazar_stanec",
                 description:
                   "Beyond the north wall lies the bustling Market Stand, filled with the vibrant sounds and smells of commerce."
               }
             ]
           },
           "kralovice_mor/vysoka_ulice/tradi_cafe" => %Zung.Game.Room{
             id: "kralovice_mor/vysoka_ulice/tradi_cafe",
             title: "Traditional Cafe",
             description:
               "Worn, creaking tables and chairs surround a central fireplace in this humble eatery.",
             exits: [
               %Zung.Game.Room.Exit{
                 direction: :south,
                 to: "kralovice_mor/vysoka_ulice/ulice_jizba",
                 description:
                   "A narrow corridor leads to the City Jail, its heavy doors adorned with iron hinges and rusted locks."
               },
               %Zung.Game.Room.Exit{
                 direction: :north,
                 to: "kralovice_mor/vysoka_ulice/kropec_kavka",
                 description:
                   "The entrance to a cramped Pawn Shop beckons, its sign creaking in the faint breeze."
               },
               %Zung.Game.Room.Exit{
                 direction: :east,
                 to: "kralovice_mor/vysoka_ulice/pazar_stanec",
                 description:
                   "A bustling Market Stand waits beyond, filled with the vibrant colors of exotic wares."
               }
             ],
             objects: [
               %Zung.Game.Object{
                 id: "rotten_bread",
                 name: "rotten bread",
                 description: "Rotten bread lies here.",
                 keywords: ["rotten bread", "bread"]
               },
               %Zung.Game.Object{
                 id: "burnt_coffee_beans",
                 name: "burnt coffee beans",
                 description: "Burnt coffee beans lies here.",
                 keywords: ["burnt coffee beans", "beans", "coffee beans"]
               }
             ]
           },
           "kralovice_mor/vysoka_ulice/ulice_celar" => %Zung.Game.Room{
             id: "kralovice_mor/vysoka_ulice/ulice_celar",
             title: "Cellars",
             description:
               "Dark, damp tunnels filled with stacked crates and barrels, dimly lit by flickering torches.",
             exits: [
               %Zung.Game.Room.Exit{
                 direction: :south,
                 to: "kralovice_mor/vysoka_ulice/pazar_stanec",
                 description:
                   "A narrow stairway leads up to the bustling Market Stand, where merchants hawk their wares."
               },
               %Zung.Game.Room.Exit{
                 direction: :west,
                 to: "kralovice_mor/vysoka_ulice/kropec_kavka",
                 description:
                   "A worn wooden door creaks in the breeze, leading to the Pawn Shop's dim interior."
               }
             ],
             objects: [
               %Zung.Game.Object{
                 id: "stacked_crates_dusty_barrels_flickering_torches",
                 name: "Stacked crates, dusty barrels, flickering torches",
                 description: "Stacked crates, dusty barrels, flickering torches lies here.",
                 keywords: [
                   "Stacked crates, dusty barrels, flickering torches",
                   "torches",
                   "flickering torches"
                 ]
               }
             ]
           },
           "kralovice_mor/vysoka_ulice/ulice_jizba" => %Zung.Game.Room{
             id: "kralovice_mor/vysoka_ulice/ulice_jizba",
             title: "City Jail",
             description:
               "Cold, damp stone walls and a low ceiling confine you to this small holding cell, with iron bars separating you from the darkness beyond.",
             exits: [
               %Zung.Game.Room.Exit{
                 direction: :east,
                 to: "kralovice_mor/vysoka_ulice/strojarne",
                 description:
                   "A narrow doorway leads into a dimly lit smithy, where the sound of hammering on hot metal fills the air."
               },
               %Zung.Game.Room.Exit{
                 direction: :north,
                 to: "kralovice_mor/moravian_walls/wall_entry_point",
                 description:
                   "A heavy wooden door with iron hinges creaks open to reveal a dark and foreboding wall entrance."
               }
             ]
           },
           "kralovice_mor/skalni_kraj/vchod_do_docku" => %Zung.Game.Room{
             id: "kralovice_mor/skalni_kraj/vchod_do_docku",
             title: "Gateway to Docks and Shipyards",
             description:
               "A weathered wooden bridge spans a small chasm, connecting The Quarry to the bustling Docks and Shipyards district below.",
             exits: [
               %Zung.Game.Room.Exit{
                 direction: :south,
                 to: "kralovice_mor/skalni_kraj/vysoke_cesta",
                 description:
                   "A set of steep stairs leads down to the Upper Quarry Level, a labyrinthine network of tunnels and caverns."
               },
               %Zung.Game.Room.Exit{
                 direction: :west,
                 to: "kralovice_mor/skalni_kraj/smyczny_tunnel",
                 description:
                   "The bridge creaks ominously as it spans the chasm, leading west into the darkness of the Broken Tunnel to the Old Mine."
               }
             ]
           },
           "kralovice_mor/skalni_kraj/vysoke_cesta" => %Zung.Game.Room{
             id: "kralovice_mor/skalni_kraj/vysoke_cesta",
             title: "Upper Quarry Level",
             description:
               "A steeper, rockier area with fewer structures, offering better views of the surrounding landscape.",
             exits: [
               %Zung.Game.Room.Exit{
                 direction: :west,
                 to: "kralovice_mor/skalni_kraj/dolu_pristup",
                 description:
                   "A narrow tunnel leads down to the Lower Quarry Level, a maze of dark passages and dusty tunnels."
               },
               %Zung.Game.Room.Exit{
                 direction: :north,
                 to: "kralovice_mor/skalni_kraj/vchod_do_docku",
                 description:
                   "A rickety wooden bridge spans a deep chasm, leading to the Gateway to Docks and Shipyards."
               }
             ],
             objects: [
               %Zung.Game.Object{
                 id: "rusty_old_lantern_hanging_from_the_wall_its_wick_dry_and_cracked",
                 name: "a rusty old lantern hanging from the wall, its wick dry and cracked",
                 description:
                   "Rusty old lantern hanging from the wall, its wick dry and cracked lies here.",
                 keywords: [
                   "rusty old lantern hanging from the wall, its wick dry and cracked",
                   "cracked",
                   "and cracked"
                 ]
               },
               %Zung.Game.Object{
                 id: "scattered_rocks_and_pebbles_littering_the_ground",
                 name: "scattered rocks and pebbles littering the ground",
                 description: "Scattered rocks and pebbles littering the ground lies here.",
                 keywords: [
                   "scattered rocks and pebbles littering the ground",
                   "ground",
                   "the ground"
                 ]
               }
             ]
           },
           "kralovice_mor/pohorenie_klasy/vytoky_na_doke" => %Zung.Game.Room{
             id: "kralovice_mor/pohorenie_klasy/vytoky_na_doke",
             title: "Vykody na Doke",
             description:
               "A bustling area filled with carters and sailors unloading and loading goods from ships, crates stacked haphazardly on wooden pallets and barrels overflowing with tar and oil.||NL||The air is thick with the smell of saltwater and smoke.",
             exits: [
               %Zung.Game.Room.Exit{
                 direction: :south,
                 to: "kralovice_mor/pohorenie_klasy/krajina_tovarne",
                 description:
                   "A narrow alleyway leads down into the depths of the docks, lined with crates and boxes stacked haphazardly on either side."
               },
               %Zung.Game.Room.Exit{
                 direction: :west,
                 to: "kralovice_mor/pohorenie_klasy/radnice_stavby",
                 description:
                   "The sound of hammering grows fainter as you make your way towards the town hall, where the mayor's office is said to be located."
               },
               %Zung.Game.Room.Exit{
                 direction: :north,
                 to: "kralovice_mor/pohorenie_klasy/kapitanova_kamera",
                 description:
                   "A large wooden door leads up into the captain's quarters, a cozy cabin that seems out of place in this chaotic environment."
               }
             ],
             objects: [
               %Zung.Game.Object{
                 id:
                   "worn_leather_satchel_leans_against_the_wall_a_half_empty_flask_of_grog_sitting_atop_it",
                 name:
                   "A worn leather satchel leans against the wall, a half-empty flask of grog sitting atop it.",
                 description:
                   "Worn leather satchel leans against the wall, a half-empty flask of grog sitting atop it. lies here.",
                 keywords: [
                   "worn leather satchel leans against the wall, a half-empty flask of grog sitting atop it.",
                   "it.",
                   "atop it."
                 ]
               }
             ]
           },
           "kralovice_mor/moravian_walls/wall_entry_point" => %Zung.Game.Room{
             id: "kralovice_mor/moravian_walls/wall_entry_point",
             title: "Wall Entrance",
             description:
               "Grey stone walls tower above, casting long shadows in the fading light.||NL||The air is thick with the scent of damp earth and decay.",
             exits: [
               %Zung.Game.Room.Exit{
                 direction: :north,
                 to: "kralovice_mor/moravian_walls/wall_top_walkway",
                 description:
                   "A narrow staircase leads up to the Wall Top Walkway, accessible only to those with the proper clearance."
               },
               %Zung.Game.Room.Exit{
                 direction: :east,
                 to: "kralovice_mor/moravian_walls/south_gate_entrance",
                 description:
                   "A large wooden gate bars entrance to the South Gate Entrance, guarded by two imposing stone statues."
               },
               %Zung.Game.Room.Exit{
                 direction: :south,
                 to: "kralovice_mor/vysoka_ulice/ulice_jizba",
                 description:
                   "A heavy iron door seals off access to the City Jail, adorned with ominous warning signs."
               }
             ],
             objects: [
               %Zung.Game.Object{
                 id: "large_wooden_gate_key",
                 name: "A large wooden gate key",
                 description: "Large wooden gate key lies here.",
                 keywords: ["large wooden gate key", "key", "gate key"]
               }
             ]
           },
           "kralovice_mor/moravian_walls/wall_top_walkway" => %Zung.Game.Room{
             id: "kralovice_mor/moravian_walls/wall_top_walkway",
             title: "Wall Top Walkway",
             description:
               "A narrow, windswept walkway atop the grey stone walls of The Wards, lined with worn wooden railings and offering a bleak view over the city's twisted streets.",
             exits: [
               %Zung.Game.Room.Exit{
                 direction: :south,
                 to: "kralovice_mor/moravian_walls/wall_entry_point",
                 description:
                   "A heavy wooden door, adorned with iron hinges and a large iron knocker in the shape of a snarling lion's head."
               },
               %Zung.Game.Room.Exit{
                 direction: :north,
                 to: "kralovice_mor/moravian_walls/watchtower_viewpoint",
                 description:
                   "A narrow staircase leading up to a small watchtower, its windows barred and its presence seeming to draw the very light out of the air."
               },
               %Zung.Game.Room.Exit{
                 direction: :east,
                 to: "kralovice_mor/moravian_walls/west_wall_crossing",
                 description: "A rusty iron gate, partially hidden by overgrown bushes and vines."
               }
             ],
             objects: [
               %Zung.Game.Object{
                 id: "tattered_flag_bearing_the_emblem_of_the_city_guard",
                 name: "A tattered flag bearing the emblem of the city guard",
                 description: "Tattered flag bearing the emblem of the city guard lies here.",
                 keywords: [
                   "tattered flag bearing the emblem of the city guard",
                   "guard",
                   "city guard"
                 ]
               }
             ]
           },
           "kralovice_mor/moravian_walls/watchtower_viewpoint" => %Zung.Game.Room{
             id: "kralovice_mor/moravian_walls/watchtower_viewpoint",
             title: "Watchtower Viewpoint",
             description:
               "A raised platform with a view of the surrounding area, used by guards for surveillance and spotting potential threats.",
             exits: [
               %Zung.Game.Room.Exit{
                 direction: :south,
                 to: "kralovice_mor/moravian_walls/wall_top_walkway",
                 description:
                   "A narrow walkway along the wall's edge, with steep drop-offs on either side."
               },
               %Zung.Game.Room.Exit{
                 direction: :east,
                 to: "kralovice_mor/moravian_walls/south_wall_gatehouse",
                 description:
                   "A sturdy gatehouse door adorned with iron hinges and a heavy-looking iron knocker in the shape of a snarling lion's head."
               }
             ],
             objects: [
               %Zung.Game.Object{
                 id: "lantern_with_a_single_guttering_candle_a_battered_wooden_stool",
                 name: "A lantern with a single, guttering candle, a battered wooden stool",
                 description:
                   "Lantern with a single, guttering candle, a battered wooden stool lies here.",
                 keywords: [
                   "lantern with a single, guttering candle, a battered wooden stool",
                   "stool",
                   "wooden stool"
                 ]
               }
             ]
           },
           "kralovice_mor/dokonalulice/west_garden_path" => %Zung.Game.Room{
             id: "kralovice_mor/dokonalulice/west_garden_path",
             title: "West Garden Path",
             description:
               "A winding, overgrown path through a once-grand garden, now choked with weeds and vines that scrape against crumbling stone statues.||NL||Faded floral patterns still adorn the walls, but they seem more like a distant memory than a vibrant reality.",
             exits: [
               %Zung.Game.Room.Exit{
                 direction: :south,
                 to: "kralovice_mor/dokonalulice/north_gate_entrance",
                 description:
                   "A grand stone archway looms ahead, covered in ivy and dust, with the North Gate Entrance guarded by two imposing stone statues."
               },
               %Zung.Game.Room.Exit{
                 direction: :north,
                 to: "kralovice_mor/dokonalulice/south_balcony_view",
                 description:
                   "The overgrown path gives way to a balcony overlooking the town below, where the sounds of Upper Town's daily struggles and triumphs rise up on the wind."
               },
               %Zung.Game.Room.Exit{
                 direction: :east,
                 to: "kralovice_mor/dokonalulice/east_town_hall",
                 description:
                   "A grand entrance to the East Town Hall beckons, its ornate doors adorned with carvings of forgotten gods and nobility."
               }
             ],
             objects: [
               %Zung.Game.Object{
                 id:
                   "rusty_gardening_tool_lies_abandoned_on_the_path_its_handle_worn_smooth_by_time",
                 name:
                   "A rusty gardening tool lies abandoned on the path, its handle worn smooth by time.",
                 description:
                   "Rusty gardening tool lies abandoned on the path, its handle worn smooth by time. lies here.",
                 keywords: [
                   "rusty gardening tool lies abandoned on the path, its handle worn smooth by time.",
                   "time.",
                   "by time."
                 ]
               }
             ]
           },
           "kralovice_mor/moravian_walls/west_wall_crossing" => %Zung.Game.Room{
             id: "kralovice_mor/moravian_walls/west_wall_crossing",
             title: "West Wall Crossing",
             description:
               "A narrow, dimly lit tunnel with grey stone walls, the air thick with dust and the stench of rotting wood.",
             exits: [
               %Zung.Game.Room.Exit{
                 direction: :south,
                 to: "kralovice_mor/moravian_walls/south_gate_entrance",
                 description:
                   "A worn stone step leads down to the South Gate Entrance, where guards patrol the entrance to the Wards."
               },
               %Zung.Game.Room.Exit{
                 direction: :west,
                 to: "kralovice_mor/moravian_walls/wall_top_walkway",
                 description:
                   "A narrow ledge along the wall offers a precarious view of the Wall Top Walkway above."
               },
               %Zung.Game.Room.Exit{
                 direction: :north,
                 to: "kralovice_mor/moravian_walls/south_wall_gatehouse",
                 description:
                   "The heavy wooden door of the South Wall Gatehouse looms ahead, adorned with iron hinges and a large, rusty knocker."
               },
               %Zung.Game.Room.Exit{
                 direction: :east,
                 to: "kralovice_mor/moravian_walls/inner_gate_entrance",
                 description:
                   "A short corridor leads into the Inner Gate Entrance, where courtiers and dignitaries are often seen entering the Wards."
               }
             ],
             objects: [
               %Zung.Game.Object{
                 id: "rusty_iron_hinges",
                 name: "Rusty iron hinges",
                 description: "Rusty iron hinges lies here.",
                 keywords: ["Rusty iron hinges", "hinges", "iron hinges"]
               },
               %Zung.Game.Object{
                 id: "old_wooden_beam",
                 name: "Old wooden beam",
                 description: "Old wooden beam lies here.",
                 keywords: ["Old wooden beam", "beam", "wooden beam"]
               }
             ]
           },
           "kralovice_mor/skalni_kraj/zahnicky_budynek" => %Zung.Game.Room{
             id: "kralovice_mor/skalni_kraj/zahnicky_budynek",
             title: "Old Mine's Office Building",
             description:
               "A cramped, dimly lit room with peeling plaster walls and a low ceiling, filled with dusty records, forgotten tools, and ancient mining equipment.",
             exits: [
               %Zung.Game.Room.Exit{
                 direction: :south,
                 to: "kralovice_mor/skalni_kraj/krovna_vysledek",
                 description:
                   "A narrow doorway leads to the bustling Quarry's Central Gathering Area."
               }
             ],
             objects: [
               %Zung.Game.Object{
                 id: "abandoned_ledger_rusty_pen_dusty_mining_maps",
                 name: "abandoned ledger, rusty pen, dusty mining maps",
                 description: "Abandoned ledger, rusty pen, dusty mining maps lies here.",
                 keywords: [
                   "abandoned ledger, rusty pen, dusty mining maps",
                   "maps",
                   "mining maps"
                 ]
               }
             ]
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
