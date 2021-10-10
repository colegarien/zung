defmodule Zung.Game.Room3 do
  def exits(), do: %{down: Zung.Game.Room2}
  def title(), do: "The Main Deck"
  def description(), do: "The top deck of this vessel.||NL||The ship is docked and ready for disembarkment."

  def describe() do
    title_string = "||BOLD||||GRN||#{title()}||RESET||"
    description_string = "||YEL||#{description()}||RESET||"
    exits_string = "exits: " <> Enum.reduce(Map.keys(exits()), "", fn direction, acc ->
      separator = (if acc != "", do: ", ", else: "")
      "#{acc}#{separator}||BOLD||||CYA||#{direction}||RESET||"
    end)

    "||NL||#{title_string}||NL||||NL||#{description_string}||NL||||NL||#{exits_string}||NL||||NL||"
  end

  def move(direction) do
    if Map.has_key?(exits(), direction) do
      {:ok, exits()[direction]}
    else
      {:error, "||RED||There is no where to go in the direction.||RESET||"}
    end
  end
end
