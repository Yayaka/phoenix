defmodule YMP.HostInformationProviderTest do
  use DB.DataCase

  setup do
    bypass = Bypass.open
    {:ok, bypass: bypass}
  end

  test "get_host_information from DB", %{bypass: bypass} do
    params = %{
      host: "localhost:#{bypass.port}",
      ymp_version: "0.1.0",
      connection_protocols: [
        %{name: "https-token",
          version: "0.1.0",
          parameters: %{
            "request-path" => "/request",
            "grant-path" => "/grant",
            "packet-path" => "/packet"
          }
        }
      ]
    }
    changeset = YMP.HostInformation.changeset(%YMP.HostInformation{}, params)
    DB.Repo.insert(changeset)
    {:ok, host_information} = YMP.HostInformationProvider.request(params.host)
    assert host_information.host == params.host
    assert host_information.ymp_version == "0.1.0"
    assert length(host_information.connection_protocols) == 1
    assert length(host_information.service_protocols) == 0
  end

  test "get_host_information from HTTP", %{bypass: bypass} do
    Bypass.expect_once bypass, "GET", "/.well-known/ymp", fn conn ->
      information = %{
        "ymp-version" => "0.1.0",
        "connection-protocols" => [
          %{name: "https-token",
            version: "0.1.0",
            parameters: %{
              "request-path" => "/request",
              "grant-path" => "/grant",
              "packet-path" => "/packet"
            }
          }
        ],
        "service-protocols" => []
      }
      body = Poison.encode!(information)
      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(200, body)
    end
    host = "localhost:#{bypass.port}"
    {:ok, host_information} = YMP.HostInformationProvider.request(host)
    # Cached to DB
    {:ok, ^host_information} = YMP.HostInformationProvider.request(host)
    assert host_information.host == host
    assert host_information.ymp_version == "0.1.0"
    assert length(host_information.connection_protocols) == 1
    assert length(host_information.service_protocols) == 0
  end
end
