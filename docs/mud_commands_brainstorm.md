# MUD Command Brainstorm for Zung

## Context

Zung is an Elixir MUD engine with 36 rooms across a Czech-themed port town (Kralovice Mor) and a tutorial ship. The current command vocabulary is minimal: movement (6 directions + `enter`), `look` (with target variants), `say`/`csay`/`ooc`, and `quit`. Objects exist in rooms but are scenery-only — no inventory, no manipulation, no NPCs, no combat, no stats. The architecture (GenServers, pub/sub via gproc, state machine) is clean and ready for extension. The parser lives in `lib/game/parser.ex`, dispatch in `lib/state/game/game.ex`.

The goal below is not an implementation plan — it's a curated set of commands that would make the world come alive, with concrete scenarios showing how each creates engaging play. Commands are grouped by the kind of experience they unlock.

---

## 1. `help` — Make the Game Learnable

The single highest-impact addition. Right now a new player types `look`, sees objects, and has no idea they can `look at compass`. Every other command below is wasted if players can't discover it.

**Engaging applications:**

- **Context-sensitive hints.** Typing `help` in a room with a locked door says *"You notice a locked door here. Try: unlock <object> with <key>."* In a room with an NPC: *"Someone is here. Try: talk <name>."* This teaches through the world, not a manual.
- **Progressive revelation.** First login, `help` shows only movement and look. After picking up your first item, inventory commands appear. After first combat, combat commands appear. The help system *grows with the player* so it never overwhelms.
- **`help <topic>` for lore.** `help quarry` tells you the quarry's history. `help kralovice` gives town lore. This doubles as both a game mechanic and a worldbuilding delivery vehicle — players who read help become more capable *and* more immersed.

---

## 2. `get` / `drop` / `inventory` — Make Objects Real

The 35 items in the world are currently wallpaper. The moment a player can pick up that `small_rusty_key` from the Eastern Wall, every object becomes a question: *what is this for?*

**Engaging applications:**

- **The key puzzle.** The `small_rusty_key` on the Eastern Wall unlocks a gate in the South Wall Gatehouse, revealing a hidden armory or passage out of the city. Simple, classic, immediately satisfying. The player has to *notice* the key, *carry* it across several rooms, and *figure out* where it goes.
- **The logbook trade.** The `worn_leather_bound_logbook` in the Captain's Chamber contains a manifest. An NPC at the docks pays for it (or attacks you for having it). Suddenly an examine-only prop becomes a plot device.
- **Weight and choice.** Carry capacity forces decisions. You found exotic spices *and* rare herbs at the market, but you can only carry one more thing and there's a locked chest three rooms away. Do you drop the spices, or come back later and risk someone else grabbing them?

---

## 3. `examine` / `x` — Reward Curiosity

Deeper than `look at`, examine reveals hidden properties, triggers discoveries, and teaches players that the world has layers.

**Engaging applications:**

- **Hidden compartments.** `examine armchair` in the Town Hall reveals a hidden drawer containing a folded letter. `look at armchair` just says it's ornate. This trains players to examine *everything*, creating a treasure-hunt mentality.
- **Object history.** `examine tarnished_brass_compass` reveals an inscription: *"To Captain Borovy, who always found his way home."* — connecting it to the `kancelar_skupce_borovy` office. The world starts cross-referencing itself.
- **State-revealing.** `examine gate` shows whether it's locked, rusted shut, or ajar. `examine lantern` shows whether it's lit, empty, or full of oil. Gives players information they need to act without trial-and-error.

---

## 4. `open` / `close` / `lock` / `unlock` — Doors and Secrets

Transforms static exits into interactive barriers. Combined with keys from `get`, this is the bread and butter of MUD puzzle design.

**Engaging applications:**

