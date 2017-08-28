defmodule Amorphos.HostInformationProvider do
  def request(host) do
    case DB.Repo.get_by(Amorphos.HostInformation, host: host) do
      nil ->
        url = "http://#{host}/.well-known/amorphos"
        struct = %Amorphos.HostInformation{}
        with {:ok, response} <- Amorphos.HTTP.get(url),
             {:ok, body} <- Poison.decode(response.body),
             %{"amorphos-version" => version,
               "connection-protocols" => connection_protocols,
               "service-protocols" => service_protocols} <- body,
             params <- %{
               host: host,
               amorphos_version: version,
               connection_protocols: connection_protocols,
               service_protocols: service_protocols},
             changeset <- Amorphos.HostInformation.changeset(struct, params),
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

  def clear_old_caches(older_than) do
    import Ecto.Query
    query = from info in Amorphos.HostInformation,
      where: info.updated_at < ^older_than
    DB.Repo.delete_all(query)
  end
end
