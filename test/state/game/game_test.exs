defmodule Zung.State.Game.GameTest do
  use ExUnit.Case, async: true
  use MecksUnit.Case

  alias Zung.State.Game.Game

  defmock Zung.Client, preserve: true do
    def new(_socket) do
      %Zung.Client {
        session_id: 1234,
        connection_id: 5678,
      }
    end

    def flush_output(%Zung.Client{} = client) do
      # don't actually flush output so we can pick at it during testing
      client
    end
  end

  mocked_test "no input do nothing loop" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil) |
      game_state: %Zung.Client.GameState{ username: "tim_allen" },
    }

    # Act
    actual_client = Game.do_game(client)

    # Assert
    assert actual_client.session_id === 1234
    assert actual_client.connection_id === 5678
    assert actual_client.game_state.username === "tim_allen"
  end

  mocked_test "garbage input" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil) |
      game_state: %Zung.Client.GameState{ username: "tim_allen" },
      input_buffer: :queue.in("ladwijlaiwjd awkod awdj\n" , :queue.new),
    }

    # Act
    actual_client = Game.do_game(client)

    # Assert
    assert :queue.is_empty(actual_client.input_buffer)
    assert not :queue.is_empty(actual_client.output_buffer)
    {:value, actual_output } = :queue.peek(actual_client.output_buffer)
    assert actual_output === "||GRN||Wut?||RESET||"
  end

  mocked_test "simple look command" do
    # Arrange
    client = %Zung.Client{
      Zung.Client.new(nil) |
      game_state: %Zung.Client.GameState{ username: "tim_allen" },
      input_buffer: :queue.in("look\n" , :queue.new),
    }

    # Act
    actual_client = Game.do_game(client)

    # Assert
    assert :queue.is_empty(actual_client.input_buffer)
    assert not :queue.is_empty(actual_client.output_buffer)
    {:value, actual_output } = :queue.peek(actual_client.output_buffer)
    assert actual_output === """
||BOLD||||GRN||The Test Room||RESET||
    A simple test room for testing units
||BOLD||||CYA||-{ Exits: north }-||RESET||

"""
  end
end
