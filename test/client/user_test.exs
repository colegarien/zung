defmodule Zung.Client.UserTest do
  use ExUnit.Case, async: true
  alias Zung.Client.User.State

  defp get_now(), do: :os.system_time(:millisecond)


  test "user - log login updates the last_login" do
    # Arrange
    user = %State{State.new |
      last_login: get_now() - 5000
    }

    # Act
    actual = State.log_login(user)

    # Assert
    assert user.last_login < actual.last_login
  end

  test "user - dont set fake settings" do
    # Arrange
    user = State.new

    # Act
    actual = State.set_setting(user, :some_nonsense, "no go")

    # Assert
    assert not Map.has_key?(actual.settings, :some_nonsense)
  end

  test "user - do set real settings" do
    # Arrange
    user = %State{State.new |
      settings: %{
        use_ansi?: false
      }
    }

    # Act
    actual = State.set_setting(user, :use_ansi?, true)

    # Assert
    assert actual.settings[:use_ansi?] === true
  end

  test "user - return nil for fake settings" do
    # Arrange
    user = State.new

    # Act
    actual = State.get_setting(user, :some_nonsense)

    # Assert
    assert actual === nil
  end

  test "user - return value for settings" do
    # Arrange
    user = %State{State.new |
      settings: %{
        use_ansi?: true
      }
    }

    # Act
    actual = State.get_setting(user, :use_ansi?)

    # Assert
    assert actual === true
  end

end
