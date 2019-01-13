defmodule HexMini.Endpoint.API.Changelog do
  import HexMini.Endpoint.API

  alias HexMini.Packages.{Changelog, Release}

  def init(_), do: []

  def call(conn, _opts) do
    conn
    |> respond_text_lazy(&render_html/1)
    |> respond(200, render(HexMini.Packages.changelog))
  end

  defp render(changelog) do
    Enum.map(changelog, fn(%Changelog{} = c) ->
      %{name: c.package.name, user: c.user, action: render_action(c),
        date: NaiveDateTime.truncate(c.inserted_at, :second)}
    end)
  end

  defp render_action(%Changelog{action: "publish", release: %Release{} = r} = c) do
    "publish #{c.package.name} #{r.version}"
  end
  defp render_action(%Changelog{action: "owner_add"} = c) do
    "add owner #{Map.fetch!(c.meta, "user")} to #{c.package.name}"
  end
  defp render_action(%Changelog{action: "owner_delete"} = c) do
    "delete owner #{Map.fetch!(c.meta, "user")} from #{c.package.name}"
  end

  defp render_html(changelog) do
    Enum.reduce(changelog, "", fn(%{name: name, action: action, user: user, date: date}, acc) ->
      acc <> """
      #{action}
        at #{date}
        by #{user}

      """
    end)
  end
end
