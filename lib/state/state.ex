defmodule Zung.State.State do
  @type state_data :: term
  @callback run(%Zung.Client{}, state_data) ::
              {module, %Zung.Client{}, state_data} | {atom, %Zung.Client{}, state_data}
end
