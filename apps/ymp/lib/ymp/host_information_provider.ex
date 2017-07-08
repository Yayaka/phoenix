defmodule YMP.HostInformationProvider do
  def get(host) do
    case DB.Repo.get_by(YMP.HostInformation, host: host) do
      nil ->
        url = "http://#{host}/.well-known/ymp"
        struct = %YMP.HostInformation{}
        with {:ok, response} <- YMP.HTTP.get(url),
             {:ok, body} <- Poison.decode(response.body),
             %{"ymp-version" => version,
               "connection-protocols" => connection_protocols,
               "service-protocols" => service_protocols} <- body,
             params <- %{
               host: host,
               ymp_version: version,
               connection_protocols: connection_protocols,
               service_protocols: service_protocols},
             changeset <- YMP.HostInformation.changeset(struct, params),
             true <- changeset.valid?,
             {:ok, host_information} <- DB.Repo.insert(changeset) do
          {:ok, host_information}
        else
          _ ->
            :error
        end
      host_information -> {:ok, host_information}
    end
  end
end
