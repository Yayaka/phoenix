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

    get "/.well-known/amorphos", PageController, :host_information

    get "/", PageController, :index
    resources "/users", UserController, only: [:new, :create]

    get "/login", PageController, :login
    post "/login", SessionController, :create
    get "/logout", SessionController, :delete
    get "/switch-user", SessionController, :switch

    get "/timeline", EventController, :timeline

    scope "/yayaka" do
      get "/", YayakaUserController, :index
      get "/user-attributes", YayakaUserController, :user_attributes
      post "/create-user", YayakaUserController, :create_user
      post "/check-user-name-availability", YayakaUserController, :check_user_name_availability
      post "/update-user-name", YayakaUserController, :update_user_name
      post "/update-user-attributes", YayakaUserController, :update_user_attributes
      post "/fetch-user", YayakaUserController, :fetch_user
      post "/fetch-user-by-name", YayakaUserController, :fetch_user_by_name
      post "/get-token", YayakaUserController, :get_token
      post "/authenticate-user", YayakaUserController, :authenticate_user
      post "/authorize-service", YayakaUserController, :authorize_service
      post "/revoke-service-authorization", YayakaUserController, :revoke_service_authorization
      post "/fetch-user-relations", YayakaUserController, :fetch_user_relations
      post "/subscribe", YayakaUserController, :subscribe
      post "/unsubscribe", YayakaUserController, :unsubscribe
    end
  end

  scope "/api", Web do
    pipe_through [:api, :api_auth]

    scope "/amorphos" do
      scope "/https-token" do
        post "/request", HTTPSTokenController, :request
        post "/grant", HTTPSTokenController, :grant
        post "/packet", HTTPSTokenController, :packet
      end
    end
  end
end
