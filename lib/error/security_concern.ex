defmodule Zung.Error.SecurityConcern do
  defexception message: "The connection was forcibly closed due to some security concern.",
               show_client: false
end
