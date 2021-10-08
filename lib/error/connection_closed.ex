defmodule Zung.Error.ConnectionClosed do
  defexception message: "The connection to the client was lost or closed."
end
