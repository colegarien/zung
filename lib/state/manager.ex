defmodule Zung.State.Manager do
  def run({state_module_name, data}, %Zung.Client{} = client) do
    apply(state_module_name, :run, [client, data]) |> run(client)
  end
end
