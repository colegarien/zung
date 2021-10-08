defmodule Zung.State.State do
  @type state_data :: term
  @callback run(%Zung.Client{}, state_data) :: {module, state_data} | {atom, state_data}
end
