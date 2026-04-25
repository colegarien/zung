defmodule Zung.NewbieWalkthroughTest do
  use ExUnit.Case
  @moduletag :capture_log

  setup do
    Application.stop(:zung)
    :ok = Application.start(:zung)
  end

  test "newbie area: two-player full command walkthrough" do
    alice = TestClient.connect()
    assert TestClient.login_new(alice, "alice_wt", "Testpass1!") =~ "Brig"

    bob = TestClient.connect()
    assert TestClient.login_new(bob, "bob_wt", "Testpass1!") =~ "Brig"

    # ----------------------------------------------------------------
    # Phase A — Brig, alice solo
    # ----------------------------------------------------------------

    # look / examine flavor text
    assert TestClient.send_and_recv(alice, "look") =~ "Brig"
    assert TestClient.send_and_recv(alice, "look scratchings") =~ "2021-01-08"
    assert TestClient.send_and_recv(alice, "examine scratchings") =~ "2021-01-08"
    assert TestClient.send_and_recv(alice, "look north") =~ "exit"
    assert TestClient.send_and_recv(alice, "look water pipe") =~ "water pipe"

    # basic commands
    assert TestClient.send_and_recv(alice, "inventory") =~ "not carrying"
    assert TestClient.send_and_recv(alice, "help") =~ "Available Commands"
    assert TestClient.send_and_recv(alice, "help look") =~ "look"

    who_out = TestClient.send_and_recv(alice, "who")
    assert who_out =~ "alice_wt"
    assert who_out =~ "bob_wt"

    assert TestClient.send_and_recv(alice, "score") =~ "alice_wt"

    where_out = TestClient.send_and_recv(alice, "where")
    assert where_out =~ "alice_wt"
    assert where_out =~ "Brig"

    # settings / brief toggle
    assert TestClient.send_and_recv(alice, "settings") =~ "ansi"
    assert TestClient.send_and_recv(alice, "set brief on") =~ "Brief mode is now on"
    assert TestClient.send_and_recv(alice, "brief") =~ "Brief mode is now off"
    settings_out = TestClient.send_and_recv(alice, "settings")
    assert settings_out =~ "brief"
    assert settings_out =~ "off"

    # alias / unalias (move north then south to restore position)
    assert TestClient.send_and_recv(alice, "alias gn north") =~ "Alias set"
    assert TestClient.send_and_recv(alice, "gn") =~ "Lower Deck"
    assert TestClient.send_and_recv(alice, "unalias gn") =~ "Alias removed"
    assert TestClient.send_and_recv(alice, "gn") =~ "Wut"
    assert TestClient.send_and_recv(alice, "south") =~ "Brig"

    # search (Brig has no search_text)
    assert TestClient.send_and_recv(alice, "search") =~ "nothing"

    # negative-path: graceful errors, no crashes
    assert TestClient.send_and_recv(alice, "get plank") =~ "don't see"
    assert TestClient.send_and_recv(alice, "drop anything") =~ "don't have"
    # scratchings is a flavor text, not an object → can't read/use
    assert TestClient.send_and_recv(alice, "read scratchings") =~ "don't see"
    assert TestClient.send_and_recv(alice, "use scratchings") =~ "don't see"
    # north exit defaults to :open
    assert TestClient.send_and_recv(alice, "open north") =~ "already open"
    assert TestClient.send_and_recv(alice, "close north") =~ "close it"
    # restore
    assert TestClient.send_and_recv(alice, "open north") =~ "open it"
    assert TestClient.send_and_recv(alice, "lock north") =~ "close it first"
    assert TestClient.send_and_recv(alice, "unlock north") =~ "already open"
    # no NPCs in Brig
    assert TestClient.send_and_recv(alice, "talk guard") =~ "don't see anyone"
    assert TestClient.send_and_recv(alice, "ask guard about ship") =~ "don't see anyone"
    # connection still alive after negative-path barrage
    assert TestClient.send_and_recv(alice, "look") =~ "Brig"

    # ----------------------------------------------------------------
    # Phase B — named-exit traversal (alice in Brig)
    # ----------------------------------------------------------------

    assert TestClient.send_and_recv(alice, "enter water pipe") =~ "Main Deck"
    assert TestClient.send_and_recv(alice, "look") =~ "Main Deck"
    assert TestClient.send_and_recv(alice, "down") =~ "Lower Deck"

    # objects in Lower Deck
    assert TestClient.send_and_recv(alice, "look planks") =~ "old wooden planks"

    assert TestClient.send_and_recv(alice, "examine another stack of planks") =~
             "Another big stack"

    # planks are not takeable
    assert TestClient.send_and_recv(alice, "get planks") =~ "can't take"

    # ----------------------------------------------------------------
    # Phase C — bob joins alice in Lower Deck
    # ----------------------------------------------------------------

    assert TestClient.send_and_recv(bob, "north") =~ "Lower Deck"

    # drain both sockets (no arrival broadcast exists, just clear buffers)
    TestClient.drain(alice)
    TestClient.drain(bob)

    # confirm both in Lower Deck
    assert TestClient.send_and_recv(alice, "look") =~ "Lower Deck"
    assert TestClient.send_and_recv(bob, "look") =~ "Lower Deck"

    # ----------------------------------------------------------------
    # Phase D — social commands (both in Lower Deck)
    # ----------------------------------------------------------------

    # say
    assert TestClient.send_and_recv(alice, "say hello bob") =~ "You say"
    assert TestClient.drain(bob) =~ "hello bob"

    # ooc (default alias: ooc → csay ooc)
    assert TestClient.send_and_recv(bob, "ooc howdy") =~ "OOC"
    assert TestClient.drain(alice) =~ "OOC"

    # emote (custom action)
    assert TestClient.send_and_recv(alice, "emote waves hello") =~ "waves hello"
    assert TestClient.drain(bob) =~ "alice_wt waves hello"

    # me (alias for emote)
    assert TestClient.send_and_recv(alice, "me nods knowingly") =~ "nods knowingly"
    assert TestClient.drain(bob) =~ "alice_wt nods knowingly"

    # canned emotes — batch alice's sends, then single drain for bob
    TestClient.send_and_recv(alice, "bow")
    TestClient.send_and_recv(alice, "wave")
    TestClient.send_and_recv(alice, "nod")
    TestClient.send_and_recv(alice, "shrug")
    bob_canned = TestClient.drain(bob)
    assert bob_canned =~ "bows gracefully"
    assert bob_canned =~ "waves"
    assert bob_canned =~ "nods"
    assert bob_canned =~ "shrugs"

    # shout (local)
    TestClient.send_and_recv(alice, "shout ahoy")
    assert TestClient.drain(bob) =~ "ahoy"

    # yell (alias of shout)
    TestClient.send_and_recv(alice, "yell ahoy there")
    assert TestClient.drain(bob) =~ "ahoy there"

    # whisper — sender and target both see it via room pubsub
    alice_whisper = TestClient.send_and_recv(alice, "whisper bob_wt psst")
    assert alice_whisper =~ "You whisper to bob_wt"
    assert TestClient.drain(bob) =~ "psst"

    # tell — direct push to alice + player-channel pubsub for bob
    assert TestClient.send_and_recv(alice, "tell bob_wt secret msg") =~ "You tell bob_wt"
    assert TestClient.drain(bob) =~ "secret msg"

    # give — alice has no inventory, expect bad-parse
    assert TestClient.send_and_recv(alice, "give planks bob_wt") =~ "don't have"

    # lead
    assert TestClient.send_and_recv(alice, "lead") =~ "following you will move"

    # follow — bob follows alice, then alice moves up
    assert TestClient.send_and_recv(bob, "follow alice_wt") =~ "begin following"
    assert TestClient.send_and_recv(alice, "up") =~ "Main Deck"
    bob_follow = TestClient.drain(bob)
    assert bob_follow =~ "You follow alice_wt"

    # confirm bob auto-moved to Main Deck
    assert TestClient.send_and_recv(bob, "look") =~ "Main Deck"

    # bob stops following
    assert TestClient.send_and_recv(bob, "follow") =~ "stop following"

    # ----------------------------------------------------------------
    # Phase E — teardown
    # ----------------------------------------------------------------

    assert TestClient.send_and_recv(bob, "quit") =~ "Bye"
    assert TestClient.send_and_recv(alice, "quit") =~ "Bye"
  end
end
