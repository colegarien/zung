defmodule Zung.Game.Room2 do
  def exits(), do: %{up: Zung.Game.Room3, south: Zung.Game.Room1}
  def title(), do: "The Lower Deck"
  def description(), do: "The damp, musty underbelly of a ship."

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
