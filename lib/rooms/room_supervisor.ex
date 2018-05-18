require Logger
defmodule SignalTower.RoomSupervisor do
  use Supervisor

  alias SignalTower.RoomSupervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: RoomSupervisor)
  end

  def get_room(room_id) do
    case Supervisor.start_child(RoomSupervisor, [room_id]) do
      {:ok, pid} ->
        Logger.debug("start a new room for #{room_id}")
        pid
      {:error, {:already_started, pid}} -> pid
    end
  end

  def init(:ok) do
    children = [
      worker(SignalTower.Room, [], restart: :transient)
    ]
    supervise(children, strategy: :simple_one_for_one)
  end
end
