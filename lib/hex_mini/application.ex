defmodule HexMini.Application do
  use Application

  def start(_type, _args) do
    children = cleanup_child([
      {HexMini.Repo, []},

      spec_if(HexMini.start_endpoint?, {HexMini.Endpoint, [port: 4000]}),
    ])

    opts = [strategy: :one_for_one, name: HexMini.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp spec_if(true, child), do: child
  defp spec_if(_, _), do: :ignore

  defp cleanup_child(childs) do
    Enum.filter(childs, fn(child) -> child != :ignore end)
  end
end
