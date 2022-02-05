defmodule Rem.Sessions.ServerTest do
  use ExUnit.Case, async: true

  alias Rem.Sessions.Server

  describe "new/1" do
    test "starts a new session" do
      on_timeout = fn -> :on_timeout_fn end
      opts = [
        value:      :value,
        handler:    __MODULE__,
        timeout:    100_000,
        on_timeout: on_timeout
      ]
      assert {:ok, pid} = Server.new(make_ref(), opts)
      assert Process.alive?(pid)

      state = :sys.get_state(pid)

      assert state.value         == :value
      assert state.handler       == __MODULE__
      assert state.timeout       == 100_000
      assert state.on_timeout.() == :on_timeout_fn

      Process.exit(pid, :kill)
    end

    test "returns an error if server already exists" do
      session_id = make_ref()
      {:ok, pid} = Server.new(session_id)

      assert {:error, {:already_started, npid}} = Server.new(session_id)
      assert pid == npid

      Process.exit(pid, :kill)
    end
  end

  describe "get/1" do
    test "returns {:ok value} w/the 'value' attribute of the state" do
      session_id = make_ref()
      {:ok, pid} = Server.new(session_id, value: :state_value)

      assert {:ok, :state_value} == Server.get(session_id)

      Process.exit(pid, :kill)
    end

    test "returns an error if session does not exist" do
      assert {:error, :no_session} = Server.get(make_ref())
    end
  end

  describe "get_handler/1" do
    test "returns {:ok, handler} w/the 'handler' attribute of the state" do
      session_id = make_ref()
      {:ok, pid} = Server.new(session_id, handler: __MODULE__)

      assert {:ok, __MODULE__} == Server.get_handler(session_id)

      Process.exit(pid, :kill)
    end

    test "returns an error if session does not exist" do
      assert {:error, :no_session} = Server.get_handler(make_ref())
    end
  end

  describe "set/2" do
    test "returns {:ok, new_value} and sets the 'value' attribute of the state" do
      session_id = make_ref()
      {:ok, pid} = Server.new(session_id, value: :old_value)

      assert {:ok, :new_value} == Server.set(session_id, :new_value)

      state = :sys.get_state(pid)
      assert state.value == :new_value

      Process.exit(pid, :kill)
    end

    test "returns an error if session does not exist" do
      assert {:error, :no_session} = Server.set(make_ref(), :new_value)
    end
  end

  describe "kill/1" do
    test "kills the process" do
      session_id = make_ref()
      {:ok, pid} = Server.new(session_id)

      assert :ok = Server.kill(session_id)

      # 10ms is typically enough for the process to shutdown
      Process.sleep(10)
      refute Process.alive?(pid)
    end

    test "returns no error even if the process does not exist" do
      assert :ok = Server.kill(make_ref())
    end
  end

  describe "server times out" do
    test "calls the received on_timeout function after the timeout" do
      test_pid   = self()
      on_timeout = fn -> send(test_pid, :am_ded) end
      {:ok, pid} = Server.new(make_ref(), on_timeout: on_timeout, timeout: 0)

      assert_receive :am_ded
      refute Process.alive?(pid)
    end

    test "is able to handle errors in the on_timeout function" do
      on_timeout = fn -> raise "Onoz" end
      {:ok, pid} = Server.new(make_ref(), on_timeout: on_timeout, timeout: 0)

      # 10ms is typically enough for the process to shutdown
      Process.sleep(10)
      refute Process.alive?(pid)
    end
  end
end
