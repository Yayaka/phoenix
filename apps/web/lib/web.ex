defmodule Web do
  @moduledoc """
  A module that keeps using definitions for controllers,
  views and so on.

  This can be used in your application as:

      use Web, :controller
      use Web, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below.
  """

  def controller do
    quote do
      use Phoenix.Controller, namespace: Web
      import Plug.Conn
      import Web.Router.Helpers
      import Web.Gettext

      def get_user(conn) do
        case Guardian.Plug.current_resource(conn) do
          nil -> nil
          user -> DB.Repo.get!(YayakaPresentation.PresentationUser, user["id"])
        end
      end

      def get_yayaka_user(conn) do
        Plug.Conn.get_session(conn, :yayaka_user)
      end

      def get_yayaka_user!(conn) do
        case Plug.Conn.get_session(conn, :yayaka_user) do
          user when not is_nil(user) -> user
        end
      end
    end
  end

  def view do
    quote do
      use Phoenix.View, root: "lib/web/templates",
                        namespace: Web

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_csrf_token: 0, get_flash: 2, view_module: 1]

      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      import Web.Router.Helpers
      import Web.ErrorHelpers
      import Web.Gettext

      def get_user(conn) do
        Guardian.Plug.current_resource(conn)
      end
    end
  end

  def router do
    quote do
      use Phoenix.Router
      import Plug.Conn
      import Phoenix.Controller
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import Web.Gettext
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
