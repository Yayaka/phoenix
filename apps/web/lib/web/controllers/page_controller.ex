defmodule Web.PageController do
  use Web, :controller
  alias YayakaPresentation.User

  def index(conn, _params) do
    render conn, "index.html"
  end

  def login(conn, _params) do
    render conn, "login.html"
  end
end
