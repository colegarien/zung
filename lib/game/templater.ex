defmodule Zung.Game.Templater do
  @templating_regex ~r/\|\|([A-Z_]+)?\|\|/ # ||TEMPLATE_WORD_HERE||
  @primitive_templating_replacements %{
    "NL" => "\r\n",
    "ECHO_OFF" => <<255, 251, 1>>,
    "ECHO_ON" => <<255, 252, 1>>,
  }
  @ansi_templating_replacements %{
    "NL" => "\r\n",
    "RESET" => "\e[0m",
    "BOLD" => "\e[1m",
    "ITALIC" => "\e[3m",
    "UNDERLINE" => "\e[4m",
    "BLINK_SLOW" => "\e[5m",
    "BLINK_FAST" => "\e[6m",
    "INVERT" => "\e[7m",
    "BLK" => "\e[30m",
    "RED" => "\e[31m",
    "GRN" => "\e[32m",
    "YEL" => "\e[33m",
    "BLU" => "\e[34m",
    "MAG" => "\e[35m",
    "CYA" => "\e[36m",
    "WHT" => "\e[37m",
    "BLK_BK" => "\e[40m",
    "RED_BK" => "\e[41m",
    "GRN_BK" => "\e[42m",
    "YEL_BK" => "\e[43m",
    "BLU_BK" => "\e[44m",
    "MAG_BK" => "\e[45m",
    "CYA_BK" => "\e[46m",
    "WHT_BK" => "\e[47m",
    "ECHO_OFF" => <<255, 251, 1>>,
    "ECHO_ON" => <<255, 252, 1>>,
  }

  def template(text, use_ansi?) do
    replacements = if use_ansi?, do: @ansi_templating_replacements, else: @primitive_templating_replacements
    Regex.replace(@templating_regex, text, fn _, match ->
      if Map.has_key?(replacements, match), do: replacements[match], else: ""
    end)
  end
end
