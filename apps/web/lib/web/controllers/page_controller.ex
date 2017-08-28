defmodule Web.PageController do
  use Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end

  def login(conn, _params) do
    render conn, "login.html"
  end

  def host_information(conn, _params) do
    json conn, Amorphos.get_host_information
  end
end
