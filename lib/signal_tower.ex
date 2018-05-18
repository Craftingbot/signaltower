defmodule SignalTower do
  use Application
  import Supervisor.Spec, warn: false

  def start(_type, _args) do

    start_cowboy()
    |> start_supervisor()
  end

  def stop(_state) do
    :ok
  end

  defp start_cowboy() do
    {port, _} = Integer.parse("4233")

    dispatch = :cowboy_router.compile([
      {:_, [
        {"/[...]", SignalTower.WebsocketHandler, []}
      ]}
    ])

    {port, dispatch}
  end

  defp start_supervisor({port, dispatch}) do
    children = [
      supervisor(SignalTower.RoomSupervisor, []),
      worker(:cowboy, [:web, [port: port], %{env: %{dispatch: dispatch}}], function: :start_clear)
    ]
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
