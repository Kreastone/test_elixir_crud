defmodule KVstore do
  use Application
  @moduledoc """
  Simple KV Storage
  """
  def start(_type, _args) do
    children = [
      Supervisor.Spec.worker(Storage, [], name: WorkerStorage),
      Plug.Adapters.Cowboy.child_spec(:http, Router, [], port: 8080)
    ]
    opts = [strategy: :one_for_one, name: Sample.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
