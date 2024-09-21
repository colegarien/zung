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
    Zung.Client.raw_clear_screen(client)

    Zung.Client.force_ansi(client, true)
    Zung.Client.raw_write(client, @color_test_banner)
    Zung.Client.force_ansi(client, false)

    handle_color_check(client, data)
  end

  def handle_color_check(%Zung.Client{} = client, data) do
    Zung.Client.raw_write(client, "Use Color? (Y/N): ")
    response = Zung.Client.raw_read(client) |> String.downcase()

    yes? = String.starts_with?(response, "y")
    no? = String.starts_with?(response, "n")

    if not yes? and not no? do
      Zung.Client.raw_write_line(client, "Please enter either 'yes' or 'no'.")
      handle_color_check(client, data)
    else
      Zung.Client.force_ansi(client, yes?)
      {Zung.State.Login.Creation.Finalize, client, Map.put(data, :use_ansi?, yes?)}
    end
  end
end
