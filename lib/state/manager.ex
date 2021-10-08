defmodule Zung.State.Manager do
  require Logger

  def run({:die, _}, %Zung.Client{} = _client), do: exit(:shutdown)
  def run({state_module_name, data}, %Zung.Client{} = client) do
    apply(state_module_name, :run, [client, data]) |> run(client)
  end

end