- **The gatehouse sequence.** The South Wall Gatehouse has a gate that's locked. Find the rusty key, unlock it, enter the gatehouse, find a lever inside. Pull the lever to open the main South Gate — which is a city-wide event announced to all players. Suddenly your solo puzzle-solving affects the shared world.
- **Containers.** A locked chest in the Quarry contains old mining maps that reveal a hidden tunnel (secret exit). The key is on the Quarry Foreman's desk. Opening the chest is a two-room puzzle; the reward is a shortcut through the whole quarry.
- **Closeable doors for defense.** Close and lock a door behind you to prevent an NPC pursuer from following. Or lock other players out of a room during a tense standoff. Doors become tactical.

---

## 5. `search` — Active Discovery

Unlike `look` and `examine` which target known objects, `search` is for finding the *unknown*. It makes every room potentially deeper than it appears.

**Engaging applications:**

- **Hidden exits.** `search` in the Smiczny Tunnel reveals a narrow crack in the wall — a secret passage to a hidden chamber with old mining relics. Players who just walk through never find it. Players who search are rewarded with content others miss.
- **Buried items.** `search` at the West Garden Path turns up a muddy coin stamped with an unfamiliar crest. It's worthless alone, but collecting three such coins from different hidden locations unlocks a secret NPC dialogue.
- **Clue trails.** `search` at a crime scene (a ransacked office) reveals footprints leading east, a torn piece of fabric, and a smashed vial. Each clue points toward the next location. The search command becomes the engine of detective-style quests.

---

## 6. `use` — Contextual Object Interaction

A general-purpose verb: `use lantern`, `use key on door`, `use compass`. Each object defines what "use" means for it, creating surprises.

**Engaging applications:**

- **The lantern in the dark.** A tunnel deep in the quarry is pitch-black — entering it gives only *"You stumble in absolute darkness."* and movement is randomized. `use rusty_lantern` (found two rooms back) illuminates the room, revealing the description, exits, and a skeleton clutching a journal.
- **The compass as guide.** `use tarnished_brass_compass` anywhere in the world gives you a bearing: *"The needle swings and settles pointing northeast."* It always points toward a specific hidden location — a treasure or a quest goal. It's a persistent puzzle that spans the whole map.
- **The lockpick gamble.** `use rusted_lockpick on chest` has a chance of success based on lockpick condition. Fail and the lockpick breaks. Succeed and the chest opens. Risk/reward with a consumable resource.

---

## 7. `read` — Lore Delivery Through Play

Distinct from `examine` — specifically for text-bearing objects like books, scrolls, signs, and maps. Makes literacy a game mechanic.

**Engaging applications:**

- **The Captain's logbook.** `read logbook` in the Captain's Chamber shows dated entries revealing the ship's journey: ports visited, cargo manifests, a cryptic final entry about "the thing in the hold." Multi-page reading (`read logbook page 3`) creates a document players page through.
- **Signposts and wayfinding.** `read sign` at crossroads shows directions: *"East: Docks. North: Market Square. West: The Quarry — DANGER."* Helps navigation while worldbuilding. Signs in different areas might be in different languages, requiring a translation item.
- **Recipe scrolls.** `read scroll` reveals a crafting recipe: *"Combine rare herbs with quarry water in a clay pot to produce a Miner's Tonic."* The recipe itself is the quest — find the ingredients, find a pot, make the thing.

---

## 8. `talk` / `ask` / `greet` — NPC Conversation

Keyword-driven dialogue: `talk merchant`, `ask merchant about spices`, `ask guard about gate`. NPCs become information sources, quest givers, and characters.

**Engaging applications:**

- **The suspicious merchant.** `talk merchant` at the Market Stand gets you a friendly greeting and a price list. `ask merchant about rare herbs` gets a knowing look and a whispered offer: *"I know where to get them... for a price."* `ask merchant about captain borovy` — he goes pale and refuses to talk further. Keywords unlock different NPC states.
- **The guard's dilemma.** A guard at the South Gate asks you to deliver a message to the watchtower — but warns you the quarry path is dangerous. Completing the errand changes the guard's dialogue permanently: he trusts you now and shares rumors about hidden passages.
- **Faction reputation.** Talking to the dock workers about the quarry foreman reveals a labor dispute. Taking sides (delivering messages for one faction, stealing documents for another) shifts how NPCs respond to you across the whole town.

