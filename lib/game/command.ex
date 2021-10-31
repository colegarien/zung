defmodule Zung.Game.Command do
  require Logger

  # TODO ideas for commands -> https://github.com/sneezymud/dikumud/blob/master/lib/help_table
  # TODO cool alias section -> https://github.com/Yuffster/CircleMUD/blob/master/lib/text/help/commands.hlp
  # TODO nice website -> https://dslmud.fandom.com/wiki/Commands
  # TODO neat thing about room/area building -> http://www.forgottenkingdoms.org/builders/blessons.php


  def parse(username, line) do
    # TODO the split seems like non-sense, maybe need to completely separate the parser and "command" excecutor
    case String.split(line) do
      ["do", thing] -> {:ok, {:do, thing}}
      ["quit"] -> {:ok, :quit}
      ["look"] -> {:look, :room}
      ["l"] -> {:look, :room}
      ["look" | targeting_words] ->
        worthless_words = ["to", "the", "at", "in"]
        target = targeting_words
          |> Enum.filter(&(&1 not in worthless_words))
          |> Enum.reduce("", &("#{&2} #{&1}"))
          |> String.trim
        if(target in ["north", "south", "east", "west", "northwest", "northeast", "southwest", "southeast", "up", "down"]) do
          {:look, String.to_atom(target)}
        else
          {:look, target}
        end
      ["l" | targeting_words] ->
        worthless_words = ["to", "the", "at", "in"]
        target = targeting_words
          |> Enum.filter(&(&1 not in worthless_words))
          |> Enum.reduce("", &("#{&2} #{&1}"))
          |> String.trim
        if(target in ["north", "south", "east", "west", "northwest", "northeast", "southwest", "southeast", "up", "down"]) do
          {:look, String.to_atom(target)}
        else
          {:look, target}
        end
      ["north"] -> {:move, :north}
      ["south"] -> {:move, :south}
      ["east"] -> {:move, :east}
      ["west"] -> {:move, :west}
      ["northwest"] -> {:move, :northwest}
      ["northeast"] -> {:move, :northeast}
      ["southwest"] -> {:move, :southwest}
      ["southeast"] -> {:move, :southeast}
      ["up"] -> {:move, :up}
      ["down"] -> {:move, :down}
      ["n"] -> {:move, :north}
      ["s"] -> {:move, :south}
      ["e"] -> {:move, :east}
      ["w"] -> {:move, :west}
      ["nw"] -> {:move, :northwest}
      ["ne"] -> {:move, :northeast}
      ["sw"] -> {:move, :southwest}
      ["se"] -> {:move, :southeast}
      ["u"] -> {:move, :up}
      ["d"] -> {:move, :down}
      ["ooc" | the_rest] ->
        message = the_rest |> Enum.reduce("", &("#{&2} #{&1}")) |> String.trim
        {:publish, {:ooc, {username, message}}}
      _ -> {:error, :unknown_command}
    end
  end

  def run({:do, thing}) do
    {:ok, thing <> " was done"}
  end

  def run(:quit) do
    raise Zung.Error.Connection.Closed
  end

  def run({:move, direction}) do
    {:move, direction}
  end

  def run({:look, :room}) do
    {:look, :room}
  end

  def run({:look, target}) do
    {:look, target}
  end

  def run({:publish, data}) do
    {:publish, data}
  end

  def run(_command) do
    {:ok, "Ok"}
  end

end
