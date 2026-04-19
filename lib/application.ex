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
             exits: [%Zung.Game.Room.Exit{direction: :down, to: "newbie/room_2"},
               %Zung.Game.Room.Exit{direction: :east, to: "kraakenhavn/dockside_quay/abandoned_ships_wharf"}]
           },
          # region: kraakenhavn
  "kraakenhavn/dockside_quay/abandoned_ships_wharf" => %Zung.Game.Room{
    id: "kraakenhavn/dockside_quay/abandoned_ships_wharf",
    title: "Abandoned Ships Wharf",
    description: "Weathered wooden docks creak beneath heavy loads, old hulls and abandoned cargo lie scattered about.",
    exits: [
      %Zung.Game.Room.Exit{direction: :up, to: "newbie/room_3", description: "A narrow gang-plank to board the SS Rockwell"},
      %Zung.Game.Room.Exit{direction: :north, to: "kraakenhavn/dockside_quay/midnight_market", description: "A narrow alleyway leads north"},
      %Zung.Game.Room.Exit{direction: :south, to: "kraakenhavn/dockside_quay/smuggler_s_alley", description: "The dock stretches out to the south"},
      %Zung.Game.Room.Exit{direction: :east, to: "kraakenhavn/dockside_quay/docks_master_office", description: "A large office building looms east"},
      %Zung.Game.Room.Exit{direction: :west, to: "kraakenhavn/dockside_quay/lighthouse_keeper_quarters", description: "The setting sun casts a golden glow on the western horizon"},
    ],
  },
  "kraakenhavn/the_spire/balcony_over_the_ruin" => %Zung.Game.Room{
    id: "kraakenhavn/the_spire/balcony_over_the_ruin",
    title: "The Balcony of the Ancients",
    description: "Crumbing stone walls, overgrown with vines and moss.||NL||Flickering torches cast eerie shadows on the ground below.",
    exits: [
      %Zung.Game.Room.Exit{direction: :north, to: "kraakenhavn/the_spire/entrance_to_the_spire", description: "A narrow corridor stretches into the darkness of the spire."},
      %Zung.Game.Room.Exit{direction: :east, to: "kraakenhavn/the_spire/corridors_of_the_ruin", description: "The ruin's ancient passageways seem to stretch on forever in this direction."},
      %Zung.Game.Room.Exit{direction: :west, to: "kraakenhavn/the_spire/library_of_forbidden_knowledge", description: "A door leads into a dimly lit chamber filled with forbidden texts."},
      %Zung.Game.Room.Exit{direction: :down, to: "kraakenhavn/the_spire/treasury_of_relics", description: "The air grows thick with the scent of gold and treasure as you descend deeper."},
    ],
  },
  "kraakenhavn/dockside_quay/cargo_crane_pit" => %Zung.Game.Room{
    id: "kraakenhavn/dockside_quay/cargo_crane_pit",
    title: "Cargo Crane Pit",
    description: "A large, dimly lit area with wooden crates and nets scattered about.",
    exits: [
      %Zung.Game.Room.Exit{direction: :south, to: "kraakenhavn/dockside_quay", description: "A narrow passageway leads south"},
      %Zung.Game.Room.Exit{direction: :north, to: "kraakenhavn/dockside_quay/abandoned_ships_wharf", description: "A rickety crane stretches northward"},
    ],
  },
  "kraakenhavn/the_spire/corridors_of_the_ruin" => %Zung.Game.Room{
    id: "kraakenhavn/the_spire/corridors_of_the_ruin",
    title: "Corridors of the Ancients",
    description: "Dusty shelves line the narrow passageways, containing ancient texts and artifacts that seem to hold forgotten knowledge.",
    exits: [
      %Zung.Game.Room.Exit{direction: :north, to: "kraakenhavn/the_spire/library_of_forbidden_knowledge", description: "The narrow corridor leads deeper into the Spire, towards forbidden knowledge."},
      %Zung.Game.Room.Exit{direction: :south, to: "kraakenhavn/the_spire/treasury_of_relics", description: "A section of wall slides open, revealing a chamber filled with ancient treasures."},
      %Zung.Game.Room.Exit{direction: :east, to: "kraakenhavn/the_spire/entrance_to_the_spire", description: "The corridor continues eastward, leading back to the Spire's entrance."},
    ],
    objects: [
      %Zung.Game.Object{
        id: "dusty_tome_with_yellowed_pages",
        name: "A dusty tome with yellowed pages",
        description: "Dusty tome with yellowed pages lies here.",
        keywords: ["dusty tome with yellowed pages", "pages", "yellowed pages"]
      },
      %Zung.Game.Object{
        id: "ancient_artifact_adorned_with_mysterious_runes",
        name: "An ancient artifact adorned with mysterious runes",
        description: "Ancient artifact adorned with mysterious runes lies here.",
        keywords: ["ancient artifact adorned with mysterious runes", "runes", "mysterious runes"]
      },
    ],
  },
  "kraakenhavn/dockside_quay/docks_master_office" => %Zung.Game.Room{
    id: "kraakenhavn/dockside_quay/docks_master_office",
    title: "Docks Master Office",
    description: "A cramped, dimly lit office with dusty files and papers scattered on a worn wooden desk.||NL||Shelves line the walls, filled with old nautical charts and faded maps.||NL||A single, flickering candle casts eerie shadows.",
    exits: [
      %Zung.Game.Room.Exit{direction: :north, to: "kraakenhavn/dockside_quay/abandoned_ships_wharf", description: "A narrow corridor stretches north, into darkness."},
      %Zung.Game.Room.Exit{direction: :south, to: "kraakenhavn/dockside_quay/midnight_market", description: "The bustling market of the Docks continues south, a cacophony of sound and color."},
    ],
    objects: [
      %Zung.Game.Object{
        id: "docks_master_s_journal",
        name: "Docks Master's Journal",
        description: "Docks Master's Journal lies here.",
        keywords: ["Docks Master's Journal", "Journal", "Master's Journal"]
      },
      %Zung.Game.Object{
        id: "old_nautical_chart",
        name: "Old Nautical Chart",
        description: "Old Nautical Chart lies here.",
        keywords: ["Old Nautical Chart", "Chart", "Nautical Chart"]
      },
    ],
  },
  "kraakenhavn/the_red_harbor/duke_mansion" => %Zung.Game.Room{
    id: "kraakenhavn/the_red_harbor/duke_mansion",
    title: "Duke Masters' Mansion",
    description: "A grandiose mansion with lavish decor, surrounded by heavily armed guards and a high wall.||NL||The interior is opulent, with expensive tapestries and polished marble floors.",
    exits: [
      %Zung.Game.Room.Exit{direction: :north, to: "kraakenhavn/the_red_harbor/the_drowned_tavern", description: "A narrow doorway leads to a dimly lit hallway."},
      %Zung.Game.Room.Exit{direction: :east, to: "kraakenhavn/the_red_harbor/red_viper_hive", description: "A heavily guarded corridor stretches out into the darkness."},
      %Zung.Game.Room.Exit{direction: :south, to: "kraakenhavn/the_red_harbor/luna_s_apartment", description: "A grand staircase curves upward, disappearing into the shadows."},
      %Zung.Game.Room.Exit{direction: :west, to: "kraakenhavn/the_red_harbor/stealthing_alley", description: "A narrow alleyway cuts through the mansion's exterior wall."},
    ],
  },
  "kraakenhavn/the_spire/entrance_to_the_spire" => %Zung.Game.Room{
    id: "kraakenhavn/the_spire/entrance_to_the_spire",
    title: "Entrance Chamber",
    description: "Flickering torches cast eerie shadows on crumbling stone walls.||NL||Ancient runes adorn the entrance door.",
    exits: [
      %Zung.Game.Room.Exit{direction: :north, to: "kraakenhavn/the_spire/corridors_of_the_ruin", description: "A narrow corridor stretches into darkness."},
      %Zung.Game.Room.Exit{direction: :east, to: "kraakenhavn/the_spire/library_of_forbidden_knowledge", description: "Shelves of ancient tomes seem to lean in, as if listening."},
      %Zung.Game.Room.Exit{direction: :south, to: "kraakenhavn/the_spire/treasury_of_relics", description: "A vaulted ceiling disappears into shadowy darkness."},
      %Zung.Game.Room.Exit{direction: :west, to: "kraakenhavn/the_spire/balcony_over_the_ruin", description: "The wind whispers secrets from above."},
    ],
    objects: [
      %Zung.Game.Object{
        id: "entrance_door",
        name: "the entrance door",
        description: "Entrance door lies here.",
        keywords: ["entrance door", "door"]
      },
    ],
  },
  "kraakenhavn/lighthouse_district/garden_of_memories" => %Zung.Game.Room{
    id: "kraakenhavn/lighthouse_district/garden_of_memories",
    title: "Garden of Memories",
    description: "A serene, winding garden filled with a variety of flowers, trees, and statues.||NL||Soft golden light filters through stained glass windows, casting a warm glow over the garden.",
    exits: [
      %Zung.Game.Room.Exit{direction: :north, to: "kraakenhavn/lighthouse_district/lighthouse_warden_house", description: "A narrow path leads north to the warden's residence."},
      %Zung.Game.Room.Exit{direction: :south, to: "kraakenhavn/merchants_guild_office", description: "The garden stretches south towards the bustling merchants' guild office."},
      %Zung.Game.Room.Exit{direction: :east, to: "kraakenhavn/lighthouse_district/lighthouse_lantern_room", description: "A winding path leads east, disappearing into the lantern room's warm light."},
      %Zung.Game.Room.Exit{direction: :west, to: "kraakenhavn/heirloom_bakery", description: "The garden curves west towards the sweet scent of freshly baked heirlooms."},
    ],
    objects: [
      %Zung.Game.Object{
        id: "small_weathered_stone_bench",
        name: "a small, weathered stone bench",
        description: "Small, weathered stone bench lies here.",
        keywords: ["small, weathered stone bench", "bench", "stone bench"]
      },
      %Zung.Game.Object{
        id: "vase_with_a_single_long_stemmed_red_rose",
        name: "a vase with a single, long-stemmed red rose",
        description: "Vase with a single, long-stemmed red rose lies here.",
        keywords: ["vase with a single, long-stemmed red rose", "rose", "red rose"]
      },
    ],
  },
  "kraakenhavn/the_spire/keeper_quarters" => %Zung.Game.Room{
    id: "kraakenhavn/the_spire/keeper_quarters",
    title: "Erebus' Quarters",
    description: "Flickering torches cast eerie shadows on crumbling stone walls.||NL||Ancient texts line the shelves, their yellowed pages whispering forgotten knowledge.",
    exits: [
      %Zung.Game.Room.Exit{direction: :north, to: "kraakenhavn/the_spire/entrance_to_the_spire", description: "A narrow corridor stretches into darkness."},
      %Zung.Game.Room.Exit{direction: :east, to: "kraakenhavn/the_spire/corridors_of_the_ruin", description: "The walls seem to press in on either side, casting long shadows."},
    ],
    objects: [
      %Zung.Game.Object{
        id: "ancient_tome",
        name: " ancient tome",
        description: " ancient tome lies here.",
        keywords: [" ancient tome", "tome", "ancient tome"]
      },
      %Zung.Game.Object{
        id: "candle",
        name: "candle",
        description: "Candle lies here.",
        keywords: ["candle"]
      },
      %Zung.Game.Object{
        id: "small_desk",
        name: "small desk",
        description: "Small desk lies here.",
        keywords: ["small desk", "desk"]
      },
    ],
  },
  "kraakenhavn/the_spire/library_of_forbidden_knowledge" => %Zung.Game.Room{
    id: "kraakenhavn/the_spire/library_of_forbidden_knowledge",
    title: "The Labyrinthine Library",
    description: "Shelves upon shelves of ancient tomes stretch into the darkness, their leather bindings cracked and worn.||NL||Tomes bound in human skin seem to writhe on their shelves like living things.",
    exits: [
      %Zung.Game.Room.Exit{direction: :south, to: "kraakenhavn/the_spire/entrance_to_the_spire", description: "A narrow corridor leads back into the darkness of the spire."},
      %Zung.Game.Room.Exit{direction: :east, to: "kraakenhavn/the_spire/corridors_of_the_ruin", description: "Corridors of ancient stone stretch out into the ruin, lined with cobweb-shrouded alcoves."},
    ],
    objects: [
      %Zung.Game.Object{
        id: "tome_bound_in_human_skin",
        name: "A tome bound in human skin",
        description: "Tome bound in human skin lies here.",
        keywords: ["tome bound in human skin", "skin", "human skin"]
      },
      %Zung.Game.Object{
        id: "ancient_artifact_emitting_a_faint_hum",
        name: "An ancient artifact emitting a faint hum",
        description: "Ancient artifact emitting a faint hum lies here.",
        keywords: ["ancient artifact emitting a faint hum", "hum", "faint hum"]
      },
    ],
  },
  "kraakenhavn/dockside_quay/lighthouse_keeper_quarters" => %Zung.Game.Room{
    id: "kraakenhavn/dockside_quay/lighthouse_keeper_quarters",
    title: "Lighthouse Keeper's Quarters",
    description: "A simple, yet well-maintained room with a single window offering a view of the city's waterways.||NL||The walls are adorned with dusty nautical maps and faded photographs.",
    exits: [
      %Zung.Game.Room.Exit{direction: :south, to: "kraakenhavn/dockside_quay", description: "A long, narrow corridor stretches out into the darkness"},
      %Zung.Game.Room.Exit{direction: :east, to: "kraakenhavn/dockside_quay/abandoned_ships_wharf", description: "The creaking of old wooden planks echoes through the air"},
    ],
    objects: [
      %Zung.Game.Object{
        id: "lantern",
        name: "a lantern",
        description: "Lantern lies here.",
        keywords: ["lantern"]
      },
      %Zung.Game.Object{
        id: "old_logbook",
        name: "an old logbook",
        description: "Old logbook lies here.",
        keywords: ["old logbook", "logbook"]
      },
    ],
  },
  "kraakenhavn/lighthouse_district/lighthouse_lantern_room" => %Zung.Game.Room{
    id: "kraakenhavn/lighthouse_district/lighthouse_lantern_room",
    title: "Lantern Room",
    description: "Shelves lined with antique lanterns, each one unique and meticulously maintained.||NL||Soft golden light filters through stained glass windows above, casting a warm glow over the room.",
    exits: [
      %Zung.Game.Room.Exit{direction: :north, to: "kraakenhavn/lighthouse_district/lighthouse_warden_house", description: "A narrow corridor leads north, into the warden's private quarters."},
      %Zung.Game.Room.Exit{direction: :east, to: "kraakenhavn/merchant_guild_office", description: "Merchants and traders often pass through this way on their visits to the lighthouse."},
      %Zung.Game.Room.Exit{direction: :south, to: "kraakenhavn/heirloom_bakery", description: "The bakery's sweet aroma wafts up from below, enticing visitors with treats."},
    ],
    objects: [
      %Zung.Game.Object{
        id: "antique_lanterns",
        name: "Antique lanterns",
        description: "Antique lanterns lies here.",
        keywords: ["Antique lanterns", "lanterns"]
      },
      %Zung.Game.Object{
        id: "stained_glass_windows",
        name: "Stained glass windows",
        description: "Stained glass windows lies here.",
        keywords: ["Stained glass windows", "windows", "glass windows"]
      },
    ],
  },
  "kraakenhavn/lighthouse_district/lighthouse_library" => %Zung.Game.Room{
    id: "kraakenhavn/lighthouse_district/lighthouse_library",
    title: "Lighthouse Library",
    description: "Shelves line the walls, packed with ancient tomes and yellowed charts.||NL||Flickering candles cast a warm glow over the room.",
    exits: [
      %Zung.Game.Room.Exit{direction: :north, to: "kraakenhavn/lighthouse_district/lighthouse_warden_house", description: "A narrow staircase leads up to the warden's private quarters"},
      %Zung.Game.Room.Exit{direction: :east, to: "kraakenhavn/merchants_guild_office", description: "A doorway opens into a bustling marketplace"},
      %Zung.Game.Room.Exit{direction: :south, to: "kraakenhavn/lighthouse_district/lighthouse_lantern_room", description: "The lantern room lies below, its light a beacon in the darkness"},
    ],
    objects: [
      %Zung.Game.Object{
        id: "ancient_tome",
        name: "ancient_tome",
        description: "Ancient_tome lies here.",
        keywords: ["ancient_tome"]
      },
      %Zung.Game.Object{
        id: "nautical_chart",
        name: "nautical_chart",
        description: "Nautical_chart lies here.",
        keywords: ["nautical_chart"]
      },
    ],
  },
  "kraakenhavn/lighthouse_district/lighthouse_warden_house" => %Zung.Game.Room{
    id: "kraakenhavn/lighthouse_district/lighthouse_warden_house",
    title: "Warden's Residence",
    description: "A well-appointed home with a large garden and a view of the harbor, with soft golden light filtering through stained glass windows.",
    exits: [
      %Zung.Game.Room.Exit{direction: :north, to: "kraakenhavn/merchants_guild_office", description: "A narrow corridor leads north to the Merchants' Guild Office."},
      %Zung.Game.Room.Exit{direction: :east, to: "kraakenhavn/lighthouse_district/lighthouse_lantern_room", description: "An open door lets in a warm breeze from the Lighthouse Lantern Room."},
      %Zung.Game.Room.Exit{direction: :south, to: "kraakenhavn/heirloom_bakery", description: "A short hallway leads south to the Heirloom Bakery."},
      %Zung.Game.Room.Exit{direction: :west, to: "kraakenhavn/lighthouse_district/lighthouse_library", description: "A winding staircase descends west to the Lighthouse Library."},
    ],
  },
  "kraakenhavn/the_red_harbor/luna_s_apartment" => %Zung.Game.Room{
    id: "kraakenhavn/the_red_harbor/luna_s_apartment",
    title: "Luna's Apartment",
    description: "A cramped but cozy one-bedroom apartment, the walls adorned with tattered black lace and faded roses.||NL||A single, flickering candle casts eerie shadows on the walls.",
    exits: [
      %Zung.Game.Room.Exit{direction: :north, to: "kraakenhavn/the_red_harbor/the_drowned_tavern", description: "A narrow stairway leads down into the darkness"},
      %Zung.Game.Room.Exit{direction: :south, to: "kraakenhavn/the_red_harbor/red_viper_hive", description: "The stairs lead back up to the tavern's main floor"},
      %Zung.Game.Room.Exit{direction: :east, to: "kraakenhavn/the_red_harbor/duke_mansion", description: "A small, grimy window opens onto a sprawling estate"},
      %Zung.Game.Room.Exit{direction: :west, to: "kraakenhavn/the_red_harbor/stealthing_alley", description: "A narrow alleyway stretches out into the darkness"},
    ],
    objects: [
      %Zung.Game.Object{
        id: "rose_tipped_dagger",
        name: "a rose-tipped dagger",
        description: "Rose-tipped dagger lies here.",
        keywords: ["rose-tipped dagger", "dagger"]
      },
      %Zung.Game.Object{
        id: "black_lace_veil",
        name: "a black lace veil",
        description: "Black lace veil lies here.",
        keywords: ["black lace veil", "veil", "lace veil"]
      },
    ],
  },
  "kraakenhavn/dockside_quay/midnight_market" => %Zung.Game.Room{
    id: "kraakenhavn/dockside_quay/midnight_market",
    title: "Midnight Market",
    description: "Cramped stalls and vendors selling everything from dubious spices to worn-out gear line the narrow aisles, their wares scattered haphazardly on wooden crates and tables.||NL||Flickering lanterns cast eerie shadows on the walls as the crowd presses in.",
    exits: [
      %Zung.Game.Room.Exit{direction: :south, to: "kraakenhavn/dockside_quay/docks_master_office", description: "A worn set of stairs leads down into darkness"},
      %Zung.Game.Room.Exit{direction: :west, to: "kraakenhavn/dockside_quay/cargo_crane_pit", description: "A narrow corridor stretches off into the gloom"},
      %Zung.Game.Room.Exit{direction: :east, to: "kraakenhavn/dockside_quay/abandoned_ships_wharf", description: "A section of docked ships seems to lean drunkenly against its moorings"},
      %Zung.Game.Room.Exit{direction: :north, to: "kraakenhavn/dockside_quay/smuggler_s_alley", description: "A narrow alleyway appears, lined with tall, grimy buildings"},
    ],
    objects: [
      %Zung.Game.Object{
        id: "worn_leather_satchel",
        name: "a worn leather satchel",
        description: "Worn leather satchel lies here.",
        keywords: ["worn leather satchel", "satchel", "leather satchel"]
      },
      %Zung.Game.Object{
        id: "rusty_lantern",
        name: "a rusty lantern",
        description: "Rusty lantern lies here.",
        keywords: ["rusty lantern", "lantern"]
      },
    ],
  },
  "kraakenhavn/the_spire/observation_deck" => %Zung.Game.Room{
    id: "kraakenhavn/the_spire/observation_deck",
    title: "The Observation Deck",
    description: "Wind-whipped debris clings to crumbling stone walls as flickering torches cast eerie shadows.||NL||Below, the city's turrets and spires stretch into the darkness.",
    exits: [
      %Zung.Game.Room.Exit{direction: :north, to: "kraakenhavn/the_spire/entrance_to_the_spire", description: "A narrow corridor leads back down into the depths of The Spire."},
      %Zung.Game.Room.Exit{direction: :south, to: "kraakenhavn/the_spire/corridors_of_the_ruin", description: "Winding stairs descend into darkness, vanishing from sight."},
      %Zung.Game.Room.Exit{direction: :east, to: "kraakenhavn/the_spire/library_of_forbidden_knowledge", description: "A row of ancient tomes lines one wall, their leather bindings worn and cracked."},
      %Zung.Game.Room.Exit{direction: :west, to: "kraakenhavn/the_spire/treasury_of_relics", description: "Gilded display cases housing relics from a bygone era stand at attention."},
    ],
  },
  "kraakenhavn/the_graveyard/rachel_grimstone_office" => %Zung.Game.Room{
    id: "kraakenhavn/the_graveyard/rachel_grimstone_office",
    title: "Rachel Grimstone's Office",
    description: "A dimly lit room with dusty tomes lining the shelves, where yellowed scrolls are tied with black twine.||NL||A large, ornate desk sits at the far end of the room.",
    exits: [
      %Zung.Game.Room.Exit{direction: :east, to: "kraakenhavn/the_graveyard/the_lonesome_bell", description: "A narrow corridor stretches east, disappearing into darkness."},
      %Zung.Game.Room.Exit{direction: :west, to: "kraakenhavn/the_graveyard/the_overgrown_tomb", description: "A winding path leads west, overgrown with vines and moss."},
    ],
    objects: [
      %Zung.Game.Object{
        id: "rachel_grimstone_s_tattered_journal",
        name: "Rachel Grimstone's tattered journal",
        description: "Rachel Grimstone's tattered journal lies here.",
        keywords: ["Rachel Grimstone's tattered journal", "journal", "tattered journal"]
      },
      %Zung.Game.Object{
        id: "worn_leather_bound_book",
        name: "A worn leather-bound book",
        description: "Worn leather-bound book lies here.",
        keywords: ["worn leather-bound book", "book", "leather-bound book"]
      },
    ],
  },
  "kraakenhavn/the_red_harbor/red_viper_hive" => %Zung.Game.Room{
    id: "kraakenhavn/the_red_harbor/red_viper_hive",
    title: "The Red Vipers' Hideout",
    description: "A dimly lit chamber filled with the stench of rotting seafood and cheap perfume.||NL||Flickering lanterns cast eerie shadows on rusty metal traps and menacing thugs.",
    exits: [
      %Zung.Game.Room.Exit{direction: :north, to: "kraakenhavn/the_red_harbor/the_drowned_tavern", description: "A narrow staircase leads up to the tavern above."},
      %Zung.Game.Room.Exit{direction: :south, to: "kraakenhavn/the_red_harbor/stealthing_alley", description: "The air grows thick with noxious fumes as you head deeper into the dock's underbelly."},
      %Zung.Game.Room.Exit{direction: :east, to: "kraakenhavn/the_red_harbor/luna_s_apartment", description: "A rickety wooden door creaks shut behind you, sealing your fate."},
      %Zung.Game.Room.Exit{direction: :west, to: "kraakenhavn/the_red_harbor_streets", description: "The sound of scurrying rodents and dripping water fills the air as you venture further into the depths."},
      %Zung.Game.Room.Exit{direction: :down, to: "kraakenhavn/the_abandoned_cistern", description: "A seemingly bottomless pit yawns open before you, filled with jagged metal and broken crates."},
    ],
    objects: [
      %Zung.Game.Object{
        id: "rusty_dagger",
        name: "a rusty dagger",
        description: "Rusty dagger lies here.",
        keywords: ["rusty dagger", "dagger"]
      },
      %Zung.Game.Object{
        id: "torn_piece_of_paper",
        name: "a torn piece of paper",
        description: "Torn piece of paper lies here.",
        keywords: ["torn piece of paper", "paper", "of paper"]
      },
    ],
  },
  "kraakenhavn/dockside_quay/smuggler_s_alley" => %Zung.Game.Room{
    id: "kraakenhavn/dockside_quay/smuggler_s_alley",
    title: "Smuggler's Alley",
    description: "Narrow passageway lined with old warehouses, wooden crates stacked haphazardly, and rusty metal beams creaking in the wind.",
    exits: [
      %Zung.Game.Room.Exit{direction: :south, to: "kraakenhavn/dockside_quay", description: "The narrow passageway opens up into a bustling dockside area"},
      %Zung.Game.Room.Exit{direction: :east, to: "kraakenhavn/dockside_quay/cargo_crane_pit", description: "A makeshift staircase leads down to the cargo crane pit below"},
    ],
    objects: [
      %Zung.Game.Object{
        id: "old_lantern",
        name: "old lantern",
        description: "Old lantern lies here.",
        keywords: ["old lantern", "lantern"]
      },
      %Zung.Game.Object{
        id: "rusted_key",
        name: "rusted key",
        description: "Rusted key lies here.",
        keywords: ["rusted key", "key"]
      },
    ],
  },
  "kraakenhavn/the_red_harbor/stealthing_alley" => %Zung.Game.Room{
    id: "kraakenhavn/the_red_harbor/stealthing_alley",
    title: "Stealthing Alley",
    description: "Trash cans and broken crates line the narrow alley, casting long shadows in the flickering lantern light.||NL||The air reeks of rotting seafood and cheap perfume.",
    exits: [
      %Zung.Game.Room.Exit{direction: :north, to: "kraakenhavn/the_red_harbor/the_drowned_tavern", description: "A worn wooden dock stretches out before you, disappearing into darkness."},
      %Zung.Game.Room.Exit{direction: :south, to: "kraakenhavn/the_red_harbor/red_viper_hive", description: "The narrow alley continues on in the opposite direction, vanishing from view."},
    ],
  },
  "kraakenhavn/the_red_harbor/the_drowned_tavern" => %Zung.Game.Room{
    id: "kraakenhavn/the_red_harbor/the_drowned_tavern",
    title: "The Drunken Mermaid Tavern",
    description: "A dimly lit, smoke-filled room with a long bar in the center, adorned with rusty fishing nets and faded sea creature posters.||NL||Flickering lanterns cast eerie shadows on the walls.",
    exits: [
      %Zung.Game.Room.Exit{direction: :north, to: "kraakenhavn/the_red_harbor/red_viper_hive", description: "A narrow corridor leads into darkness"},
      %Zung.Game.Room.Exit{direction: :down, to: "kraakenhavn/the_red_harbor/stealthing_alley", description: "Stairs lead down to a hidden entrance"},
      %Zung.Game.Room.Exit{direction: :east, to: "kraakenhavn/the_red_harbor/duke_mansion", description: "A grand staircase leads up to a wealthy estate"},
    ],
    objects: [
      %Zung.Game.Object{
        id: "mug_of_frothy_ale",
        name: "a mug of frothy ale",
        description: "Mug of frothy ale lies here.",
        keywords: ["mug of frothy ale", "ale", "frothy ale"]
      },
      %Zung.Game.Object{
        id: "wooden_tankard_with_a_cracked_handle",
        name: "a wooden tankard with a cracked handle",
        description: "Wooden tankard with a cracked handle lies here.",
        keywords: ["wooden tankard with a cracked handle", "handle", "cracked handle"]
      },
      %Zung.Game.Object{
        id: "fisherman_s_net_hung_on_the_wall",
        name: "a fisherman's net hung on the wall",
        description: "Fisherman's net hung on the wall lies here.",
        keywords: ["fisherman's net hung on the wall", "wall", "the wall"]
      },
    ],
  },
  "kraakenhavn/the_graveyard/the_graveyard_entrance" => %Zung.Game.Room{
    id: "kraakenhavn/the_graveyard/the_graveyard_entrance",
    title: "The Graveyard Entrance",
    description: "Massive stone angels stand watch, their wings outstretched as they guard the entrance to this foreboding cemetery.||NL||The walls are covered in vines, and moss clings to crumbling headstones.",
    exits: [
      %Zung.Game.Room.Exit{direction: :north, to: "kraakenhavn/the_graveyard/the_overgrown_tomb", description: "A narrow alleyway leads into the darkness of the overgrown tomb."},
      %Zung.Game.Room.Exit{direction: :south, to: "kraakenhavn/the_graveyard/rachel_grimstone_office", description: "The entrance to Rachel Grimstone's office is visible through a wrought-iron gate."},
      %Zung.Game.Room.Exit{direction: :east, to: "kraakenhavn/the_graveyard/the_lonesome_bell", description: "A narrow path winds down into the darkness of The Lonesome Bell."},
      %Zung.Game.Room.Exit{direction: :west, to: "kraakenhavn/the_graveyard/tomb_raider_supply_room", description: "The entrance to the Tomb Raider Supply Room is marked by a large, rusty door."},
    ],
    objects: [
      %Zung.Game.Object{
        id: "old_key",
        name: "old key",
        description: "Old key lies here.",
        keywords: ["old key", "key"]
      },
      %Zung.Game.Object{
        id: "tattered_cloak",
        name: "tattered cloak",
        description: "Tattered cloak lies here.",
        keywords: ["tattered cloak", "cloak"]
      },
    ],
  },
  "kraakenhavn/the_graveyard/the_lonesome_bell" => %Zung.Game.Room{
    id: "kraakenhavn/the_graveyard/the_lonesome_bell",
    title: "The Lone Bell",
    description: "A once-majestic church stands, its walls now cracked and worn.||NL||The lone bell tower rises above the crumbling roof, casting a shadow over the surrounding headstones.",
    exits: [
      %Zung.Game.Room.Exit{direction: :north, to: "kraakenhavn/the_graveyard/the_overgrown_tomb", description: "A narrow alleyway leads north to more forgotten graves"},
      %Zung.Game.Room.Exit{direction: :east, to: "kraakenhavn/the_graveyard/rachel_grimstone_office", description: "The door to Rachel Grimstone's office creaks open on the east side of the church"},
    ],
  },
  "kraakenhavn/the_graveyard/the_overgrown_tomb" => %Zung.Game.Room{
    id: "kraakenhavn/the_graveyard/the_overgrown_tomb",
    title: "The Overgrown Tomb",
    description: "Crumbling stone statues guard the entrance to this overgrown mausoleum.||NL||Vines crawl up the walls as far as they can reach, and moss clings to crumbling headstones.",
    exits: [
      %Zung.Game.Room.Exit{direction: :north, to: "kraakenhavn/the_graveyard/the_graveyard_entrance", description: "A narrow path leads back to the graveyard entrance."},
      %Zung.Game.Room.Exit{direction: :east, to: "kraakenhavn/the_graveyard/tomb_raider_supply_room", description: "A hidden door in the wall of vines conceals a room filled with supplies."},
      %Zung.Game.Room.Exit{direction: :south, to: "kraakenhavn/the_graveyard/rachel_grimstone_office", description: "A narrow corridor stretches into Rachel Grimstone's office, her scent lingering on the air."},
    ],
    objects: [
      %Zung.Game.Object{
        id: "creepy_statue",
        name: "creepy_statue",
        description: "Creepy_statue lies here.",
        keywords: ["creepy_statue"]
      },
      %Zung.Game.Object{
        id: "tombstone",
        name: "tombstone",
        description: "Tombstone lies here.",
        keywords: ["tombstone"]
      },
    ],
  },
  "kraakenhavn/the_graveyard/the_sewer_access" => %Zung.Game.Room{
    id: "kraakenhavn/the_graveyard/the_sewer_access",
    title: "Sewer Access",
    description: "A narrow, dimly lit stairway leads down into darkness.||NL||Dusty cobwebs cling to the walls.",
    exits: [
      %Zung.Game.Room.Exit{direction: :north, to: "kraakenhavn/the_graveyard/the_graveyard_entrance", description: "A worn stone path leads up into the graveyard"},
      %Zung.Game.Room.Exit{direction: :south, to: "kraakenhavn/the_graveyard/rachel_grimstone_office", description: "The dimly lit stairway continues downward, vanishing into darkness"},
      %Zung.Game.Room.Exit{direction: :down, to: "kraakenhavn/the_graveyard/the_overgrown_tomb", description: "A rickety ladder descends into the sewer below"},
    ],
    objects: [
      %Zung.Game.Object{
        id: "rusty_lantern",
        name: "a rusty lantern",
        description: "Rusty lantern lies here.",
        keywords: ["rusty lantern", "lantern"]
      },
      %Zung.Game.Object{
        id: "piece_of_torn_fabric",
        name: "a piece of torn fabric",
        description: "Piece of torn fabric lies here.",
        keywords: ["piece of torn fabric", "fabric", "torn fabric"]
      },
    ],
  },
  "kraakenhavn/the_graveyard/tomb_raider_supply_room" => %Zung.Game.Room{
    id: "kraakenhavn/the_graveyard/tomb_raider_supply_room",
    title: "Victoria Stonebrook's Supply Room",
    description: "Cramped shelves line the walls, stacked with pickaxes and lanterns.||NL||A small workbench sits in the corner, bearing tools for excavation.",
    exits: [
      %Zung.Game.Room.Exit{direction: :north, to: "kraakenhavn/the_graveyard/the_overgrown_tomb", description: "A narrow corridor stretches into darkness"},
      %Zung.Game.Room.Exit{direction: :east, to: "kraakenhavn/the_graveyard/rachel_grimstone_office", description: "A door with a rusted doorknob leads to a dimly lit room"},
      %Zung.Game.Room.Exit{direction: :west, to: "kraakenhavn/the_graveyard/the_lonesome_bell", description: "A set of stairs descends into the darkness"},
      %Zung.Game.Room.Exit{direction: :south, to: "kraakenhavn/the_graveyard/the_graveyard_entrance", description: "The entrance to the graveyard beckons from beyond a nearby gate"},
    ],
    objects: [
      %Zung.Game.Object{
        id: "pickaxe",
        name: "pickaxe",
        description: "Pickaxe lies here.",
        keywords: ["pickaxe"]
      },
      %Zung.Game.Object{
        id: "lantern",
        name: "lantern",
        description: "Lantern lies here.",
        keywords: ["lantern"]
      },
      %Zung.Game.Object{
        id: "trowel",
        name: "trowel",
        description: "Trowel lies here.",
        keywords: ["trowel"]
      },
    ],
  },
  "kraakenhavn/the_spire/treasury_of_relics" => %Zung.Game.Room{
    id: "kraakenhavn/the_spire/treasury_of_relics",
    title: "The Treasury of the Ancients",
    description: "Glittering relics and artifacts adorn the walls, casting a warm glow in the dimly lit chamber.",
    exits: [
      %Zung.Game.Room.Exit{direction: :north, to: "kraakenhavn/the_spire/entrance_to_the_spire", description: "A narrow corridor stretches into the darkness."},
      %Zung.Game.Room.Exit{direction: :east, to: "kraakenhavn/the_spire/corridors_of_the_ruin", description: "The air grows thick with the stench of decay as you proceed."},
      %Zung.Game.Room.Exit{direction: :south, to: "kraakenhavn/the_spire/library_of_forbidden_knowledge", description: "Shelved texts seem to lean in, as if sharing secrets."},
      %Zung.Game.Room.Exit{direction: :west, to: "kraakenhavn/the_spire/balcony_over_the_ruin", description: "The wind whispers through the broken stones below."},
    ],
    objects: [
      %Zung.Game.Object{
        id: "ancient_tome",
        name: "Ancient Tome",
        description: "Ancient Tome lies here.",
        keywords: ["Ancient Tome", "Tome"]
      },
      %Zung.Game.Object{
        id: "golden_amulet",
        name: "Golden Amulet",
        description: "Golden Amulet lies here.",
        keywords: ["Golden Amulet", "Amulet"]
      },
    ],
  },
}
       }},
      {Task.Supervisor, name: Zung.Server.TaskSupervisor},
      Supervisor.child_spec({Task, fn -> Zung.Server.accept(port) end}, restart: :permanent)
    ]

    opts = [strategy: :one_for_one, name: Zung.Server.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
