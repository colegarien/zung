defmodule Zung.SessionTest do
  use ExUnit.Case, async: true
  alias Zung.Session.State

  defp get_now(), do: :os.system_time(:millisecond)

  test "state - fresh session is not active" do
    # Arrange
    session = State.new

    # Act
    actual = State.is_active?(session)

    # Assert
    assert false === actual
  end

  test "state - closed session is not active" do
    # Arrange
    session = %State{State.new |
      is_authenticated: true,
      is_disconnected: false,
    }

    # Act
    closed_session = State.close(session)
    actual = State.is_active?(closed_session)

    # Assert
    assert false === actual
  end

  test "state - session expire a few seconds ago" do
    # Arrange
    session = %State{State.new |
      timeout: 1000,
      is_authenticated: true,
      is_disconnected: false,
      last_activity: get_now() - 5000,
    }

    # Act
    actual = State.is_expired?(session)

    # Assert
    assert true === actual
  end

  test "state - refreshed session is not expired" do
    # Arrange
    session = %State{State.new |
      timeout: 1000,
      is_authenticated: true,
      is_disconnected: false,
      last_activity: get_now() - 5000,
    }

    # Act
    refreshed_session = State.refresh(session)
    actual = State.is_expired?(refreshed_session)

    # Assert
    assert false === actual
  end

  test "state - session will expire in a few seconds ago" do
    # Arrange
    session = %State{State.new |
      timeout: 10000,
      is_authenticated: true,
      is_disconnected: false,
      last_activity: get_now() - 5000,
    }

    # Act
    actual = State.is_expired?(session)

    # Assert
    assert false === actual
  end


  test "new sessions have unique ids" do
    # Arrange
    current_state = %{
      1 => State.new,
      2 => State.new,
    }

    # Act
    {_, actual, _} = Zung.Session.handle_call({:new, State.new}, nil, current_state)

    # Assert
    assert 3 === actual
  end

  test "new sessions with gap in old sessions" do
    # Arrange
    current_state = %{
      1 => State.new,
      5 => State.new,
    }

    # Act
    {_, actual, _} = Zung.Session.handle_call({:new, State.new}, nil, current_state)

    # Assert
    assert 6 === actual
  end

  test "new sessions unordered gap" do
    # Arrange
    current_state = %{
      5 => State.new,
      1 => State.new,
    }

    # Act
    {_, actual, _} = Zung.Session.handle_call({:new, State.new}, nil, current_state)

    # Assert
    assert 6 === actual
  end


  test "cleanup - no session to remove" do
    # Arrange
    current_state = %{}

    # Act
    actual = Zung.Session.remove_inactive_sessions(current_state)

    # Assert
    assert %{} === actual
  end

  test "cleanup - one session to remove" do
    # Arrange
    current_state = %{
      3 => %State{State.new | is_disconnected: true}
    }

    # Act
    actual = Zung.Session.remove_inactive_sessions(current_state)

    # Assert
    assert %{} === actual
  end

  test "cleanup - multiple sessions to remove" do
    # Arrange
    current_state = %{
      3 => %State{State.new | is_disconnected: true},
      5 => %State{State.new | is_disconnected: true},
      7 => %State{State.new | is_disconnected: true}
    }

    # Act
    actual = Zung.Session.remove_inactive_sessions(current_state)

    # Assert
    assert %{} === actual
  end

  test "cleanup - multiple sessions to remove some leftover" do
    # Arrange
    current_state = %{
      3 => %State{State.new | is_disconnected: true},
      5 => %State{State.new | is_disconnected: true},
      9 => %State{State.new | is_disconnected: false},
      7 => %State{State.new | is_disconnected: true}
    }

    # Act
    actual = Zung.Session.remove_inactive_sessions(current_state)

    # Assert
    assert %{} === actual
  end


  test "expire - no sessions" do
    # Arrange
    current_state = %{}

    # Act
    actual = Zung.Session.close_expired_sessions(current_state)

    # Assert
    assert %{} === actual
  end

  test "expire - one expired session" do
    # Arrange
    current_state = %{
      1 => %State{State.new |
        timeout: 1000,
        is_authenticated: true,
        is_disconnected: false,
        last_activity: get_now() - 5000,
      }
    }

    # Act
    actual = Zung.Session.close_expired_sessions(current_state)

    # Assert
    assert false === actual[1].is_authenticated
    assert true === actual[1].is_disconnected
  end

  test "expire - one expired session one non expired" do
    # Arrange
    current_state = %{
      1 => %State{State.new |
        timeout: 1000,
        is_authenticated: true,
        is_disconnected: false,
        last_activity: get_now() - 5000,
      },
      3 =>  %State{State.new |
        timeout: 1000,
        is_authenticated: true,
        is_disconnected: false,
        last_activity: get_now(),
      },
    }

    # Act
    actual = Zung.Session.close_expired_sessions(current_state)

    # Assert
    assert false === actual[1].is_authenticated
    assert true === actual[1].is_disconnected

    assert true === actual[3].is_authenticated
    assert false === actual[3].is_disconnected
  end

end
