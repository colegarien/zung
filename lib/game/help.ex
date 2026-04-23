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