---

## 9. `emote` / `me` — Social Expression

`emote laughs nervously` displays *"Ozzy laughs nervously."* Built-in emotes (`bow`, `wave`, `nod`, `shrug`) with their own display text.

**Engaging applications:**

- **NPC reactions.** `bow` in front of the town magistrate earns respect — he shares information he wouldn't otherwise. `shrug` at the merchant lowers his opinion of you. Emotes become a social skill system without stats.
- **Ritual puzzles.** A sealed door in the old chapel responds to a sequence of emotes: `kneel`, then `pray`, then `bow`. The combination is hinted at in a book found elsewhere. Emotes become puzzle inputs.
- **Multiplayer theater.** Two players staging an impromptu scene in the tavern — emotes are the vocabulary of collaborative storytelling. The MUD equivalent of improv.

---

## 10. `whisper` / `tell` — Private Communication

`whisper Bob meet me at the docks` — only Bob sees the message; others see *"Ozzy whispers something to Bob."* `tell` works across rooms.

**Engaging applications:**

- **Conspiracy and intrigue.** Two players planning a heist in a crowded room. Others know *something* is being discussed but not what. Creates social tension organically.
- **NPC whispers.** An NPC whispers to you unprompted: *"The foreman hides something in the old tunnel. Third stone on the left."* — quest clues delivered as secrets feel more valuable than announced text.
- **Deaf rooms.** In the noisy quarry, `say` doesn't carry — only `whisper` (close proximity) or `shout` works. Environment shapes which communication commands function.

---

## 11. `shout` / `yell` — Extended Range Communication

Heard in the current room *and all adjacent rooms*. Has consequences.

**Engaging applications:**

- **Calling for help.** Lost in the quarry tunnels, `shout help` reaches players one room away. They hear *"You hear someone shouting from the east!"* and can follow the sound to find you.
- **Alerting enemies.** Shouting near a guarded area alerts the guards — they come to investigate. Silence is tactical. This creates a stealth/noise dynamic without a full stealth system.
- **Town crier gameplay.** A player on the Wall Top Walkway shouts news that carries across half the fortress. Emergent role-playing: someone decides to be the town crier.

---

## 12. `who` — Community Awareness

Shows online players. Optional location sharing, idle times.

**Engaging applications:**

- **Finding other players.** *"Ozzy — The Docks (idle 3m)"*. You know where to go for company. Simple but transforms a lonely single-player feel into awareness of a shared world.
- **Anonymous mode.** A "cloaked" status hides your location. Others see *"Ozzy — somewhere"*. Creates mystery about what cloaked players are doing.
- **NPC listing.** `who npc` shows which NPCs are "awake" in which areas. Some NPCs only appear at certain times or under certain conditions.

---

## 13. `map` — Spatial Awareness

ASCII minimap of rooms you've visited. Fog of war for the unexplored.

**Engaging applications:**

