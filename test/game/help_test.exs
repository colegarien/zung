defmodule Zung.Game.HelpTest do
  use ExUnit.Case, async: true

  alias Zung.Game.Help

  test "list_commands includes all command names" do
    output = Help.list_commands()
    assert output =~ "look"
    assert output =~ "help"
    assert output =~ "quit"
    assert output =~ "who"
    assert output =~ "get"
    assert output =~ "drop"
    assert output =~ "inventory"
    assert output =~ "examine"
    assert output =~ "say"
    assert output =~ "enter"
    assert output =~ "north"
  end

  test "list_commands includes header" do
    output = Help.list_commands()
    assert output =~ "Available Commands:"
  end

  test "describe_command for a known command" do
    output = Help.describe_command("look")
    assert output =~ "look"
    assert output =~ "Usage:"
    assert output =~ "look [target]"
  end

  test "describe_command for another known command" do
    output = Help.describe_command("get")
    assert output =~ "get"
    assert output =~ "Usage:"
    assert output =~ "get <item>"
  end

  test "describe_command for an unknown command" do
    output = Help.describe_command("nonexistent")
    assert output =~ "Unknown command"
    assert output =~ "nonexistent"
  end
end
