ExUnit.start()
Application.ensure_all_started(:db)
Ecto.Adapters.SQL.Sandbox.mode(DB.Repo, :manual)
YMP.TestMessageHandler.start_link()
YMP.TestConnection.start_link()
