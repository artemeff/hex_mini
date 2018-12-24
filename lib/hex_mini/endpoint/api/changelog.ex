defmodule HexMini.Endpoint.API.Changelog do
  import HexMini.Endpoint.API

  def init(_), do: []

  def call(conn, _opts) do
    conn
    |> respond_text_lazy(&render_html/1)
    |> respond(200, render(HexMini.Packages.changelog))
  end

  defp render(changelog) do
    Enum.map(changelog, fn(c) ->
      %{name: c.package.name, version: c.release.version, action: c.action,
        user: c.release.owner, date: NaiveDateTime.truncate(c.release.inserted_at, :second)}
    end)
  end

  defp render_html(changelog) do
    Enum.reduce(changelog, "", fn(%{name: name, version: version, action: action, user: user, date: date}, acc) ->
      acc <> """
      #{name} #{version} #{action}
        at #{date}
        by #{user}

      """
    end)
  end
end
