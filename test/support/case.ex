defmodule HexMini.Case do
  use ExUnit.CaseTemplate

  alias Ecto.Adapters.SQL.Sandbox

  using do
    quote do
      import Ecto.Query
      import ExUnit.CaptureLog
      import HexMini.Factory
      import HexMini.Case.Endpoint
    end
  end

  setup tags do
    :ok = Sandbox.checkout(HexMini.Repo)

    unless tags[:async] do
      Sandbox.mode(HexMini.Repo, {:shared, self()})
    end

    # FIXME get rid of sqlite or `{busy,0}` messages
    on_exit(fn -> :timer.sleep(50) end)
  end

  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn({message, opts}) ->
      Enum.reduce(opts, message, fn({key, value}, acc) ->
        String.replace(acc, "%{#{key}}", inspect(value))
      end)
    end)
  end
end
