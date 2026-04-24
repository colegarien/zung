defmodule Zung.Game.Help do
  @commands %{
    "help" => %{
      summary: "Display available commands or help for a specific command",
      usage: "help [command]",
      detail:
        "Type 'help' to see all available commands, or 'help <command>' for detailed help on a specific command."
    },
    "look" => %{
      summary: "Look around the room or at something specific",
      usage: "look [target]",
      detail:
        "Without arguments, describes the current room. With a target, examines a specific object, exit, or direction. Alias: l"
    },
    "examine" => %{
      summary: "Examine something closely for more detail",
      usage: "examine <target>",
      detail:
        "Take a closer look at an object or feature for additional details beyond what 'look' reveals. Alias: x"
    },
    "north" => %{
      summary: "Move north",
      usage: "north",
      detail: "Move to the room to the north, if an exit exists. Alias: n"
    },
    "south" => %{
      summary: "Move south",
      usage: "south",
      detail: "Move to the room to the south, if an exit exists. Alias: s"
    },
    "east" => %{
      summary: "Move east",
      usage: "east",
      detail: "Move to the room to the east, if an exit exists. Alias: e"
    },
    "west" => %{
      summary: "Move west",
      usage: "west",
      detail: "Move to the room to the west, if an exit exists. Alias: w"
    },
    "up" => %{
      summary: "Move up",
      usage: "up",
      detail: "Move to the room above, if an exit exists. Alias: u"
    },
    "down" => %{
      summary: "Move down",
      usage: "down",
      detail: "Move to the room below, if an exit exists. Alias: d"
    },
    "enter" => %{
      summary: "Enter a named exit",
      usage: "enter <exit name>",
      detail: "Move through a named exit such as a door, gate, or passage."
    },
    "say" => %{
      summary: "Say something to the room",
      usage: "say <message>",
      detail: "Speak a message that everyone in the current room can hear."
    },
    "csay" => %{
      summary: "Say something to a chat channel",
      usage: "csay <channel> <message>",
      detail:
        "Send a message to a chat channel you have joined. Alias: ooc (for the ooc channel)"
    },
    "who" => %{
      summary: "See who is currently online",
      usage: "who",
      detail: "Displays a list of all players currently connected to the game."
    },
    "get" => %{
      summary: "Pick up an item from the room",
      usage: "get <item>",
      detail:
        "Pick up an item from the current room and add it to your inventory. Alias: take"
    },
    "drop" => %{
      summary: "Drop an item from your inventory",
      usage: "drop <item>",
      detail: "Drop an item from your inventory into the current room."
    },
    "inventory" => %{
      summary: "View items you are carrying",
      usage: "inventory",
      detail: "Display a list of all items currently in your inventory. Alias: i"
    },
    "quit" => %{
      summary: "Quit the game",
      usage: "quit",
      detail: "Disconnect from the game."
    },
    "read" => %{
      summary: "Read text on an object",
      usage: "read <object>",
      detail:
        "Read text written on an object such as a book, sign, scroll, or map. The object can be in the room or in your inventory."
    },
    "search" => %{
      summary: "Search the room for hidden things",
      usage: "search",
      detail:
        "Actively search the current room for hidden items, exits, or clues that aren't immediately visible."
    },
    "use" => %{
      summary: "Use an object",
      usage: "use <object> [on <target>]",
      detail:
        "Use an object in a context-appropriate way. You can also specify a target: 'use key on door'."
    },
    "open" => %{
      summary: "Open a door or exit",
      usage: "open <exit>",
      detail: "Open a closed door, gate, or other exit so you can pass through."
    },
    "close" => %{
      summary: "Close a door or exit",
      usage: "close <exit>",
      detail: "Close an open door, gate, or other exit."
    },
    "lock" => %{
      summary: "Lock a closed exit",
      usage: "lock <exit>",
      detail: "Lock a closed door or gate. You must have the correct key in your inventory."
    },
    "unlock" => %{
      summary: "Unlock a locked exit",
      usage: "unlock <exit>",
      detail:
        "Unlock a locked door or gate. You must have the correct key in your inventory."
    },
    "talk" => %{
      summary: "Talk to someone",
      usage: "talk <person>",
      detail: "Start a conversation with a character in the room."
    },
    "ask" => %{
      summary: "Ask someone about a topic",
      usage: "ask <person> about <topic>",
      detail:
        "Ask a character about a specific topic. Different topics may reveal different information."
    }
  }

  @spec list_commands() :: String.t()
  def list_commands do
    header = "||BOLD||||CYA||Available Commands:||RESET||||NL||"

    commands_text =
      @commands
      |> Enum.sort_by(fn {name, _} -> name end)
      |> Enum.reduce("", fn {name, %{summary: summary}}, acc ->
        acc <> "  ||BOLD||||GRN||#{String.pad_trailing(name, 12)}||RESET|| #{summary}||NL||"
      end)

    footer =
      "||NL||Type ||BOLD||help <command>||RESET|| for more information on a specific command."

    header <> commands_text <> footer
  end

  @spec describe_command(String.t()) :: String.t()
  def describe_command(name) do
    case Map.get(@commands, name) do
      nil ->
        "||RED||Unknown command: \"#{name}\". Type 'help' to see available commands.||RESET||"

      %{summary: summary, usage: usage, detail: detail} ->
        "||BOLD||||CYA||#{name}||RESET|| - #{summary}||NL||" <>
          "||BOLD||Usage:||RESET|| #{usage}||NL||" <>
          detail
    end
  end
end
