defmodule Amorphos do
  @host Application.get_env(:web, Web.Endpoint)[:url][:host]
  @port Application.get_env(:web, Web.Endpoint)[:http][:port]

  def get_host do
    if is_nil(@port) do
      @host
    else
      "#{@host}:#{@port}"
    end
  end
end
