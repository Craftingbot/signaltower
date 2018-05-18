defmodule SignalTower.WebsocketHandler do
  @behaviour :cowboy_websocket_handler
  require Logger
  alias SignalTower.Session

  def init(req, _) do
    {:cowboy_websocket, req, nil}
  end

  def websocket_init(state) do
    {:ok, state}
  end


  ## accept frames from client

  def websocket_handle({:text, msg}, room) do
    case Poison.decode(msg) do
      {:ok, parsed_msg} ->
        {:ok, Session.handle_message(parsed_msg, room)}
      _ ->
        answer = Poison.encode!(%{event: "error", description: "invalid json", received_msg: msg})
        {:reply, {:text, answer}, room}
    end
  end

  def websocket_handle(msg, state) do
    Logger.warn "Unknown message: #{inspect(msg)}"
    {:ok, state}
  end


  ## accept action on server side and send result to client if needed 

  def websocket_info({:DOWN,_,_,pid,_}, room) do
    Logger.debug "websocket connect is DOWN for #{inspect(pid)}"
    {:noreply, Session.handle_exit_message(pid, room)}
  end

  def websocket_info({:to_user, msg}, state) do
    {:reply, {:text, internal_to_json(msg)}, state}
  end

  def websocket_info({:internal_error, msg}, state) do
    Logger.warn "cowboy error: #{inspect(msg)}"
    #{:ok, reply} = Palava.handle_server_error(msg)
    {:reply, {:text, "{\"event\": \"error\", \"message\": \"Internal Error: #{msg}\"}"}, state}
  end


  ## websocket terminate, here we just show some debug info, we really dont have
  #to define them

  def terminate({:remote, close_code, msg}, _req, state) do
    Logger.debug("client removed with code#{close_code}")
  end

  def terminate(:remote, _req, state) do
    Logger.debug("client removed")
  end

  def terminate(:timeout, _req, state) do
    Logger.debug("ws timeout #{inspect(self())}")
  end

  def terminate(reason, req, state) do
    Logger.debug("ws terminate, #{inspect([reason, req, state])}")
  end

  defp internal_to_json(msg) do
    case Poison.encode(msg) do
      {:ok, msg_json} ->
        msg_json
      _ ->
        Logger.error "Sending message: Could not transform internal object to JSON: #{inspect(msg)}"
        error_msg = Poison.encode! %{event: "error", message: "internal_server_error"}
        error_msg
    end
  end
end
