defmodule Zung.Game.Parser do

  def parse(%Zung.Client{} = _client, _data) do
    :unknown_command
  end
end
