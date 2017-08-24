defmodule Web.Router do
  use Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Guardian.Plug.VerifySession
    plug Guardian.Plug.LoadResource
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :api_auth do
    plug Guardian.Plug.VerifyHeader, realm: "Bearer"
    plug Guardian.Plug.LoadResource
  end

  scope "/", Web do
    pipe_through :browser

    get "/", PageController, :index
    resources "/users", UserController, only: [:new, :create]

    get "/login", PageController, :login
    post "/login", SessionController, :create
    get "/logout", SessionController, :delete
  end

  scope "/api", Web do
    pipe_through [:api, :api_auth]

    scope "/ymp" do
      scope "/https-token" do
        post "/request", HTTPSTokenController, :request
        post "/grant", HTTPSTokenController, :grant
        post "/packet", HTTPSTokenController, :packet
      end
    end
  end
end
