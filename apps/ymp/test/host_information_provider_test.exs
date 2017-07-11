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

  test "clear_old_caches" do
    now = DateTime.utc_now() |> DateTime.to_unix()
    to_naive = fn unix ->
      {:ok, datetime} = DateTime.from_unix(unix)
      DateTime.to_naive(datetime)
    end
    info1 = %YMP.HostInformation{
      host: "host1",
      ymp_version: "0.1.0",
      updated_at: to_naive.(now - 2000)
    }
    info2 = %YMP.HostInformation{
      info1 | host: "host2",
      updated_at: to_naive.(now - 1000)
    }
    info3 = %YMP.HostInformation{
      info1 | host: "host3",
      updated_at: to_naive.(now)
    }
    info4 = %YMP.HostInformation{
      info1 | host: "host4",
      updated_at: to_naive.(now + 1000)
    }
    DB.Repo.insert(info1)
    DB.Repo.insert(info2)
    DB.Repo.insert(info3)
    DB.Repo.insert(info4)
    list = DB.Repo.all(YMP.HostInformation)
    assert list |> length == 4
    YMP.HostInformationProvider.clear_old_caches(to_naive.(now))
    list = DB.Repo.all(YMP.HostInformation)
    assert list |> length == 2
    assert Enum.any?(list, fn %{host: host} -> host == info3.host end)
    assert Enum.any?(list, fn %{host: host} -> host == info4.host end)
  end
end
