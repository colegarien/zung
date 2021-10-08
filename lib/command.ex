defmodule Zung.Command do
  def parse(line) do
    case String.split(line) do
      ["do", thing] -> {:ok, {:do, thing}}
      ["quit"] -> {:ok, :quit}
      ["xterm256"] -> {:ok, :xterm256}
      ["truecolor"] -> {:ok, :truecolor}
      _ -> {:error, :unknown_command}
    end
  end


  def run({:do, thing}) do
    {:ok, thing <> " was done"}
  end

  def run(:quit) do
    raise Zung.Error.ConnectionClosed, message: "Player logged out."
  end

  def run(:xterm256) do
    {:ok, do_xterm256(0, 0, "") <> "||RESET||"}
  end

  def run(:truecolor) do
    {:ok, do_truecolor(0, 0, 0, 0, 0, 0, "") <> "||RESET||"}
  end

  def run(_command) do
    {:ok, "Ok"}
  end

  defp do_xterm256(256, _front_color, current), do: current
  defp do_xterm256(back_color, 256, current), do: do_xterm256(back_color + 1, 0, current)
  defp do_xterm256(back_color, front_color, current), do: do_xterm256(back_color, front_color + 1, current <> "\e[48;5;#{back_color}m\e[38;5;#{front_color}m@")


  defp do_truecolor(256, _, _, _, _, _, current), do: current
  defp do_truecolor(br, 256, _, _, _, _, current), do: do_truecolor(br + 1, 0, 0, 0, 0, 0, current)
  defp do_truecolor(br, bg, 256, _, _, _, current), do: do_truecolor(br, bg + 1, 0, 0, 0, 0, current)
  defp do_truecolor(br, bg, bb, 256, _, _, current), do: do_truecolor(br, bg, bb + 1, 0, 0, 0, current)
  defp do_truecolor(br, bg, bb, fr, 256, _, current), do: do_truecolor(br, bg, bb, fr + 1, 0, 0, current)
  defp do_truecolor(br, bg, bb, fr, fg, 256, current), do: do_truecolor(br, bg, bb, fr, fg + 1, 0, current)
  defp do_truecolor(br, bg, bb, fr, fg, fb, current) do
    do_truecolor(br, bg, bb, fr, fg, fb + 1, current <> "\e[48;2;#{br};#{bg};#{bb}m\e[38;2;#{fr};#{fg};#{fb}m@")
  end
end
