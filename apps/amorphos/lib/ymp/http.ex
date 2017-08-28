defmodule Amorphos.HTTP do
  def get(url, body \\ "", headers \\ []) do
    {:request, [:get, url, body, headers]}
    |> Honeydew.async(:http, reply: true)
    |> Honeydew.yield
  end

  def post(url, body, headers) do
    {:request, [:post, url, body, headers]}
    |> Honeydew.async(:http, reply: true)
    |> Honeydew.yield
  end

  def request(method, url, body, headers) do
    HTTPoison.request!(method, url, body, headers)
  end
end
