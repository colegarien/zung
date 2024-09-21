defmodule Zung.Game.Object do
  defstruct [
    :id,
    name: "",
    description: "",
    keywords: []
  ]

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

  def describe_target(objects, id) do
    Enum.find(objects, %{description: "You see nothing of interest."}, &(id === &1.id)).description
  end

  def short_describe(%Zung.Game.Object{name: name} = _object), do: name
  def long_describe(%Zung.Game.Object{description: description} = _object), do: description
end