- **Fog of war exploration.** The map starts almost blank. Each room you enter fills in. Completionists are driven to fill the entire map — exploration becomes its own reward.
- **Landmarks.** Special rooms (the watchtower, the captain's quarters, the market) show as distinct symbols. The map becomes a mental model aid for navigating the 36-room world.
- **Secret rooms.** Rooms found via `search` appear on the map in a different color, marking them as discoveries. Bragging rights for completionists.

---

## 14. `craft` / `combine` — Creation

Combine inventory items to create new things. Recipes found through `read` and experimentation.

**Engaging applications:**

- **The makeshift torch.** Combine `planks` from the Lower Deck + `oil` from a lantern = a torch that lasts 10 minutes of real time. Consumable light source for dark areas. Solves the dark-tunnel problem with player agency rather than just finding the "right" item.
- **The miner's tonic.** `rare herbs` + `quarry water` (from a specific room) + `clay pot` = a tonic that boosts a stat temporarily. The recipe is in a scroll in the foreman's office. Finding, reading, gathering, crafting — it's a four-step quest embedded in the craft system.
- **Repairing the bridge.** Combining `planks` + `rope` creates a plank bridge that can be placed in a specific broken-bridge room, creating a new permanent exit. Player actions reshape the map.

---

## 15. `cast` — Magic as Utility and Discovery

Spells as environmental tools, not just combat damage. Verbal invocation: `cast illuminate`, `cast reveal`, `cast mend`.

**Engaging applications:**

- **`cast illuminate`** — Lights a dark room permanently (or temporarily). The quarry tunnels have unlit branches; casting light reveals hidden writing on walls, alternate exits, or lurking creatures.
- **`cast reveal`** — Functions like a magical `search` but finds illusions and magical concealment. A seemingly blank wall in the chapel `reveal`s a shimmering doorway. Mundane `search` wouldn't find it.
- **`cast gust`** — Blows out a candle, scatters papers on a desk (revealing one with a clue), or knocks down a rope bridge behind you (preventing pursuit but also preventing retreat). Spells with environmental side-effects create memorable moments.
- **`cast mend`** — Repairs a broken item: the rusted lockpick becomes a functional lockpick, the tattered map becomes readable. Gives value to "junk" items.

---

## 16. `score` / `stats` — Character Identity

View your character sheet: health, experience, level, skills, exploration progress.

**Engaging applications:**

- **Exploration percentage.** *"You have explored 14 of 36 known rooms (38%)."* Turns wandering into a scored activity. Players with 100% exploration earn a title.
- **Skill proficiencies.** *"Lockpicking: Novice (3/10 successful picks)"* — skills improve through use, not point allocation. The game rewards trying things.
- **Reputation tracker.** *"Dock Workers: Friendly. Quarry Guild: Suspicious."* Shows how your choices have shaped NPC relationships. Gives weight to dialogue choices.

---

## 17. `alias` — Player-Defined Shortcuts

The alias system already exists in the code but has no player-facing command. Expose it.

**Engaging applications:**

- **Combat macros.** `alias aa attack all` — power users create optimized flows. The game rewards system mastery.
- **Navigation shortcuts.** `alias home north;north;east;east` — one command to walk a saved path. Players build their own fast-travel.
- **Persona expression.** `alias greet emote bows deeply and tips their hat` — players define signature gestures. Identity through command customization.

---

## 18. `follow` / `lead` — Group Movement

`follow Ozzy` — you automatically move when Ozzy moves. `lead` shows who's following you.

**Engaging applications:**

- **Guided tours.** An experienced player leads a newcomer through the quarry without the newcomer needing to know directions. Mentorship through mechanics.
- **NPC guides.** An NPC guide at the docks offers to lead you through the walls district. `follow guide` and they walk you through, narrating as they go. Combines movement, lore delivery, and NPC interaction.
- **Ambush potential.** Following someone into a dead-end room where they close and lock the door behind you. Following has trust implications.

---

## Priority Tiers

**Tier 1 — These unlock fundamental play:**
- `help` (makes everything else discoverable)
- `get` / `drop` / `inventory` (makes objects interactive)
- `examine` (rewards curiosity)
- `who` (multiplayer awareness)

**Tier 2 — These create puzzles and stories:**
- `open` / `close` / `lock` / `unlock` (barrier puzzles)
- `use` (contextual interaction)
- `search` (active discovery)
- `read` (lore delivery)
- `talk` / `ask` (NPC life)

**Tier 3 — These deepen the social world:**
- `emote` (expression)
- `whisper` / `tell` (private communication)
- `shout` (extended range + consequences)
- `alias` (player empowerment)
- `follow` / `lead` (group play)

**Tier 4 — These create long-term engagement:**
- `map` (exploration tracking)
- `score` / `stats` (progression)
- `craft` / `combine` (creation)
- `cast` (magic as tool)
