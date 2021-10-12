defmodule Zung.State.Login.Creation.ColorCheck do
  @behaviour Zung.State.State

  @color_test_banner ~S"""
--------------------------------------------------------------------------------
This section is to determine if you client supports colors used in Zung.
If you can see the colors enter 'y' if you can't enter 'n'.
--------------------------------------------------------------------------------
      Color Test:     ||RED||Red ||GRN||Green ||YEL||Yellow ||BLU||Blue ||MAG||Magenta ||CYA||Cyan ||WHT||White||RESET||

"""

  @impl Zung.State.State
  def run(%Zung.Client{} = client, data) do
    Zung.Client.clear_screen(client)
    Zung.Client.write_data(%Zung.Client{client | use_ansi?: true}, @color_test_banner)
    handle_color_check(client, data)
  end

  def handle_color_check(%Zung.Client{} = client, data) do
    Zung.Client.write_data(client, "Use Color? (Y/N): ")
    response = Zung.Client.read_line(client) |> String.downcase

    yes? = String.starts_with?(response, "y")
    no? = String.starts_with?(response, "n")
    if not yes? and not no? do
      Zung.Client.write_line(client, "Please enter either 'yes' or 'no'.")
      handle_color_check(client, data)
    else
      {Zung.State.Login.Creation.Finalize, %Zung.Client{client | use_ansi?: yes?}, Map.put(data, :use_ansi?, yes?)}
    end
  end
end
