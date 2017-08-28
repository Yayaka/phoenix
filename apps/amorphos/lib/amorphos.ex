defmodule Amorphos do
  @host Application.get_env(:web, Web.Endpoint)[:url][:host]
  @port Application.get_env(:web, Web.Endpoint)[:http][:port]
  @information Application.get_env(:amorphos, :host_information)

  def get_host do
    if is_nil(@port) do
      @host
    else
      "#{@host}:#{@port}"
    end
  end

  def get_host_information do
    @information
  end
end
