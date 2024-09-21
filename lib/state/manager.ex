defmodule Zung.State.Manager do
  def run({state_module_name, %Zung.Client{} = client, data}) do
    apply(state_module_name, :run, [client, data]) |> run
  end
end
