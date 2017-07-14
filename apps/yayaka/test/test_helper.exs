ExUnit.start()
Application.ensure_all_started(:db)
Ecto.Adapters.SQL.Sandbox.mode(DB.Repo, :manual)
