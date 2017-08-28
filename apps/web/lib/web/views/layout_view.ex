defmodule Web.LayoutView do
  use Web, :view

  def render_user(user) do
    {:ok, user} = Yayaka.YayakaUserCache.get_or_fetch(user)
    "#{user.name} @ #{user.host}"
  end
end
