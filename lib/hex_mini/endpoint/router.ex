defmodule HexMini.Endpoint.Router do
  use Plug.Router

  alias HexMini.Endpoint.{API, Repo}

  plug HexMini.Endpoint.Plugs.Authorization, except: [{"GET", "/public_key"}]
  plug :match
  plug :dispatch

  # HexMini endpoints

  get "/", to: API.Changelog

  # Hex Repo endpoints

  get "/public_key", to: Repo.PublicKey
  get "/packages/:name", to: Repo.Package
  get "/tarballs/:name_with_version", to: Repo.Tarball

  post "/publish", to: Repo.Publish

  match _ do
    send_resp(conn, 404, "not found")
  end
end
