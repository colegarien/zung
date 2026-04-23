defmodule Zung.Game.Object do
  defstruct [
    :id,
    name: "",
    description: "",
    keywords: [],
    examine_text: nil,
    takeable?: false
  ]

  @type t :: %__MODULE__{
          id: String.t() | nil,
          name: String.t(),
          description: String.t(),
          keywords: [String.t()],
          examine_text: String.t() | nil,
          takeable?: boolean()
        }

  @spec describe([t()] | t()) :: String.t()
  def describe(objects) when is_list(objects) do
    if Enum.empty?(objects) do
      ""
    else
      "||YEL||" <>
        Enum.reduce(objects, "", fn object, acc ->
          "#{acc}    #{short_describe(object)}||NL||"
        end) <>
        "||RESET||"
    end
  end

  @spec describe_target([t()], String.t()) :: String.t()
  def describe_target(objects, id) do
    Enum.find(objects, %{description: "You see nothing of interest."}, &(id === &1.id)).description
  end

  @spec examine_target([t()], String.t()) :: String.t()
  def examine_target(objects, id) do
    object = Enum.find(objects, nil, &(id === &1.id))

    cond do
      object == nil -> "You see nothing of interest."
      object.examine_text != nil -> object.examine_text
      true -> object.description
    end
  end

  def short_describe(%Zung.Game.Object{name: name} = _object), do: name
  def long_describe(%Zung.Game.Object{description: description} = _object), do: description
end
