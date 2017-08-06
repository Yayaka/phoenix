defmodule YMP.TestConnection do
  @behaviour YMP.MessageHandler
  def start_link() do
    Registry.start_link(:duplicate, __MODULE__)
  end
  def register(host) do
    Registry.register(__MODULE__, host, :ok)
  end
  # Callback
  @behaviour YMP.Connection
  defstruct [:host]
  def connect(host_information) do
    {:ok, %__MODULE__{host: host_information.host}}
  end
  def send_packet(connection, messages) do
    host = connection.host
    Registry.dispatch(__MODULE__, host, fn entries ->
      for {pid, :ok} <- entries do
        send pid, messages
      end
    end)
    Registry.unregister(__MODULE__, host)
    :ok
  end
  def validate(%YMP.HostInformation.ConnectionProtocol{}), do: true
  def check_expired(connection), do: false
end
