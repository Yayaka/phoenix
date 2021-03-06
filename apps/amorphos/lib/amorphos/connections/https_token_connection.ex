defmodule Amorphos.HTTPSTokenConnection do
  @behaviour Amorphos.Connection

  defstruct [:host_information, :token, :expires]

  if Mix.env in [:test, :dev] do
    @timeout 100
    @scheme "http"
  else
    @timeout 5000
    @scheme "https"
  end

  @impl Amorphos.Connection
  def expires?(connection) do
    expires = connection.expires
    now = DateTime.utc_now() |> DateTime.to_unix()
    expires <= now
  end

  @impl Amorphos.Connection
  def validate(connection_protocol) do
    parameters = connection_protocol.parameters
    request_path = Map.get(parameters, "request-path")
    grant_path = Map.get(parameters, "grant-path")
    packet_path = Map.get(parameters, "packet-path")
    is_binary(request_path)
    and is_binary(grant_path)
    and is_binary(packet_path)
    and String.length(request_path) >= 1
    and String.length(grant_path) >= 1
    and String.length(packet_path) >= 1
  end

  @impl Amorphos.Connection
  def connect(host_information) do
    sender_host = Amorphos.get_host()
    host = host_information.host
    https_token = host_information.connection_protocols
                   |> Enum.find(fn struct ->
                     struct.name == "https-token"
                   end)
    request_path = https_token.parameters["request-path"]
    state = SecureRandom.uuid
    Registry.register(__MODULE__, host, %{state: state})
    body = %{
      "host" => sender_host,
      "state" => state
    } |> Poison.encode!()
    headers = [{"Content-Type", "application/json"}]
    Amorphos.HTTP.post("#{@scheme}://#{host}#{request_path}", body, headers)
    receive do
      {:grant, map} ->
        %{"host" => _host,
          "token" => token,
          "expires" => expires,
          "state" => _state} = map
        {:ok, %__MODULE__{host_information: host_information,
          token: token,
          expires: expires}}
    after
      @timeout ->
        {:error, "timeout"}
    end
  end

  @impl Amorphos.Connection
  def send_packet(connection, messages) do
    host = connection.host_information.host
    token = connection.token
    https_token = connection.host_information.connection_protocols
                   |> Enum.find(fn struct ->
                     struct.name == "https-token"
                   end)
    packet_path = https_token.parameters["packet-path"]
    url = "#{@scheme}://#{host}#{packet_path}"
    body = %{
      "packet" => %{
        "messages" => messages
      }
    } |> Poison.encode!()
    headers = [{"Content-Type", "application/json"},
               {"Authorization", "Bearer #{token}"}]
    case Amorphos.HTTP.post(url, body, headers) do
      {:ok, response} ->
        case response.status_code do
          204 -> :ok
          status -> {:error, status}
        end
      _ -> :error
    end
  end

  def handle_request(map) do
    %{"host" => host, "state" => state} = map
    {:ok, host_information} =
      Amorphos.HostInformationProvider.request(host)
    https_token = host_information.connection_protocols
                  |> Enum.find(fn struct ->
                    struct.name == "https-token"
                  end)
    grant_path = https_token.parameters["grant-path"]
    resource = %{host: host}
    {:ok, token, claims} = Guardian.encode_and_sign(resource)
    expires = Map.get(claims, "exp")
    body = %{
      "host" => Amorphos.get_host(),
      "token" => token,
      "expires" => expires,
      "state" => state
    } |> Poison.encode!()
    headers = [{"Content-Type", "application/json"}]
    Amorphos.HTTP.post("#{@scheme}://#{host}#{grant_path}", body, headers)
    :ok
  end

  def handle_grant(map) do
    host = map["host"]
    case Registry.lookup(__MODULE__, host) do
      [{pid, %{state: state}}] ->
        if state == map["state"] do
          send pid, {:grant, map}
          :ok
        else
          :error
        end
      _ ->
        :error
    end
  end

  def handle_packet(resource, packet) do
    myhost = Amorphos.get_host()
    with %{"host" => host} <- resource,
         %{"messages" => messages} <- packet do
      for message <- messages do
        if message["host"] == myhost and message["sender"]["host"] == host do
          Amorphos.MessageGateway.push(message)
        end
      end
      :ok
    else
      _ -> :error
    end
  end
end
