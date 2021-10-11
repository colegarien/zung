defmodule Zung.Game.Command do

  # TODO ideas for commands -> https://github.com/sneezymud/dikumud/blob/master/lib/help_table
  # TODO cool alias section -> https://github.com/Yuffster/CircleMUD/blob/master/lib/text/help/commands.hlp
  # TODO nice website -> https://dslmud.fandom.com/wiki/Commands
  # TODO neat thing about room/area building -> http://www.forgottenkingdoms.org/builders/blessons.php


  def parse(line) do
    case String.split(line) do
      ["do", thing] -> {:ok, {:do, thing}}
      ["quit"] -> {:ok, :quit}
      ["look"] -> {:look, :room}
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
      _ -> {:error, :unknown_command}
    end
  end

  def run({:do, thing}) do
    {:ok, thing <> " was done"}
  end

  def run(:quit) do
    raise Zung.Error.ConnectionClosed, message: "Player logged out."
  end

  def run({:move, direction}) do
    {:move, direction}
  end

  def run({:look, :room}) do
    {:look, :room}
  end

  def run(_command) do
    {:ok, "Ok"}
  end

end
