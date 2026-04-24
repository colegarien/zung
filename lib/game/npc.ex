defmodule Zung.Game.Npc do
  defstruct [
    :id,
    name: "",
    keywords: [],
    greeting: "",
    topics: %{}
  ]

  @type t :: %__MODULE__{
          id: String.t() | nil,
          name: String.t(),
          keywords: [String.t()],
          greeting: String.t(),
          topics: %{String.t() => String.t()}
        }

  @spec describe([t()]) :: String.t()
  def describe(npcs) when is_list(npcs) do
    if Enum.empty?(npcs) do
      ""
    else
      "||MAG||" <>
        Enum.reduce(npcs, "", fn npc, acc ->
          "#{acc}    #{npc.name} is here.||NL||"
        end) <>
        "||RESET||"
    end
  end

  @spec find([t()], String.t()) :: t() | nil
  def find(npcs, query) do
    Enum.find(npcs, nil, &(query === &1.id or query in &1.keywords))
  end
end
